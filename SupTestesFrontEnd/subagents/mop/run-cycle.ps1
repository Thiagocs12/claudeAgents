# Executado pela Scheduled Task "SupTestesFrontEnd-SubAgent-mop" a cada 5 minutos.
# Roda um único ciclo do subAgent do módulo "mop" (Sup TestesFrontEnd) em modo não interativo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# --- Sincronização automática do repo raiz (claudeAgents) ---
# O .git deste repo (raiz C:\Multiplica\claudeAgents) é compartilhado por todos os
# Supervisores/agentes/Status Watchers rodando nesta máquina (mesmo working tree, mesmo remoto
# Thiagocs12/claudeAgents) — ver CONHECIMENTO-SUPERVISORES.md, seção "git add/git commit no repo
# raiz". Serializado via Mutex nomeado global pra nunca mexer no índice/HEAD ao mesmo tempo que
# outro processo concorrente (resolve a race condition documentada lá). Usa fetch+merge (nunca
# rebase) e aborta e loga se houver conflito, em vez de deixar o repo compartilhado preso num
# estado de merge pela metade — mais seguro num script não supervisionado que todo mundo
# compartilha. Chamado sem -PermitirCommitEPush logo após o Set-Location (pull no início, pra não
# trabalhar sobre estado desatualizado), e com -PermitirCommitEPush no fim do ciclo (publica no
# remoto toda documentação de conhecimento/tarefas escrita/movida durante o ciclo).
function Sync-RepoRaizClaudeAgents {
    param(
        [string]$LogPath,
        [switch]$PermitirCommitEPush,
        [string]$MensagemCommit
    )
    $mutex = New-Object System.Threading.Mutex($false, "Global\ClaudeAgentsGitSync")
    try {
        $mutex.WaitOne(120000) | Out-Null
        Push-Location "C:\Multiplica\claudeAgents"
        try {
            git fetch origin main *>&1 | Add-Content -Path $LogPath -Encoding utf8
            $atras = git rev-list HEAD..origin/main --count 2>$null
            if ($atras -and [int]$atras -gt 0) {
                git merge --no-edit origin/main *>&1 | Add-Content -Path $LogPath -Encoding utf8
                if ($LASTEXITCODE -ne 0) {
                    "$(Get-Date -Format 'HH:mm:ss') | [git-sync] merge com origin/main falhou (possivel conflito) - abortando merge, sem mexer mais no repo raiz neste ciclo" |
                        Add-Content -Path $LogPath -Encoding utf8
                    git merge --abort *>&1 | Out-Null
                    return
                }
            }
            if ($PermitirCommitEPush) {
                git add -A
                $temStaged = -not [string]::IsNullOrWhiteSpace((git diff --cached --name-only))
                if ($temStaged) {
                    git commit -m $MensagemCommit *>&1 | Add-Content -Path $LogPath -Encoding utf8
                    git push origin main *>&1 | Add-Content -Path $LogPath -Encoding utf8
                }
            }
        } finally {
            Pop-Location
        }
    } finally {
        $mutex.ReleaseMutex()
    }
}

Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Conta do Claude Code dedicada a este subAgent (1º módulo criado neste Supervisor -> contaA
# "de casa").
#
# --- Alternância de conta por rate-limit (pedido do Thiago, 2026-09-15; estendida aos 3
# Supervisores em 2026-09-16) ---
# Cada conta grava sua última utilização conhecida (janela five_hour) em
# %USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json a cada ciclo que a usa, de
# qualquer agente/Supervisor (pool compartilhado contaA/contaB). Antes de começar, se a conta "de
# casa" deste agente estiver >=99% nessa janela (e o reset ainda não passou), tenta a conta
# alternativa. Não persiste a troca: no próximo ciclo, tenta a conta de casa de novo primeiro. Ver
# CONHECIMENTO-SUPERVISORES.md.
function Get-UtilizacaoConta {
    param([string]$Conta)
    $caminho = "$env:USERPROFILE\.claude-accounts\$Conta\ultima-utilizacao.json"
    if (-not (Test-Path $caminho)) { return $null }
    try {
        $dado = Get-Content $caminho -Raw | ConvertFrom-Json
        if ($dado.resetsAt -and ([DateTimeOffset]::FromUnixTimeSeconds($dado.resetsAt).UtcDateTime -lt (Get-Date).ToUniversalTime())) {
            return $null
        }
        return [double]$dado.five_hour_utilization
    } catch { return $null }
}

function Set-UtilizacaoConta {
    param([string]$Conta, [double]$Utilizacao, [long]$ResetsAt)
    $pasta = "$env:USERPROFILE\.claude-accounts\$Conta"
    if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Force -Path $pasta | Out-Null }
    @{ five_hour_utilization = $Utilizacao; resetsAt = $ResetsAt; atualizado_em = (Get-Date).ToUniversalTime().ToString("o") } |
        ConvertTo-Json | Set-Content -Path "$pasta\ultima-utilizacao.json" -Encoding utf8
}

$contaDeCasa = "contaA"
$contaAlternativa = "contaB"
$contaEfetiva = $contaDeCasa
$utilDeCasa = Get-UtilizacaoConta -Conta $contaDeCasa
if ($null -ne $utilDeCasa -and $utilDeCasa -ge 0.99) {
    $utilAlternativa = Get-UtilizacaoConta -Conta $contaAlternativa
    if ($null -eq $utilAlternativa -or $utilAlternativa -lt 0.99) {
        $contaEfetiva = $contaAlternativa
        "$(Get-Date -Format 'HH:mm:ss') | [alternancia] $contaDeCasa em $([math]::Round($utilDeCasa*100,1))% (five_hour) - usando $contaAlternativa neste ciclo" |
            Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    } else {
        "$(Get-Date -Format 'HH:mm:ss') | [alternancia] $contaDeCasa e $contaAlternativa ambas >=99% (five_hour) - seguindo com $contaDeCasa mesmo assim" |
            Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }
}
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\$contaEfetiva"

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
    # Sincronização determinística da fila de tarefas (movida de instrução do prompt do Claude pra
    # cá em 2026-09-16, pedido do Thiago: tudo que não exige julgamento deve rodar fora do Claude,
    # pra não gastar tokens/turnos em operação mecânica). Nenhuma das duas ações abaixo decide nada
    # — é só regex em duvidas.md e ordenação por timestamp no nome do arquivo.
    $aguardando = Get-ChildItem -Path "tarefas/aguardando-resposta" -File -ErrorAction SilentlyContinue
    foreach ($arquivo in $aguardando) {
        $id = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
        if (Test-DuvidaRespondida -DuvidasPath "duvidas.md" -Id $id) {
            Move-Item -Path $arquivo.FullName -Destination "tarefas/pendentes/$($arquivo.Name)" -Force
            "$(Get-Date -Format 'HH:mm:ss') | [fila] $($arquivo.Name): duvida respondida, movido aguardando-resposta -> pendentes" |
                Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
        }
    }

    $temExecutando = (Get-ChildItem -Path "tarefas/executando" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if (-not $temExecutando) {
        $maisAntiga = Get-ChildItem -Path "tarefas/pendentes" -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
        if ($maisAntiga) {
            Move-Item -Path $maisAntiga.FullName -Destination "tarefas/executando/$($maisAntiga.Name)" -Force
            "$(Get-Date -Format 'HH:mm:ss') | [fila] $($maisAntiga.Name): movido pendentes -> executando" |
                Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
        }
    }

    return (Get-ChildItem -Path "tarefas/executando" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
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

1. A fila de tarefas já foi sincronizada deterministicamente antes deste ciclo (dúvida respondida
   já volta pra tarefas/pendentes/ sozinha, e a tarefa mais antiga já foi movida pra
   tarefas/executando/ se estava vazia) — há exatamente uma tarefa em tarefas/executando/ agora.
   RETOME-A: leia a seção "## Execução" já escrita nela para saber onde parou (não recomece do
   zero, não descarte o que já foi descoberto). Se não houver nenhuma seção "## Execução" ainda,
   trate como se estivesse começando agora.
2. Leia ../../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro (inclui o ponteiro pro conhecimento já mapeado pelo SupE2eAutomation — leia aquele
   arquivo também antes de explorar do zero).
3. Tente cumprir o objetivo da tarefa via Cypress (npx cypress run), incrementalmente: escreva um
   passo, rode, observe o resultado, decida o próximo passo. Narre CADA tentativa relevante na
   seção "## Execução" do arquivo da tarefa, no formato "Tentei <ação> → <o que aconteceu>", à
   medida que for acontecendo (não só no final). Nunca inicie processo em segundo plano e encerre
   o ciclo esperando ele terminar — rode tudo de forma síncrona dentro do ciclo. Se o ciclo for
   esgotar antes de terminar, garanta que a seção "## Execução" está atualizada com o que já foi
   descoberto/tentado, para o próximo ciclo continuar de onde parou.
4. Ao concluir (objetivo cumprido, cumprido parcialmente, ou travado por um problema real da
   aplicação — isso é RESULTADO, não dúvida): grave vídeo Cypress (cypress/videos/) e copie o
   .mp4 gerado para ../videos/<id-da-tarefa>.mp4; acrescente a seção "## Resultado" (veredito,
   caminho do vídeo, resumo dos achados); atualize docs/documentacao.md com qualquer
   seletor/fluxo novo mapeado (e ../../docs/conhecimento-geral.md se valer pra outro módulo,
   releia antes de escrever); mova o arquivo de tarefas/executando/ para
   tarefas/aguardando-aprovacao/ — NUNCA para tarefas/concluidas/, e NUNCA gere hand-off nenhum
   pro SupE2eAutomation você mesmo (isso só acontece depois de aprovação do Thiago, feito pelo
   Supervisor).
5. Se travar numa dúvida bloqueante de verdade (precisa de decisão/informação do Thiago pra
   continuar — não confundir com "encontrei um bug/erro real", que é resultado, passo 4): registre
   em duvidas.md no formato padrão, mova a tarefa de tarefas/executando/ para
   tarefas/aguardando-resposta/, e encerre o ciclo sem terminar a tarefa. Nunca responda sua
   própria dúvida.

Nunca trabalhe em mais de uma tarefa ativa por vez. Nunca exponha credencial/senha em
docs/documentacao.md, duvidas.md, log, ou no relatório.
'@

$script:ultimoRateLimit = $null

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
                "rate_limit_event" {
                    $fh = $evt.rate_limit_info.unifiedWindows.five_hour
                    if ($fh) {
                        $script:ultimoRateLimit = @{ utilization = $fh.utilization; resetsAt = $fh.resetsAt }
                        $texto = "[rate-limit] conta=$contaEfetiva five_hour=$([math]::Round($fh.utilization*100,1))%"
                    }
                }
            }
        } catch {}
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }

if ($script:ultimoRateLimit) {
    Set-UtilizacaoConta -Conta $contaEfetiva -Utilizacao $script:ultimoRateLimit.utilization -ResetsAt $script:ultimoRateLimit.resetsAt
}

# Segunda passada da rede de segurança: garante que este ciclo não deixa nenhum processo
# Cypress/node vivo pra trás, mesmo que o `claude -p` acima tenha tentado rodar algo em
# background e encerrado sem esperar.
Stop-ProcessosCypressOrfaos -Pasta $PSScriptRoot -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Publica no remoto tudo que este ciclo escreveu/moveu no repo raiz (docs, duvidas, tarefas) — ver
# função Sync-RepoRaizClaudeAgents definida no início deste script.
Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt") -PermitirCommitEPush -MensagemCommit "mop (TestesFrontEnd): sincroniza estado do ciclo (auto, $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
