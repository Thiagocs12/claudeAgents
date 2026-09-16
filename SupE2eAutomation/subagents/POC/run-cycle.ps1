# Executado pela Scheduled Task "SupE2eAutomation-SubAgent-POC" a cada 5 minutos.
# Roda um único ciclo do subAgent do módulo "POC" em modo não interativo.

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

# Conta do Claude Code dedicada a este subAgent (3º módulo criado -> volta pra contaA "de casa").
#
# --- Alternância de conta por rate-limit (pedido do Thiago, 2026-09-15) ---
# Cada conta grava sua última utilização conhecida (janela five_hour) em
# %USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json a cada ciclo que a usa, de
# qualquer agente/Supervisor (pool compartilhado contaA/contaB). Antes de começar, se a conta "de
# casa" deste agente estiver >=99% nessa janela (e o reset ainda não passou), tenta a conta
# alternativa. Não persiste a troca: no próximo ciclo, tenta a conta de casa de novo primeiro. Ver
# docs/conhecimento-geral.md / CONHECIMENTO-SUPERVISORES.md.
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

# Checagem determinística (sem custo de chamada ao Claude) do que a Scheduled Task faria via LLM
# nos passos 1-4 da seção 3.2 do CLAUDE.md: só vale a pena chamar `claude -p` se houver algo
# pendente, retomável, ou uma dúvida já respondida esperando voltar pra fila. Ver seção 3.4 do
# CLAUDE.md ("Pré-checagem em PowerShell antes de chamar claude -p").
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
Você é o SubAgent do módulo "POC" (automação de UI). Leia AGENTE.md nesta pasta e siga suas
regras fixas à risca — em especial a abordagem deliberadamente incremental (uma etapa curta por
tarefa, nunca antecipar etapas futuras do fluxo). Execute agora UM único ciclo da lógica
operacional:

1. A fila de tarefas já foi sincronizada deterministicamente antes deste ciclo (dúvida respondida
   já volta pra tarefas/pendentes/ sozinha, e a tarefa mais antiga já foi movida pra
   tarefas/executando/ se estava vazia) — há exatamente uma tarefa em tarefas/executando/ agora.
   RETOME-A (um ciclo anterior pode ter esgotado antes de terminar): procure em repo/ uma branch já
   criada para essa tarefa (nome derivado do id/slug); se existir, dê checkout nela e continue a
   implementação de onde parou (não recomece do zero, não descarte trabalho já feito/descoberto);
   se não houver nenhuma branch/progresso, trate como se estivesse começando agora.
2. Leia ../../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro.
3. No repositório em repo/: se está começando a tarefa agora, dê pull na branch reviewAgents e crie
   uma branch nova para ela; se está retomando (passo 1), não refaça pull/checkout, continue na
   branch existente. Implemente EXATAMENTE o que a tarefa pede (nada além disso — não antecipe
   etapas futuras do fluxo Prospect → esteira → pleito ainda não refinadas), conforme a regra 2 do
   AGENTE.md (ler e seguir o padrão do README.md do repo, atualizando-o se necessário). Reaproveite
   a fundação de login já implementada (cy.loginComoPerfil) — não reimplemente login. Reaproveite
   também os aprendizados de navegação até o dashboard Comercial já documentados pelo módulo mop
   (../mop/docs/documentacao.md) em vez de redescobrir do zero. Se o ciclo for esgotar antes de
   terminar, faça commit do progresso parcial na branch (mesmo incompleto, mesmo que seja só
   anotações do que já foi descoberto sobre a tela) — não deixe só em arquivos não commitados.
4. Rode um autoteste sobre sua própria implementação antes de considerar concluído. Confirme que o
   vídeo da execução foi gerado normalmente (cypress/videos/), já que o Thiago quer acompanhar cada
   etapa por vídeo.
5. Se concluir com sucesso: siga a regra 7 do AGENTE.md (commit + push da branch, aviso em
   ../../agent-master/fila-merge/pendentes/ com a branch e o id da tarefa — o Agent Master faz
   merge direto na reviewAgents, sem PR por tarefa — atualize docs/documentacao.md e, se o
   aprendizado valer para qualquer módulo, também ../../docs/conhecimento-geral.md, mova o arquivo
   de tarefas/executando/ para tarefas/concluidas/).
6. Se travar numa dúvida bloqueante: siga a regra 8 do AGENTE.md (registre em duvidas.md no
   formato padrão, mova o arquivo de tarefas/executando/ para tarefas/aguardando-resposta/, e
   encerre o ciclo sem terminar a tarefa). Nunca responda sua própria dúvida.

Nunca trabalhe em mais de uma tarefa ativa por vez.
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

# Publica no remoto tudo que este ciclo escreveu/moveu no repo raiz (docs, duvidas, tarefas) — ver
# função Sync-RepoRaizClaudeAgents definida no início deste script.
Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt") -PermitirCommitEPush -MensagemCommit "POC: sincroniza estado do ciclo (auto, $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
