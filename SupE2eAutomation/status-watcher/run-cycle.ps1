# Executado pela Scheduled Task "SupE2eAutomation-StatusWatcher" a cada 15 minutos.
# Não implementa nada e não mexe em repo/ de nenhum módulo — só lê o estado de todos os
# subAgents + Agent Master do Supervisor SupE2eAutomation e avisa o Thiago (push notification)
# quando aparece algo novo que precisa da atenção dele.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# Reaproveita a conta do subAgent "geral" (contaA) — decisão do Thiago em 2026-09-14, ciente da
# concorrência de rate-limit com os subAgents que também usam essa conta.
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaA"

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# existir ALGO potencialmente notificável agora — dúvida pendente em qualquer módulo/Agent Master,
# PR legado em aguardando-aprovacao/, ou arquivo novo em tarefas/concluidas/ (de qualquer módulo)
# ou fila-merge/concluidos/ que ainda não apareça em estado-anterior.json (checagem por texto cru,
# sem interpretar o JSON — se o nome do arquivo não aparece em lugar nenhum do conteúdo gravado,
# trata como possível conclusão nova). Não replica aqui a lógica fina de "já notificado há menos de
# 2h" (isso continua dentro do prompt, comparando com estado-anterior.json) — o ganho real é pular
# por completo os ciclos em que não há NADA pendente/novo em lugar nenhum, que é o caso mais comum.
# Ver seção 3.4 do CLAUDE.md.
function Test-AlgoNotificavel {
    $estadoPath = "estado-anterior.json"
    $estadoTexto = if (Test-Path $estadoPath) { Get-Content $estadoPath -Raw -ErrorAction SilentlyContinue } else { "" }
    if (-not $estadoTexto) { $estadoTexto = "" }

    $modulos = Get-ChildItem -Path "../subagents" -Directory -ErrorAction SilentlyContinue
    foreach ($modulo in $modulos) {
        $duvidasPath = Join-Path $modulo.FullName "duvidas.md"
        if (Test-Path $duvidasPath) {
            $conteudo = Get-Content $duvidasPath -Raw -ErrorAction SilentlyContinue
            if ($conteudo -match '(?m)^Status:\s*pendente\s*$') { return $true }
        }

        $concluidasPath = Join-Path $modulo.FullName "tarefas/concluidas"
        $concluidas = Get-ChildItem -Path $concluidasPath -File -ErrorAction SilentlyContinue
        foreach ($arquivo in $concluidas) {
            if ($estadoTexto -notmatch [regex]::Escape($arquivo.Name)) { return $true }
        }
    }

    $amDuvidasPath = "../agent-master/duvidas.md"
    if (Test-Path $amDuvidasPath) {
        $conteudo = Get-Content $amDuvidasPath -Raw -ErrorAction SilentlyContinue
        if ($conteudo -match '(?m)^Status:\s*pendente\s*$') { return $true }
    }

    $legado = (Get-ChildItem -Path "../agent-master/fila-merge/aguardando-aprovacao" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($legado) { return $true }

    $concluidosMaster = Get-ChildItem -Path "../agent-master/fila-merge/concluidos" -File -ErrorAction SilentlyContinue
    foreach ($arquivo in $concluidosMaster) {
        if ($estadoTexto -notmatch [regex]::Escape($arquivo.Name)) { return $true }
    }

    return $false
}

if (-not (Test-AlgoNotificavel)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] nada pendente/novo em nenhum modulo/agent-master - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o "Status Watcher" do Supervisor "Sup Automação UI" (SupE2eAutomation). Você NUNCA
implementa código, nunca mexe em nenhuma pasta repo/, e nunca responde dúvida nenhuma — sua única
função é checar o estado de todos os subAgents e do Agent Master deste Supervisor e avisar o
Thiago via notificação quando surgir algo novo que precisa da atenção dele.

Rode agora um único ciclo:

1. Descubra os módulos existentes listando as subpastas de `../subagents/` (cada uma é um módulo).

2. Para cada módulo, colete:
   - **Lista de arquivos** (não só contagem) em `tarefas/pendentes/`, `tarefas/executando/`,
     `tarefas/aguardando-resposta/` — isso forma o "status de tarefas não concluídas" que vai no
     corpo de toda notificação (pedido do Thiago em 2026-09-14).
   - **Lista de arquivos** em `tarefas/concluidas/` — usada só pra detectar conclusão nova (passo
     6), não aparece inteira na notificação.
   - Todas as entradas de `duvidas.md` com `Status: pendente` (guarde o id da tarefa + um resumo
     curto da pergunta).

3. Para o Agent Master (`../agent-master/`), colete:
   - **Lista de arquivos** em `fila-merge/pendentes/` e `fila-merge/aguardando-aprovacao/` (esse
     último indica PR aberto esperando aprovação do Thiago no GitHub) — também entra no status de
     não concluídas.
   - **Lista de arquivos** em `fila-merge/concluidos/` — só pra detectar conclusão nova.
   - Entradas de `duvidas.md` com `Status: pendente`.

4. Monte dois blocos com essas informações:
   - `status_nao_concluidas`: pra cada módulo (+ Agent Master), quantos itens existem agora em
     pendentes/executando/aguardando-resposta (ou fila-merge/pendentes+aguardando-aprovacao pro
     Agent Master) — um resumo tipo `geral: 0p/1e/0a` (p=pendentes, e=executando,
     a=aguardando-resposta). Isso é contexto, não gatilho — vai no corpo de QUALQUER notificação
     que disparar por outro motivo, mas não dispara notificação sozinho.
   - `itens_para_notificar` (gatilhos, cada um vira um item com `id`, `tipo`): `duvida` (dúvida
     nova pendente), `pr` (PR novo em aguardando-aprovacao) — mesmo comportamento de sempre — e
     agora também `conclusao` (arquivo novo em `tarefas/concluidas/` de qualquer módulo, ou em
     `fila-merge/concluidos/` do Agent Master, que não existia no estado anterior — pedido do
     Thiago: a primeira notificação depois de uma tarefa concluir também deve aparecer).

5. Leia `estado-anterior.json` nesta pasta (`status-watcher/`), se existir. Ele guarda a lista de
   itens já vistos em ciclos anteriores, cada um com `id`, `tipo` (duvida, pr ou conclusao) e
   `primeira_vez_visto` (timestamp ISO), mais a lista de arquivos de `concluidas/`/`concluidos/`
   já vistos por módulo (pra saber o que já foi notificado como concluído e não repetir).

6. Compare o estado atual com o anterior:
   - Item novo tipo `duvida`/`pr` (não existia no estado anterior) → marque para notificar agora,
     com `primeira_vez_visto` = agora.
   - Item `duvida`/`pr` que já existia → mantenha o `primeira_vez_visto` original; marque para
     notificar de novo SOMENTE se já se passaram mais de 2 horas desde a ÚLTIMA notificação enviada
     sobre ele (guarde também `ultima_notificacao` no JSON) — evita lembrete a cada 15min do que já
     está pendente, mas reforça periodicamente o que ficou esquecido.
   - Item `duvida`/`pr` que sumiu (dúvida foi respondida, PR saiu de aguardando-aprovacao) →
     remova do estado, não precisa notificar sumiço.
   - Arquivo novo em `concluidas/`/`concluidos/` que não estava no estado anterior → gatilho
     `conclusao`, notifica UMA ÚNICA VEZ (não precisa reforçar depois — "concluída" é estado
     final, diferente de dúvida/PR pendente) e marca como já visto pra nunca mais notificar essa
     mesma tarefa.

7. Se houver 1+ gatilhos (`duvida`, `pr` ou `conclusao`) para notificar: tente enviar UMA
   notificação via PushNotification mesmo assim (pode voltar "not sent" por sessão interativa
   ativa — tudo bem, tente igual, não é seu problema resolver isso). Além disso — e isso é o que
   realmente garante que o Thiago vai ver — TERMINE sua resposta final deste ciclo com uma linha
   EXATA, sozinha, no formato `NOTIFICAR: <resumo dos gatilhos> | Status: <status_nao_concluidas
   compacto de todos os módulos + Agent Master>` (essa linha vai pro pop-up local, não pro
   PushNotification, então NÃO precisa caber em 200 caracteres — só não pode ter quebra de linha
   dentro dela). Exemplo: `NOTIFICAR: tarefa concluída em mop (monitor-diario-analisar-operacao) |
   Status: geral 1p/0e/0a, mop 0p/0e/0a, master 1 aviso pendente`. Essa linha aciona um pop-up
   local na tela do Thiago — não é uma ferramenta sua, é o `run-cycle.ps1` que procura essa linha
   no seu texto final e abre o pop-up sozinho, então basta a linha existir, no formato exato, em
   algum ponto da sua última mensagem. NUNCA inclua a linha `NOTIFICAR:` (nem tente
   PushNotification) se não há nenhum gatilho novo/a re-notificar — o bloco de status sozinho,
   sem gatilho, não justifica notificação.

8. Grave o novo estado em `estado-anterior.json` (sobrescrevendo — inclua as listas de
   `concluidas/`/`concluidos/` já vistas, pra não notificar a mesma conclusão de novo em ciclos
   futuros), e registre uma linha objetiva no final deste ciclo resumindo o que foi encontrado
   (mesmo que nada precise de notificação) — isso já vai para run-log.txt automaticamente via
   stdout, não precisa criar outro arquivo de log.

Nunca escreva em `duvidas.md` de ninguém, nunca mova arquivo de tarefa, nunca faça commit/push em
repo/ nenhum. Você é somente leitura + notificação.
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
                        Show-PopupNotificacao -mensagem $Matches[1].Trim() -nomeSupervisor "SupE2eAutomation"
                        $jaNotificou = $true
                        break
                    }
                }
            }
        } catch {}
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }
