# Executado pela Scheduled Task "SupAutomacaoUteis-AgentMaster" no fim do dia: dispara as 18:00 e
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

# --- Fila global de contas (pedido do Thiago, 2026-09-17): substitui a politica anterior de
# "conta de casa" + fallback por rate-limit. Agora e so sobre concorrencia: no maximo 1 tarefa por
# conta ao mesmo tempo, em qualquer Supervisor/modulo - nao importa quantas tarefas existam nem de
# qual Supervisor. contaA pega a primeira tarefa que pedir um slot, contaB pega a segunda; uma
# terceira tarefa (de qualquer modulo, incluindo outro Agent Master) espera uma das duas liberar,
# sem alternar no meio do caminho. `ultima-utilizacao.json` continua sendo gravado, mas so pra fins
# informativos (status da Gerente) - nao decide mais qual conta usar.
function Set-UtilizacaoConta {
    param([string]$Conta, [double]$Utilizacao, [long]$ResetsAt)
    $pasta = "$env:USERPROFILE\.claude-accounts\$Conta"
    if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Force -Path $pasta | Out-Null }
    @{ five_hour_utilization = $Utilizacao; resetsAt = $ResetsAt; atualizado_em = (Get-Date).ToUniversalTime().ToString("o") } |
        ConvertTo-Json | Set-Content -Path "$pasta\ultima-utilizacao.json" -Encoding utf8
}

# --- Pular conta com rate-limit ja conhecido (pedido do Thiago, 2026-09-17 tarde): se o ultimo
# registro de ultima-utilizacao.json de uma conta mostra five_hour_utilization >=99% e o resetsAt
# ainda nao passou, Adquirir-SlotConta tenta a OUTRA conta primeiro - evita gastar um ciclo inteiro
# (invocacao real do claude -p, custo $0 mas tempo/log perdido) so pra redescobrir que a conta
# selecionada esta sem sessao. Se as duas estiverem saturadas ao mesmo tempo, a ordem original
# (contaA, contaB) e mantida - sem alternativa mesmo assim. Se resetsAt ja passou, a conta volta a
# ser tratada como disponivel automaticamente (nao precisa de limpeza manual).
function Test-ContaSaturada {
    param([string]$Conta)
    $caminho = "$env:USERPROFILE\.claude-accounts\$Conta\ultima-utilizacao.json"
    if (-not (Test-Path $caminho)) { return $false }
    try {
        $info = Get-Content $caminho -Raw | ConvertFrom-Json
        if (-not $info.five_hour_utilization -or $info.five_hour_utilization -lt 0.99) { return $false }
        $resetsAt = [DateTimeOffset]::FromUnixTimeSeconds([long]$info.resetsAt).UtcDateTime
        return ((Get-Date).ToUniversalTime() -lt $resetsAt)
    } catch { return $false }
}

# --- Ordem global por antiguidade + prioridade manual (pedido do Thiago, 2026-09-17): "Gerente
# controla a ordem das tarefas, sempre a mais antiga primeiro, a menos que peça prioridade em
# alguma". Cada ciclo com trabalho pendente registra o id da sua tarefa/aviso mais antigo (o
# timestamp no começo do id já é a idade) em fila-tarefas.json antes de tentar um slot; se existir
# tarefa mais antiga que a minha em outro módulo — em quantidade >= slots livres agora — cedo a vez
# neste ciclo mesmo com slot livre, pro módulo mais antigo ter a chance primeiro no próximo disparo
# dele. prioridade.json (gravado pela Gerente quando o Thiago pede prioridade numa tarefa
# específica) sempre vence a ordem por idade.
function Get-DataDoId {
    param([string]$Id)
    if ($Id -and $Id -match '^(\d{14})') {
        try { return [datetime]::ParseExact($Matches[1], "yyyyMMddHHmmss", $null) } catch { return $null }
    }
    return $null
}

