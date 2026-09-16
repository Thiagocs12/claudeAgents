# Executado pela Scheduled Task "SupTestesFrontEnd-StatusWatcher" a cada 15 minutos.
# Não implementa nada, não testa nada, e não mexe em nenhuma pasta de módulo — só lê o estado de
# todos os subAgents do Supervisor SupTestesFrontEnd e avisa o Thiago (pop-up local) quando aparece
# algo novo que precisa da atenção dele. Sem Agent Master neste Supervisor, então não há
# fila-merge/PR a checar — só duvidas.md e tarefas/aguardando-aprovacao/ de cada módulo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# --- Sincronização automática do repo raiz (claudeAgents) — só pull, nunca commit/push aqui ---
# O .git deste repo (raiz C:\Multiplica\claudeAgents) é compartilhado por todos os
# Supervisores/agentes/Status Watchers rodando nesta máquina (mesmo working tree, mesmo remoto
# Thiagocs12/claudeAgents) — ver CONHECIMENTO-SUPERVISORES.md, seção "git add/git commit no repo
# raiz". Serializado via Mutex nomeado global pra nunca mexer no índice/HEAD ao mesmo tempo que
# outro processo concorrente (resolve a race condition documentada lá). Usa fetch+merge (nunca
# rebase) e aborta e loga se houver conflito, em vez de deixar o repo compartilhado preso num
# estado de merge pela metade. Este Status Watcher só chama sem -PermitirCommitEPush — é somente
# leitura, nunca commita nem dá push (regra fixa do módulo).
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

# Conta do Claude Code "de casa" do Status Watcher (participa da alternância por rate-limit
# abaixo).
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

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# existir ALGO potencialmente notificável agora (dúvida pendente em qualquer módulo, ou tarefa em
# aguardando-aprovacao/). Ver seção "Pré-checagem em PowerShell antes de chamar claude -p" do
# CONHECIMENTO-SUPERVISORES.md.
function Test-AlgoNotificavel {
    $modulos = Get-ChildItem -Path "../subagents" -Directory -ErrorAction SilentlyContinue
    foreach ($modulo in $modulos) {
        $duvidasPath = Join-Path $modulo.FullName "duvidas.md"
        if (Test-Path $duvidasPath) {
            $conteudo = Get-Content $duvidasPath -Raw -ErrorAction SilentlyContinue
            if ($conteudo -match '(?m)^Status:\s*pendente\s*$') { return $true }
        }

        $aguardandoAprovacao = Join-Path $modulo.FullName "tarefas/aguardando-aprovacao"
        if (Test-Path $aguardandoAprovacao) {
            $temArquivo = (Get-ChildItem -Path $aguardandoAprovacao -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
            if ($temArquivo) { return $true }
        }
    }
    return $false
}

if (-not (Test-AlgoNotificavel)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] nada pendente em nenhum modulo - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o "Status Watcher" do Supervisor "Sup TestesFrontEnd" (SupTestesFrontEnd). Você NUNCA
testa nada, nunca mexe em nenhuma pasta de módulo, nunca responde dúvida, e nunca decide
aprovação — sua única função é checar o estado de todos os subAgents deste Supervisor e avisar o
Thiago via notificação quando surgir algo novo que precisa da atenção dele.

Rode agora um único ciclo:

1. Descubra os módulos existentes listando as subpastas de `../subagents/` (cada uma é um módulo).

2. Para cada módulo, colete:
   - Quantidade de arquivos em `tarefas/pendentes/`, `tarefas/executando/`, `tarefas/aguardando-resposta/`.
   - Arquivos em `tarefas/aguardando-aprovacao/` (cada um = relatório + vídeo prontos, esperando o
     Thiago decidir aprovar ou reprovar).
   - Todas as entradas de `duvidas.md` com `Status: pendente` (guarde o id da tarefa + um resumo
     curto da pergunta).

3. Monte um "estado atual" com essas informações (uma lista de itens que precisam de atenção do
   Thiago: cada dúvida pendente = um item; cada tarefa em aguardando-aprovacao = um item).

4. Leia `estado-anterior.json` nesta pasta (`status-watcher/`), se existir. Ele guarda a lista de
   itens já vistos em ciclos anteriores, cada um com `id`, `tipo` (duvida ou aprovacao) e
   `primeira_vez_visto` (timestamp ISO).

5. Compare o estado atual com o anterior:
   - Item novo (não existia no estado anterior) → marque para notificar agora, com
     `primeira_vez_visto` = agora.
   - Item que já existia → mantenha o `primeira_vez_visto` original; marque para notificar de novo
     SOMENTE se já se passaram mais de 2 horas desde a ÚLTIMA notificação enviada sobre ele (guarde
     também `ultima_notificacao` no JSON).
   - Item que sumiu (dúvida foi respondida, tarefa saiu de aguardando-aprovacao) → remova do
     estado, não precisa notificar sumiço.

6. Se houver 1+ itens para notificar: tente enviar UMA notificação via PushNotification mesmo
   assim (pode voltar "not sent" por sessão interativa ativa — tudo bem, tente igual). Além disso
   — e isso é o que realmente garante que o Thiago vai ver — TERMINE sua resposta final deste
   ciclo com uma linha EXATA, sozinha, no formato `NOTIFICAR: <resumo>` (menos de 200 caracteres,
   resumindo todos os itens em uma linha só, ex.: `NOTIFICAR: SupTestesFrontEnd: teste do módulo
   mop pronto pra revisão (vídeo + relatório)`). Essa linha aciona um pop-up local na tela do
   Thiago — não é uma ferramenta sua, é o script `run-cycle.ps1` que procura por essa linha no seu
   texto final e abre o pop-up sozinho. Se for só 1 item, pode ser mais específico. NUNCA inclua a
   linha `NOTIFICAR:` (nem tente PushNotification) se não há nada novo/a re-notificar.

7. Grave o novo estado em `estado-anterior.json` (sobrescrevendo), e registre uma linha objetiva no
   final deste ciclo resumindo o que foi encontrado.

Nunca escreva em `duvidas.md` de ninguém, nunca mova arquivo de tarefa, nunca decida
aprovação/reprovação. Você é somente leitura + notificação.
'@

function Show-PopupNotificacao($mensagem, $nomeSupervisor) {
    $msgFile = Join-Path $PSScriptRoot "ultima-notificacao.txt"
    Set-Content -Path $msgFile -Value $mensagem -Encoding utf8
    Start-Process powershell -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-Command',
        "Add-Type -AssemblyName System.Windows.Forms; [System.Media.SystemSounds]::Exclamation.Play(); `$m = Get-Content -Raw '$msgFile'; [System.Windows.Forms.MessageBox]::Show(`$m, 'Atualizacao - $nomeSupervisor', 'OK', 'Information') | Out-Null"
    )
}

$jaNotificou = $false
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
            if (-not $jaNotificou) {
                $candidatos = @()
                if ($evt.type -eq "assistant") {
                    foreach ($bloco in $evt.message.content) {
                        if ($bloco.type -eq "text" -and $bloco.text) { $candidatos += $bloco.text }
                    }
                } elseif ($evt.type -eq "result" -and $evt.result) {
                    $candidatos += $evt.result
                }
                foreach ($cand in $candidatos) {
                    if ($cand -match "(?m)^NOTIFICAR:\s*(.+)$") {
                        Show-PopupNotificacao -mensagem $Matches[1].Trim() -nomeSupervisor "SupTestesFrontEnd"
                        $jaNotificou = $true
                        break
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
