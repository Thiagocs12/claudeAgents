# Executado pela Scheduled Task "SupE2eAutomation-SubAgent-mop" a cada 15 minutos.
# Roda um único ciclo do subAgent do módulo "mop" em modo não interativo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# --- Cadência adaptativa da Scheduled Task (pedido do Thiago, 2026-09-17) ---
# Ociosa (nada pra fazer neste ciclo) passa a rodar de 1 em 1 hora em vez de continuar batendo no
# intervalo normal só pra constatar fila vazia. Assim que aparecer algo pra fazer (ciclo real ou
# retomando tarefa incompleta), volta pro intervalo ativo de sempre (10min) — o script se reagenda
# sozinho, sem precisar de Status Watcher/monitor externo. Preserva StartBoundary/Actions/Principal
# originais da task, só troca o intervalo de repetição (mesma técnica usada nas trocas de cadência
# já documentadas em CONHECIMENTO-SUPERVISORES.md, seção "Cadência real").
$nomeTaskAgendada = "SupE2eAutomation-SubAgent-mop"
$intervaloAtivoTask = New-TimeSpan -Minutes 10
function Set-CadenciaAdaptativa {
    param(
        [ValidateSet('ocioso','ativo')][string]$Estado,
        [string]$LogPath
    )
    $intervaloAlvo = if ($Estado -eq 'ocioso') { New-TimeSpan -Hours 1 } else { $intervaloAtivoTask }
    try {
        $task = Get-ScheduledTask -TaskName $nomeTaskAgendada -ErrorAction Stop
        $trigger = $task.Triggers | Select-Object -First 1
        $intervaloAtual = [System.Xml.XmlConvert]::ToTimeSpan($trigger.Repetition.Interval)
        if ($intervaloAtual -ne $intervaloAlvo) {
            # Ajusta so o intervalo de repeticao via COM (Schedule.Service), preservando o gatilho
            # semanal seg-sex 9h-19h (janela comercial, pedido do Thiago 2026-09-17 noite) - trocar
            # o trigger inteiro via New-ScheduledTaskTrigger -Once destruiria essa janela.
            $service = New-Object -ComObject "Schedule.Service"
            $service.Connect()
            $folder = $service.GetFolder("\")
            $taskCom = $folder.GetTask($nomeTaskAgendada)
            $estadoHabilitado = $taskCom.Enabled
            $def = $taskCom.Definition
            $def.Triggers.Item(1).Repetition.Interval = "PT$([int]$intervaloAlvo.TotalMinutes)M"
            $folder.RegisterTaskDefinition($nomeTaskAgendada, $def, 4, $null, $null, 3) | Out-Null
            $folder.GetTask($nomeTaskAgendada).Enabled = $estadoHabilitado
            "$(Get-Date -Format 'HH:mm:ss') | [cadencia] $nomeTaskAgendada ajustada para $Estado (repeticao=$intervaloAlvo)" |
                Add-Content -Path $LogPath -Encoding utf8
        }
    } catch {
        "$(Get-Date -Format 'HH:mm:ss') | [cadencia] nao foi possivel ajustar $nomeTaskAgendada - $($_.Exception.Message)" |
            Add-Content -Path $LogPath -Encoding utf8
    }
}

# --- Scheduled Task sob demanda (pedido do Thiago, 2026-09-17 noite): substitui a cadencia ociosa
# quando a fila fica vazia de verdade - em vez de so desacelerar pra 1h, desabilita a propria
# Scheduled Task (Disable-ScheduledTask). So volta a rodar quando alguem reabilitar: o Supervisor,
# ao gravar uma tarefa nova em tarefas/pendentes/ ou marcar uma duvida como respondida em
# duvidas.md, e responsavel por chamar Enable-ScheduledTask no mesmo passo (ver
# CONHECIMENTO-SUPERVISORES.md, secao "Scheduled Task sob demanda"). Nao se aplica ao branch de
# PAUSA-HML.flag (ambiente fora do ar) - esse continua so com cadencia ociosa, sem desabilitar.
function Disable-TaskSobDemanda {
    param([string]$LogPath)
    try {
        Disable-ScheduledTask -TaskName $nomeTaskAgendada -ErrorAction Stop | Out-Null
        "$(Get-Date -Format 'HH:mm:ss') | [sob-demanda] $nomeTaskAgendada desabilitada (fila vazia)" |
            Add-Content -Path $LogPath -Encoding utf8
    } catch {
        "$(Get-Date -Format 'HH:mm:ss') | [sob-demanda] nao foi possivel desabilitar $nomeTaskAgendada - $($_.Exception.Message)" |
            Add-Content -Path $LogPath -Encoding utf8
    }
}

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
# Enquanto C:\Multiplica\claudeAgents\PAUSA-HML.flag existir, este processo depende de logar na
# plataforma (HML) e por isso não tenta nenhum ciclo — evita gastar tokens/tempo retentando contra
# um ambiente confirmadamente fora do ar. Removido pelo Thiago (ou por mim a pedido dele) assim que
# o ambiente for restabelecido.
if (Test-Path "C:\Multiplica\claudeAgents\PAUSA-HML.flag") {
    "$(Get-Date -Format 'HH:mm:ss') | [pausado] ambiente HML indisponivel (PAUSA-HML.flag existe) - ciclo nao executado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    Set-CadenciaAdaptativa -Estado 'ocioso' -LogPath (Join-Path $PSScriptRoot "run-log.txt")
    exit 0
}

# --- Fila global de contas (pedido do Thiago, 2026-09-17): substitui a politica anterior de
# "conta de casa" + fallback por rate-limit. Agora e so sobre concorrencia: no maximo 1 tarefa por
# conta ao mesmo tempo, em qualquer Supervisor/modulo - nao importa quantas tarefas existam nem de
# qual Supervisor. contaA pega a primeira tarefa que pedir um slot, contaB pega a segunda; uma
# terceira tarefa (de qualquer modulo) espera uma das duas liberar, sem alternar no meio do
# caminho. `ultima-utilizacao.json` continua sendo gravado, mas so pra fins informativos (status
# da Gerente) - nao decide mais qual conta usar.
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
# alguma". Cada ciclo com trabalho pendente registra o id da sua tarefa atual (o timestamp no
# começo do id já é a idade) em fila-tarefas.json antes de tentar um slot; se existir tarefa mais
# antiga que a minha em outro módulo — em quantidade >= slots livres agora — cedo a vez neste ciclo
# mesmo com slot livre, pro módulo mais antigo ter a chance primeiro no próximo disparo dele.
# prioridade.json (gravado pela Gerente quando o Thiago pede prioridade numa tarefa específica)
# sempre vence a ordem por idade.
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
    Atualizar-FilaTarefas -NomeModulo "SupE2eAutomation/mop" -IdTarefa $null
    Disable-TaskSobDemanda -LogPath (Join-Path $PSScriptRoot "run-log.txt")
    exit 0
}