function Atualizar-FilaTarefas {
    param([string]$NomeModulo, [string]$IdTarefa)
    $mutex = New-Object System.Threading.Mutex($false, "Global\ClaudeAgentsContaSlot")
    try {
        $mutex.WaitOne(30000) | Out-Null
        $caminho = "$env:USERPROFILE\.claude-accounts\fila-tarefas.json"
        $fila = [ordered]@{}
        if (Test-Path $caminho) {
            try {
                $obj = Get-Content $caminho -Raw | ConvertFrom-Json
                foreach ($prop in $obj.PSObject.Properties) { $fila[$prop.Name] = $prop.Value }
            } catch {}
        }
        if ($IdTarefa) {
            $fila[$NomeModulo] = $IdTarefa
        } elseif ($fila.Contains($NomeModulo)) {
            $fila.Remove($NomeModulo)
        }
        ($fila | ConvertTo-Json) | Set-Content -Path $caminho -Encoding utf8
    } finally {
        $mutex.ReleaseMutex()
    }
}

# Lock por arquivo (%USERPROFILE%\.claude-accounts\<conta>\em-uso.lock), claim atomico via Mutex
# nomeado global (mesma tecnica do Sync-RepoRaizClaudeAgents). Lock considerado travado/liberavel
# depois de 4h (processo que crashou sem liberar) - nao deveria acontecer num ciclo normal.
function Adquirir-SlotConta {
    param([string]$NomeModulo, [string]$IdTarefa, [string]$LogPath)
    $mutex = New-Object System.Threading.Mutex($false, "Global\ClaudeAgentsContaSlot")
    $contaObtida = $null
    $devoCeder = $false
    $motivoCeder = $null
    try {
        $mutex.WaitOne(30000) | Out-Null
        Atualizar-FilaTarefas -NomeModulo $NomeModulo -IdTarefa $IdTarefa

        $prioridadePath = "$env:USERPROFILE\.claude-accounts\prioridade.json"
        $prioridadeAtiva = $null
        if (Test-Path $prioridadePath) {
            try { $prioridadeAtiva = (Get-Content $prioridadePath -Raw | ConvertFrom-Json).idTarefa } catch {}
        }

        if ($prioridadeAtiva -and $prioridadeAtiva -ne $IdTarefa) {
            $devoCeder = $true
            $motivoCeder = "prioridade manual ativa em outra tarefa ($prioridadeAtiva)"
        } elseif (-not $prioridadeAtiva) {
            $livres = (@("contaA","contaB") | Where-Object { -not (Test-Path "$env:USERPROFILE\.claude-accounts\$_\em-uso.lock") }).Count
            if ($livres -gt 0) {
                $minhaData = Get-DataDoId -Id $IdTarefa
                $maisAntigas = 0
                if ($minhaData) {
                    $caminhoFila = "$env:USERPROFILE\.claude-accounts\fila-tarefas.json"
                    if (Test-Path $caminhoFila) {
                        try {
                            $obj = Get-Content $caminhoFila -Raw | ConvertFrom-Json
                            foreach ($prop in $obj.PSObject.Properties) {
                                if ($prop.Name -eq $NomeModulo) { continue }
                                $outraData = Get-DataDoId -Id $prop.Value
                                if ($outraData -and $outraData -lt $minhaData) { $maisAntigas++ }
                            }
                        } catch {}
                    }
                }
                if ($maisAntigas -ge $livres) {
                    $devoCeder = $true
                    $motivoCeder = "$maisAntigas tarefa(s) mais antiga(s) disputando $livres slot(s) livre(s)"
                }
            }
        }

        if (-not $devoCeder) {
            $ordemTentativa = @("contaA","contaB") | Sort-Object { if (Test-ContaSaturada -Conta $_) { 1 } else { 0 } }
            foreach ($conta in $ordemTentativa) {
                $pastaConta = "$env:USERPROFILE\.claude-accounts\$conta"
                $lockPath = "$pastaConta\em-uso.lock"
                $livre = $true
                if (Test-Path $lockPath) {
                    try {
                        $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
                        if (((Get-Date).ToUniversalTime() - [datetime]$lock.desde) -lt (New-TimeSpan -Hours 4)) {
                            $livre = $false
                        }
                    } catch { $livre = $true }
                }
                if ($livre) {
                    if (-not (Test-Path $pastaConta)) { New-Item -ItemType Directory -Force -Path $pastaConta | Out-Null }
                    @{ ocupado_por = $NomeModulo; pid = $PID; desde = (Get-Date).ToUniversalTime().ToString("o") } |
                        ConvertTo-Json | Set-Content -Path $lockPath -Encoding utf8
                    $contaObtida = $conta
                    break
                }
            }
        }
    } finally {
        $mutex.ReleaseMutex()
    }
    if ($contaObtida) {
        Atualizar-FilaTarefas -NomeModulo $NomeModulo -IdTarefa $null
        "$(Get-Date -Format 'HH:mm:ss') | [fila-global] slot obtido: $contaObtida (modulo=$NomeModulo, tarefa=$IdTarefa)" |
            Add-Content -Path $LogPath -Encoding utf8
    } elseif ($devoCeder) {
        "$(Get-Date -Format 'HH:mm:ss') | [fila-global] cedendo a vez ($motivoCeder) - tarefa=$IdTarefa" |
            Add-Content -Path $LogPath -Encoding utf8
    } else {
        "$(Get-Date -Format 'HH:mm:ss') | [fila-global] contaA e contaB ocupadas por outro modulo agora - ciclo aguarda a proxima execucao" |
            Add-Content -Path $LogPath -Encoding utf8
    }
    return $contaObtida
}

