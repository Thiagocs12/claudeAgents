# Executado pela Scheduled Task "SupTestesFrontEnd-SubAgent-mop" a cada 5 minutos.
# Roda um único ciclo do subAgent do módulo "mop" (Sup TestesFrontEnd) em modo não interativo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# Conta do Claude Code dedicada a este subAgent (1º módulo criado neste Supervisor -> contaA).
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaA"

# Rede de segurança determinística (não depende do LLM se comportar): mata qualquer processo
# Cypress/node remanescente desta pasta, órfão de um ciclo anterior que tenha travado/backgrounded
# um "npx cypress run" e encerrado sem limpar (já aconteceu em 2026-09-15 — ver
# docs/documentacao.md e CONHECIMENTO-SUPERVISORES.md). Roda no início (limpa lixo de um ciclo
# anterior antes de decidir se há trabalho a fazer) e no fim (garante que este ciclo não deixa
# nada pra trás), independente do que o `claude -p` tenha feito.
function Get-ArvoreDeProcessos {
    param([int[]]$RaizIds, $TodosProcessos)
    $resultado = New-Object System.Collections.Generic.HashSet[int]
    $fila = New-Object System.Collections.Generic.Queue[int]
    foreach ($id in $RaizIds) { $fila.Enqueue($id) }
    while ($fila.Count -gt 0) {
        $atual = $fila.Dequeue()
        if ($resultado.Add($atual)) {
            foreach ($filho in ($TodosProcessos | Where-Object { $_.ParentProcessId -eq $atual })) {
                $fila.Enqueue($filho.ProcessId)
            }
        }
    }
    return $resultado
}

function Stop-ProcessosCypressOrfaos {
    param([string]$Pasta, [string]$LogPath)
    try {
        $todos = Get-CimInstance Win32_Process -ErrorAction Stop
    } catch { return }
    $pastaEscapada = [regex]::Escape($Pasta)
    $raizes = $todos | Where-Object {
        $_.CommandLine -and $_.CommandLine -match $pastaEscapada -and $_.CommandLine -match "cypress"
    }
    if (-not $raizes) { return }
    $arvore = Get-ArvoreDeProcessos -RaizIds ($raizes | Select-Object -ExpandProperty ProcessId) -TodosProcessos $todos
    foreach ($procId in $arvore) {
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            try {
                Stop-Process -Id $procId -Force -ErrorAction Stop
                $ts = Get-Date -Format "HH:mm:ss"
                "$ts | [limpeza] processo remanescente encerrado: PID=$procId $($proc.ProcessName)" |
                    Add-Content -Path $LogPath -Encoding utf8
            } catch {}
        }
    }
}

Stop-ProcessosCypressOrfaos -Pasta $PSScriptRoot -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Checagem determinística (sem custo de chamada ao Claude) — mesmo padrão dos outros Supervisores.
function Test-DuvidaRespondida {
    param([string]$DuvidasPath, [string]$Id)
    if (-not (Test-Path $DuvidasPath)) { return $false }
    $conteudo = Get-Content $DuvidasPath -Raw -ErrorAction SilentlyContinue
    if (-not $conteudo) { return $false }
    foreach ($bloco in [regex]::Split($conteudo, '(?m)^##\s+')) {
        if ($bloco -match "^$([regex]::Escape($Id))\s*(\r?\n|$)") {
            return [bool]($bloco -match '(?m)^Status:\s*respondida\s*$')
        }
    }
    return $false
}