$idTarefaAtual = (Get-ChildItem -Path "tarefas/executando" -File -ErrorAction SilentlyContinue | Select-Object -First 1).BaseName
$contaEfetiva = Adquirir-SlotConta -NomeModulo "SupE2eAutomation/mop" -IdTarefa $idTarefaAtual -LogPath (Join-Path $PSScriptRoot "run-log.txt")
if (-not $contaEfetiva) {
    Set-CadenciaAdaptativa -Estado 'ocioso' -LogPath (Join-Path $PSScriptRoot "run-log.txt")
    exit 0
}
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\$contaEfetiva"

$prompt = @'
Você é o SubAgent do módulo "mop" (automação de UI). Leia AGENTE.md nesta pasta e siga suas
regras fixas à risca. Execute agora UM único ciclo da lógica operacional:

1. A fila de tarefas já foi sincronizada deterministicamente antes deste ciclo (dúvida respondida
   já volta pra tarefas/pendentes/ sozinha, e a tarefa mais antiga já foi movida pra
   tarefas/executando/ se estava vazia) — há exatamente uma tarefa em tarefas/executando/ agora.
   RETOME-A (um ciclo anterior pode ter esgotado antes de terminar): procure em repo/ uma branch já
   criada para essa tarefa (nome derivado do id/slug); se existir, dê checkout nela e continue a
   implementação de onde parou (não recomece do zero, não descarte trabalho já feito, incluindo
   qualquer coisa que já tenha descoberto sobre a tela do Monitor Diário); se não houver nenhuma
   branch/progresso, trate como se estivesse começando agora.
2. Leia docs/documentacao.md inteiro.
3. No repositório em repo/: se está começando a tarefa agora, dê pull na branch reviewAgents e crie
   uma branch nova para ela; se está retomando (passo 1), não refaça pull/checkout, continue na
   branch existente. Implemente a tarefa integralmente conforme a regra 2 do AGENTE.md (ler e
   seguir o padrão do README.md do repo, atualizando-o se necessário). Reaproveite a fundação de
   login já implementada (cy.loginComoPerfil) — não reimplemente login. Se o ciclo for esgotar
   antes de terminar, faça commit do progresso parcial na branch (mesmo incompleto, mesmo que seja
   só anotações do que já foi descoberto sobre a tela) — não deixe só em arquivos não commitados.
