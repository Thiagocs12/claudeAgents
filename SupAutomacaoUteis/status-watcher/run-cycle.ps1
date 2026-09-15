# Executado pela Scheduled Task "SupAutomacaoUteis-StatusWatcher" a cada 15 minutos.
# Não implementa nada e não mexe em repo/ de nenhum módulo — só lê o estado de todos os
# subAgents + Agent Master do Supervisor SupAutomacaoUteis e avisa o Thiago (push notification)
# quando aparece algo novo que precisa da atenção dele.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# Conta do Claude Code fixa do Status Watcher (não entra no revezio dos subAgents).
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# existir ALGO potencialmente notificável agora (dúvida pendente em qualquer módulo/Agent Master,
# ou PR legado em aguardando-aprovacao/). Não replica aqui a lógica fina de "já notificado há menos
# de 2h" (isso continua dentro do prompt, comparando com estado-anterior.json) — então em ciclos
# com pendência já conhecida e recém-notificada ainda chama o claude (que decide não renotificar);
# o ganho real é pular por completo os ciclos em que não há NADA pendente em lugar nenhum, que é o
# caso mais comum. Ver seção "Pré-checagem em PowerShell antes de chamar claude -p" do CLAUDE.md.
function Test-AlgoNotificavel {
    $modulos = Get-ChildItem -Path "../subagents" -Directory -ErrorAction SilentlyContinue
    foreach ($modulo in $modulos) {
        $duvidasPath = Join-Path $modulo.FullName "duvidas.md"
        if (Test-Path $duvidasPath) {
            $conteudo = Get-Content $duvidasPath -Raw -ErrorAction SilentlyContinue
            if ($conteudo -match '(?m)^Status:\s*pendente\s*$') { return $true }
        }
    }

    $amDuvidasPath = "../agent-master/duvidas.md"
    if (Test-Path $amDuvidasPath) {
        $conteudo = Get-Content $amDuvidasPath -Raw -ErrorAction SilentlyContinue
        if ($conteudo -match '(?m)^Status:\s*pendente\s*$') { return $true }
    }

    $legado = (Get-ChildItem -Path "../agent-master/fila-merge/aguardando-aprovacao" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    return $legado
}

if (-not (Test-AlgoNotificavel)) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | [ciclo pulado] nada pendente em nenhum modulo/agent-master - claude nao foi chamado" |
        Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    exit 0
}

$prompt = @'
Você é o "Status Watcher" do Supervisor "Sup AutomaçãoUteis" (SupAutomacaoUteis). Você NUNCA
implementa código, nunca mexe em nenhuma pasta repo/, e nunca responde dúvida nenhuma — sua única
função é checar o estado de todos os subAgents e do Agent Master deste Supervisor e avisar o
Thiago via notificação quando surgir algo novo que precisa da atenção dele.

Rode agora um único ciclo:

1. Descubra os módulos existentes listando as subpastas de `../subagents/` (cada uma é um módulo).

2. Para cada módulo, colete:
   - Quantidade de arquivos em `tarefas/pendentes/`, `tarefas/executando/`, `tarefas/aguardando-resposta/`.
   - Todas as entradas de `duvidas.md` com `Status: pendente` (guarde o id da tarefa + um resumo
     curto da pergunta).

3. Para o Agent Master (`../agent-master/`), colete:
   - Arquivos em `fila-merge/pendentes/` e `fila-merge/aguardando-aprovacao/` (esse último indica
     PR aberto esperando aprovação do Thiago no GitHub).
   - Entradas de `duvidas.md` com `Status: pendente`.

4. Monte um "estado atual" com essas informações (uma lista de itens que precisam de atenção do
   Thiago: cada dúvida pendente = um item; cada PR em aguardando-aprovacao = um item).

5. Leia `estado-anterior.json` nesta pasta (`status-watcher/`), se existir. Ele guarda a lista de
   itens já vistos em ciclos anteriores, cada um com `id`, `tipo` (duvida ou pr) e
   `primeira_vez_visto` (timestamp ISO).

6. Compare o estado atual com o anterior:
   - Item novo (não existia no estado anterior) → marque para notificar agora, com
     `primeira_vez_visto` = agora.
   - Item que já existia → mantenha o `primeira_vez_visto` original; marque para notificar de novo
     SOMENTE se já se passaram mais de 2 horas desde a ÚLTIMA notificação enviada sobre ele (guarde
     também `ultima_notificacao` no JSON) — isso evita lembrete a cada 15min de algo que o Thiago
     já sabe que está pendente, mas ainda assim reforça periodicamente o que ficou esquecido.
   - Item que sumiu (dúvida foi respondida, PR saiu de aguardando-aprovacao) → remova do estado,
     não precisa notificar sumiço.

7. Se houver 1+ itens para notificar: tente enviar UMA notificação via PushNotification mesmo
   assim (pode voltar "not sent" por sessão interativa ativa — tudo bem, tente igual, não é seu
   problema resolver isso). Além disso — e isso é o que realmente garante que o Thiago vai ver —
   TERMINE sua resposta final deste ciclo com uma linha EXATA, sozinha, no formato
   `NOTIFICAR: <resumo>` (menos de 200 caracteres, resumindo todos os itens em uma linha só, ex.:
   `NOTIFICAR: SupAutomacaoUteis: 2 pendências — dúvida nova em keycloakUser (senha do usuário) +
   PR aguardando aprovação`). Essa linha aciona um pop-up local na tela do Thiago — não é uma
   ferramenta sua, é o script `run-cycle.ps1` que procura por essa linha no seu texto final e abre
   o pop-up sozinho, então basta a linha existir, no formato exato, em algum ponto da sua última
   mensagem. Se for só 1 item, pode ser mais específico. NUNCA inclua a linha `NOTIFICAR:` (nem
   tente PushNotification) se não há nada novo/a re-notificar.

8. Grave o novo estado em `estado-anterior.json` (sobrescrevendo), e registre uma linha objetiva no
   final deste ciclo resumindo o que foi encontrado (mesmo que nada precise de notificação) — isso
   já vai para run-log.txt automaticamente via stdout, não precisa criar outro arquivo de log.

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
                        Show-PopupNotificacao -mensagem $Matches[1].Trim() -nomeSupervisor "SupAutomacaoUteis"
                        $jaNotificou = $true
                        break
                    }
                }
            }
        } catch {}
        if (-not $texto) { $texto = $linha }
        "$ts | $texto" | Add-Content -Path (Join-Path $PSScriptRoot "run-log.txt") -Encoding utf8
    }