function Test-TrabalhoPendente {
    $temPendente = (Get-ChildItem -Path "tarefas/pendentes" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($temPendente) { return $true }

    $temExecutando = (Get-ChildItem -Path "tarefas/executando" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($temExecutando) { return $true }

    $aguardando = Get-ChildItem -Path "tarefas/aguardando-resposta" -File -ErrorAction SilentlyContinue
    foreach ($arquivo in $aguardando) {
        $id = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
        if (Test-DuvidaRespondida -DuvidasPath "duvidas.md" -Id $id) { return $true }
    }
    return $false
}

if (-not (Test-TrabalhoPendente)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] sem tarefa pendente/retomavel/respondida - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o SubAgent do módulo "mop" (Sup TestesFrontEnd — QA exploratório, não automação
persistente). Leia AGENTE.md nesta pasta e siga suas regras fixas à risca. Execute agora UM único
ciclo da lógica operacional:

1. Em tarefas/aguardando-resposta/: para cada tarefa cuja dúvida correspondente em duvidas.md já
   esteja "Status: respondida", mova o arquivo de volta para tarefas/pendentes/.
2. Se tarefas/executando/ já tiver uma tarefa, RETOME-A: leia a seção "## Execução" já escrita
   nela para saber onde parou (não recomece do zero, não descarte o que já foi descoberto). Se não
   houver nenhuma seção "## Execução" ainda, trate como se estivesse começando agora.
3. Se tarefas/executando/ estiver vazia e houver algo em tarefas/pendentes/, mova a mais antiga
   (pelo timestamp no nome do arquivo) para tarefas/executando/ e prossiga.
4. Se não houver nada a fazer nos passos 1-3, encerre o ciclo agora.
5. Leia ../../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro (inclui o ponteiro pro conhecimento já mapeado pelo SupE2eAutomation — leia aquele
   arquivo também antes de explorar do zero).
6. Tente cumprir o objetivo da tarefa via Cypress (npx cypress run), incrementalmente: escreva um
   passo, rode, observe o resultado, decida o próximo passo. Narre CADA tentativa relevante na
   seção "## Execução" do arquivo da tarefa, no formato "Tentei <ação> → <o que aconteceu>", à
   medida que for acontecendo (não só no final). Nunca inicie processo em segundo plano e encerre
   o ciclo esperando ele terminar — rode tudo de forma síncrona dentro do ciclo. Se o ciclo for
   esgotar antes de terminar, garanta que a seção "## Execução" está atualizada com o que já foi
   descoberto/tentado, para o próximo ciclo continuar de onde parou.
7. Ao concluir (objetivo cumprido, cumprido parcialmente, ou travado por um problema real da
   aplicação — isso é RESULTADO, não dúvida): grave vídeo Cypress (cypress/videos/) e copie o
   .mp4 gerado para ../videos/<id-da-tarefa>.mp4; acrescente a seção "## Resultado" (veredito,
   caminho do vídeo, resumo dos achados); atualize docs/documentacao.md com qualquer
   seletor/fluxo novo mapeado (e ../../docs/conhecimento-geral.md se valer pra outro módulo,
   releia antes de escrever); mova o arquivo de tarefas/executando/ para
   tarefas/aguardando-aprovacao/ — NUNCA para tarefas/concluidas/, e NUNCA gere hand-off nenhum
   pro SupE2eAutomation você mesmo (isso só acontece depois de aprovação do Thiago, feito pelo
   Supervisor).
8. Se travar numa dúvida bloqueante de verdade (precisa de decisão/informação do Thiago pra
   continuar — não confundir com "encontrei um bug/erro real", que é resultado, passo 7): registre
   em duvidas.md no formato padrão, mova a tarefa de tarefas/executando/ para
   tarefas/aguardando-resposta/, e encerre o ciclo sem terminar a tarefa. Nunca responda sua
   própria dúvida.

Nunca trabalhe em mais de uma tarefa ativa por vez. Nunca exponha credencial/senha em
docs/documentacao.md, duvidas.md, log, ou no relatório.
'@

$prompt | claude -p --permission-mode bypassPermissions --output-format stream-json --verbose 2>&1 |
    ForEach-Object {
        $linha = $_.ToString()
        $ts = Get-Date -Format "HH:mm:ss"
        $texto = $null
        try {
            $evt = $linha | ConvertFrom-Json -ErrorAction Stop
            switch ($evt.type) {
                "system" { $texto = "[sessao] modelo=$($evt.model) cwd=$($evt.cwd)" }
                "assistant" {
                    foreach ($bloco in $evt.message.content) {
                        if ($bloco.type -eq "text" -and $bloco.text) {
                            $texto = "[fala] $($bloco.text)"
                        } elseif ($bloco.type -eq "tool_use") {
                            $args = ($bloco.input | ConvertTo-Json -Compress -Depth 4)
                            if ($args.Length -gt 300) { $args = $args.Substring(0, 300) + "..." }
                            $texto = "[tool] $($bloco.name) $args"
                        }
                    }
                }
                "user" {
                    foreach ($bloco in $evt.message.content) {
                        if ($bloco.type -eq "tool_result") {
                            $conteudo = if ($bloco.content -is [array]) {
                                ($bloco.content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text
                            } else { $bloco.content }
                            if ($conteudo) {
                                if ($conteudo.Length -gt 300) { $conteudo = $conteudo.Substring(0, 300) + "..." }
                                $texto = "[resultado] $conteudo"
                            }
                        }
                    }
                }
                "result" { $texto = "[ciclo encerrado] $($evt.subtype) duracao=$($evt.duration_ms)ms custo=`$$($evt.total_cost_usd)" }
            }
        } catch {}
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }

# Segunda passada da rede de segurança: garante que este ciclo não deixa nenhum processo
# Cypress/node vivo pra trás, mesmo que o `claude -p` acima tenha tentado rodar algo em
# background e encerrado sem esperar.
Stop-ProcessosCypressOrfaos -Pasta $PSScriptRoot -LogPath (Join-Path $PSScriptRoot "run-log.txt")