4. Rode um autoteste sobre sua própria implementação antes de considerar concluído.
5. Se concluir com sucesso: siga a regra 6 do AGENTE.md (commit + push da branch, aviso em
   ../../agent-master/fila-merge/pendentes/ com a branch e o id da tarefa — o Agent Master vai
   abrir um Pull Request, não é merge direto — atualize docs/documentacao.md, mova o arquivo de
   tarefas/executando/ para tarefas/concluidas/).
6. Se travar numa dúvida bloqueante: siga a regra 7 do AGENTE.md (registre em duvidas.md no
   formato padrão, mova o arquivo de tarefas/executando/ para tarefas/aguardando-resposta/, e
   encerre o ciclo sem terminar a tarefa). Nunca responda sua própria dúvida.

Nunca trabalhe em mais de uma tarefa ativa por vez.
'@

$script:ultimoRateLimit = $null
$script:limiteSemanalResetsAt = $null

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
        # --- Limite semanal (pedido do Thiago, 2026-09-18): "You've hit your weekly limit" nao vem
        # como rate_limit_event estruturado, so como texto falado - sem isso, Set-UtilizacaoConta
        # nunca grava a saturacao e Test-ContaSaturada (Adquirir-SlotConta) continua tentando essa
        # conta a toa. Extrai a data/hora do proprio texto ("resets Sep 21, 3pm") e trata como
        # saturacao de longa duracao (mesmo mecanismo do five_hour, so com resetsAt mais distante).
        if ($texto -match '\[fala\].*weekly limit.*resets\s+(?<mes>\w{3})\s+(?<dia>\d{1,2}),\s+(?<hora>\d{1,2})(?<ampm>am|pm)') {
            try {
                $anoRef = (Get-Date).Year
                $dataStr = "$($Matches.mes) $($Matches.dia) $anoRef $($Matches.hora):00 $($Matches.ampm.ToUpper())"
                $dtLocal = [datetime]::ParseExact($dataStr, "MMM d yyyy h:mm tt", [System.Globalization.CultureInfo]::InvariantCulture)
                if ($dtLocal -lt (Get-Date).AddDays(-1)) { $dtLocal = $dtLocal.AddYears(1) }
                $script:limiteSemanalResetsAt = [DateTimeOffset]::new([datetime]::SpecifyKind($dtLocal, 'Unspecified'), [TimeSpan]::FromHours(-3)).ToUnixTimeSeconds()
            } catch {}
        }
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }

if ($script:limiteSemanalResetsAt) {
    Set-UtilizacaoConta -Conta $contaEfetiva -Utilizacao 1 -ResetsAt $script:limiteSemanalResetsAt
} elseif ($script:ultimoRateLimit) {
    Set-UtilizacaoConta -Conta $contaEfetiva -Utilizacao $script:ultimoRateLimit.utilization -ResetsAt $script:ultimoRateLimit.resetsAt
}
Liberar-SlotConta -Conta $contaEfetiva -LogPath (Join-Path $PSScriptRoot "run-log.txt")

# --- Reabilita o Agent Master sob demanda se este ciclo deixou aviso novo em fila-merge/pendentes/
# (ele pode ter se autodesabilitado por fila vazia - ver Disable-TaskSobDemanda) ---
if ((Get-ChildItem -Path "../../agent-master/fila-merge/pendentes" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
    try {
        $taskMaster = Get-ScheduledTask -TaskName "SupE2eAutomation-AgentMaster" -ErrorAction Stop
        if ($taskMaster.State -eq 'Disabled') {
            Enable-ScheduledTask -TaskName "SupE2eAutomation-AgentMaster" -ErrorAction Stop | Out-Null
            "$(Get-Date -Format 'HH:mm:ss') | [sob-demanda] SupE2eAutomation-AgentMaster reabilitada (aviso novo em fila-merge)" |
                Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
        }
    } catch {}
}

# Publica no remoto tudo que este ciclo escreveu/moveu no repo raiz (docs, duvidas, tarefas) — ver
# função Sync-RepoRaizClaudeAgents definida no início deste script.
Sync-RepoRaizClaudeAgents -LogPath (Join-Path $PSScriptRoot "run-log.txt") -PermitirCommitEPush -MensagemCommit "mop (E2e): sincroniza estado do ciclo (auto, $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"

Set-CadenciaAdaptativa -Estado 'ativo' -LogPath (Join-Path $PSScriptRoot "run-log.txt")