function Liberar-SlotConta {
    param([string]$Conta, [string]$LogPath)
    if (-not $Conta) { return }
    Remove-Item -Path "$env:USERPROFILE\.claude-accounts\$Conta\em-uso.lock" -Force -ErrorAction SilentlyContinue
    "$(Get-Date -Format 'HH:mm:ss') | [fila-global] slot liberado: $Conta" | Add-Content -Path $LogPath -Encoding utf8
}

# Token do GitHub CLI (gh) para abrir/consultar PRs — lido de arquivo local (não versionado, nunca
# embutido neste script), reaproveitado do SupE2eAutomation.
$env:GH_TOKEN = (Get-Content (Join-Path $PSScriptRoot ".gh-token") -Raw).Trim()
$env:Path = "$env:Path;$env:LOCALAPPDATA\Programs\gh\bin"

# --- Garantia determinística do PR único reviewAgents -> master (movida de instrução do prompt do
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

Confirmar-PRUnico -Base "master" -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# houver algo pra processar em fila-merge/. Ver seção "Pré-checagem em PowerShell antes de chamar
# claude -p" do CLAUDE.md.
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
    Atualizar-FilaTarefas -NomeModulo "SupAutomacaoUteis/agent-master" -IdTarefa $null
    # --- Scheduled Task sob demanda (pedido do Thiago, 2026-09-17 noite): fila-merge vazia
    # desabilita a propria Scheduled Task - volta a ser reabilitada por qualquer subAgent que
    # deixar um aviso novo em fila-merge/pendentes/ (ver Enable-ScheduledTask no fim do run-cycle.ps1
    # de cada subAgent / CONHECIMENTO-SUPERVISORES.md, secao "Scheduled Task sob demanda").
    try {
        Disable-ScheduledTask -TaskName "SupAutomacaoUteis-AgentMaster" -ErrorAction Stop | Out-Null
        "$(Get-Date -Format 'HH:mm:ss') | [sob-demanda] SupAutomacaoUteis-AgentMaster desabilitada (fila-merge vazia)" |
            Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    } catch {
        "$(Get-Date -Format 'HH:mm:ss') | [sob-demanda] nao foi possivel desabilitar SupAutomacaoUteis-AgentMaster - $($_.Exception.Message)" |
            Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }
    exit 0
}

$idTarefaAtual = (Get-ChildItem -Path "fila-merge/pendentes","fila-merge/aguardando-aprovacao" -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1).BaseName
$contaEfetiva = Adquirir-SlotConta -NomeModulo "SupAutomacaoUteis/agent-master" -IdTarefa $idTarefaAtual -LogPath (Join-Path $PSScriptRoot "run-log.txt")
if (-not $contaEfetiva) {
    exit 0
}
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\$contaEfetiva"

$prompt = @'
Você é o Agent Master do Sup AutomaçãoUteis. Leia AGENTE.md nesta pasta e siga suas regras fixas à
risca — em especial (fluxo mudou em 2026-09-14, pedido explícito do Thiago, mesmo padrão do
SupE2eAutomation): você faz merge direto com push na reviewAgents de cada tarefa aprovada nos
testes, SEM PR nem aprovação humana por tarefa. Você NUNCA mergeia/dá push direto na master. O PR
unico e continuo reviewAgents para master (unico ponto de revisao manual do Thiago) ja e
garantido/criado deterministicamente por PowerShell antes deste ciclo (funcao Confirmar-PRUnico no
run-cycle.ps1) — voce nao precisa mais checar/criar esse PR, so cuidar da fila-merge abaixo. gh CLI
ja autenticado via GH_TOKEN, disponivel se precisar dele por outro motivo. Execute agora UM unico
ciclo da logica operacional:

1. Leia docs/documentacao.md inteiro.
2. Legado: se houver algo em fila-merge/aguardando-aprovacao/ (resquicio do modelo antigo de PR
   por tarefa; o unico caso conhecido, PR numero 5 da branch keycloakUser/clonar-usuario-prod-hml,
   ja foi mergeado e movido para concluidos/ - esta pasta deve estar vazia agora, a menos que
   surja outro caso), para cada um rode gh pr view passando a branch do aviso e pedindo os campos
   state, mergedAt e url em json.
   - MERGED: git pull origin reviewAgents em repo/; atualize repo/.env se a branch trouxe
     variável nova (compare .env.example antes/depois, busque valor em
     ../subagents/<modulo>/docs/documentacao.md ou na tarefa concluída — nunca invente); depois
     sincronize C:\multiplica\cypress-uteis de volta para reviewAgents (git pull, npm install
     --legacy-peer-deps se necessário, copiar repo/.env por cima do .env de lá). Mova o aviso para
     fila-merge/concluidos/ e registre em docs/documentacao.md.
   - CLOSED sem merge: registre dúvida em duvidas.md perguntando o motivo/próximos passos, sem
     mexer no aviso.
   - OPEN: não faça nada com esse aviso agora — nenhum aviso novo deve passar por essa pasta daqui
     pra frente.
3. Para cada aviso em fila-merge/pendentes/ (fluxo normal, novo): no repo/, busque a branch e faça
   um merge de teste LOCAL contra reviewAgents para achar conflito; se houver, resolva com a skill
   /resolve-conflicts e comite a resolução na própria branch da feature antes de mesclar de
   verdade. Atualize repo/.env se necessário (mesma lógica de sempre, nunca invente/deixe em
   branco). Voce NAO roda os testes da automacao (2026-09-17, pedido do Thiago: o subAgent ja
   rodou o autoteste antes de avisar voce, rodar de novo aqui duplicaria trabalho). Se nao houver
   conflito, ou o conflito foi resolvido com sucesso: finalize o merge de verdade e de push direto
   na reviewAgents (sem PR, sem esperar aprovacao), mova o aviso de fila-merge/pendentes/ direto
   para fila-merge/concluidos/ (nunca passa por aguardando-aprovacao/ nesse fluxo). Se nao
   resolver conflito: trate como dúvida bloqueante, desfaça o merge local (não deixe a
   reviewAgents local suja), deixe o aviso em fila-merge/pendentes/.
4. Depois de processar os avisos, sincronize C:\multiplica\cypress-uteis (pasta PESSOAL do Thiago
   — reaproveitada por decisão dele mesmo, pode ter mudanças não commitadas) sempre para a
   reviewAgents (não há mais branch de PR-por-tarefa pra testar antes de aprovar), rode npm
   install --legacy-peer-deps se necessário (nunca npm ci, o repo nao versiona
   package-lock.json). Em qualquer caso, copie repo/.env por cima do .env dessa pasta. Nunca
   exponha conteúdo de .env/token em docs/documentacao.md, duvidas.md ou no log de saída — só
   confirme que foi sincronizado. Se o pull/checkout falhar (working tree suja, divergência), não
   force nada: registre em duvidas.md.
5. Registre em docs/documentacao.md tudo que foi feito (merges feitos direto na reviewAgents,
   conflitos resolvidos, variáveis de .env novas só o nome, e estado da sincronização da pasta de
   teste manual).
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
Liberar-SlotConta -Conta $contaEfetiva -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# Publica no remoto tudo que este ciclo escreveu/moveu no repo raiz (docs, duvidas, tarefas) — ver
# função Sync-RepoRaizClaudeAgents definida no início deste script.
Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt") -PermitirCommitEPush -MensagemCommit "Agent Master AutomacaoUteis: sincroniza estado do ciclo (auto, $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
