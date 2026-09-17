# Executado pela Scheduled Task "SupE2eAutomation-AgentMaster" no fim do dia: dispara as 18:00 e
# repete a cada 20min por ate 12h (ate ~06:00), pedido do Thiago pra rodar no fim do dia ate zerar a
# fila-merge (ele faz os testes manuais/aprova no dia seguinte). A pre-checagem em PowerShell abaixo
# (Test-TrabalhoPendente) ja garante que, assim que a fila esvaziar, os disparos seguintes dessa
# janela nao chamam o Claude (so gravam "[ciclo pulado]") - nao precisa de nenhuma logica extra de
# cadencia adaptativa aqui, so o trigger diario + repeticao do Windows Task Scheduler.
# Roda um único ciclo do Agent Master em modo não interativo.

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

# --- Pausa manual por indisponibilidade de ambiente HML (2026-09-16, pedido do Thiago) ---
# Enquanto C:\Multiplica\claudeAgents\PAUSA-HML.flag existir, este processo pode rodar testes
# Cypress que logam na plataforma HML como parte da validação de merge — por isso não tenta
# nenhum ciclo enquanto o ambiente estiver fora do ar. Removido pelo Thiago (ou por mim a pedido
# dele) assim que o ambiente for restabelecido.
if (Test-Path "C:\Multiplica\claudeAgents\PAUSA-HML.flag") {
    "$(Get-Date -Format 'HH:mm:ss') | [pausado] ambiente HML indisponivel (PAUSA-HML.flag existe) - ciclo nao executado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

# Conta do Claude Code "de casa" do Agent Master (não entra no revezamento de módulos novos, mas
# participa da alternância por rate-limit abaixo, igual aos subAgents).
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

$contaDeCasa = "contaB"
$contaAlternativa = "contaA"
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

# Token do GitHub CLI (gh) para abrir/consultar PRs — lido de arquivo local (não versionado, nunca
# embutido neste script), acesso total aos repositórios, sem expiração.
$env:GH_TOKEN = (Get-Content (Join-Path $PSScriptRoot ".gh-token") -Raw).Trim()
$env:Path = "$env:Path;$env:LOCALAPPDATA\Programs\gh\bin"

# --- Garantia determinística do PR único reviewAgents -> main (movida de instrução do prompt do
# Claude pra cá em 2026-09-16, pedido do Thiago: tudo que não exige julgamento deve rodar fora do
# Claude) --- checar/criar esse PR nunca decide nada (é sempre "existe? não, cria; existe? não mexe"),
# então roda aqui, em todo ciclo, sem depender de haver algo em fila-merge/ (antes só era conferido
# quando o Claude chegava a ser chamado — agora é de graça, não tem motivo pra pular).
function Confirmar-PRUnico {
    param([string]$Base, [string]$LogPath)
    try {
        $existentesJson = gh pr list --base $Base --head reviewAgents --state open --json number 2>$null
        $existentes = if ($existentesJson) { $existentesJson | ConvertFrom-Json } else { @() }
    } catch { $existentes = @() }
    if ($existentes -and $existentes.Count -gt 0) { return }
    gh pr create --base $Base --head reviewAgents `
        --title "Integracao continua reviewAgents -> $Base" `
        --body "PR unico e continuo, criado automaticamente. Reflete cada commit novo pusheado na reviewAgents. Revisao/merge manual do Thiago quando quiser." `
        *>&1 | Add-Content -Path $LogPath -Encoding utf8
    "$(Get-Date -Format 'HH:mm:ss') | [pr-unico] nao existia PR aberto reviewAgents->$Base - criado" |
        Add-Content -Path $LogPath -Encoding utf8
}

Confirmar-PRUnico -Base "main" -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# houver algo pra processar em fila-merge/. Ver seção 3.4 do CLAUDE.md.
function Test-TrabalhoPendente {
    $pendentes = (Get-ChildItem -Path "fila-merge/pendentes" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($pendentes) { return $true }
    $legado = (Get-ChildItem -Path "fila-merge/aguardando-aprovacao" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    return $legado
}

if (-not (Test-TrabalhoPendente)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] fila-merge vazia - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o Agent Master do projeto de automação de UI. Leia AGENTE.md nesta pasta e siga suas
regras fixas à risca — em especial (fluxo mudou em 2026-09-14, pedido explícito do Thiago): você
faz merge direto com push na reviewAgents de cada tarefa aprovada nos testes, SEM PR nem
aprovação humana por tarefa. Você NUNCA mergeia/dá push direto na main. O PR unico e continuo
reviewAgents para main (unico ponto de revisao manual do Thiago) ja e garantido/criado
deterministicamente por PowerShell antes deste ciclo (funcao Confirmar-PRUnico no run-cycle.ps1)
— voce nao precisa mais checar/criar esse PR, so cuidar da fila-merge abaixo. gh CLI ja autenticado
via GH_TOKEN, disponivel se precisar dele por outro motivo. Execute agora UM unico ciclo da logica
operacional:

1. Leia ../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro.
2. Legado: se houver algo em fila-merge/aguardando-aprovacao/ (aviso de PR por tarefa do modelo
   antigo, ex. PR numero 9 da branch feature/mop-monitor-diario-analisar-operacao), para cada um
   rode gh pr view passando a branch do aviso e pedindo os campos state, mergedAt e url em json.
   - MERGED: git pull origin reviewAgents em repo/; atualize repo/.env se a branch trouxe
     variável nova (compare .env.example antes/depois, busque valor em
     ../subagents/<modulo>/docs/documentacao.md ou na tarefa concluída — nunca invente); depois
     sincronize C:\multiplica\cypress-e2e de volta para reviewAgents (git pull, npm ci se
     necessário, copiar repo/.env por cima do .env de lá). Mova o aviso para
     fila-merge/concluidos/ e registre em docs/documentacao.md.
   - CLOSED sem merge: registre dúvida em duvidas.md perguntando o motivo/próximos passos, sem
     mexer no aviso.
   - OPEN: não faça nada com esse aviso agora — nenhum aviso novo deve passar por essa pasta daqui
     pra frente.
3. Para cada aviso em fila-merge/pendentes/ (fluxo normal, novo): no repo/, busque a branch e faça
   um merge de teste LOCAL contra reviewAgents para achar conflito; se houver, resolva com a skill
   /resolve-conflicts e comite a resolução na própria branch da feature antes de mesclar de
   verdade. Atualize repo/.env se necessário (mesma lógica de sempre, nunca invente/deixe em
   branco). Rode os testes relevantes (npm test) contra a branch mesclada preventivamente. Se
   passar: finalize o merge de verdade e de push direto na reviewAgents (sem PR, sem esperar
   aprovacao), mova o aviso de fila-merge/pendentes/ direto para fila-merge/concluidos/ (nunca
   passa por aguardando-aprovacao/ nesse fluxo). Se falhar/não resolver conflito: trate como
   dúvida bloqueante, desfaça o merge local (não deixe a reviewAgents local suja), deixe o aviso
   em fila-merge/pendentes/.
4. Depois de processar os avisos, sincronize C:\multiplica\cypress-e2e sempre para a reviewAgents
   (não há mais branch de PR-por-tarefa pra testar antes de aprovar), rode npm ci se necessário.
   Em qualquer caso, copie repo/.env por cima do .env dessa pasta. Copie também
   repo/cypress/videos/*.mp4 (se existirem, dos testes que voce rodou neste ciclo) para
   cypress/videos/ dentro dessa pasta — o video da execucao tem que terminar no repositorio do
   Thiago, nao so ficar preso no seu clone (repo/). Nunca exponha conteúdo de .env/token em
   docs/documentacao.md, duvidas.md ou no log de saída — só confirme que foi sincronizado. Se o
   pull/checkout falhar (working tree suja, divergência), não force nada: registre em duvidas.md.
5. Registre em docs/documentacao.md tudo que foi feito (merges feitos direto na reviewAgents,
   conflitos resolvidos, variáveis de .env novas só o nome, e estado da sincronização da pasta de
   teste manual). Se o aprendizado valer para qualquer módulo, registre também em
   ../docs/conhecimento-geral.md (releia antes de escrever).
6. Nunca responda sua própria dúvida.
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
Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt") -PermitirCommitEPush -MensagemCommit "Agent Master E2e: sincroniza estado do ciclo (auto, $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
