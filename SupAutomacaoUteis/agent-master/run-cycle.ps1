# Executado pela Scheduled Task "SupAutomacaoUteis-AgentMaster" a cada 15 minutos.
# Roda um único ciclo do Agent Master em modo não interativo.

$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

# Conta do Claude Code fixa do Agent Master (não entra no revezio dos subAgents) — reaproveitada
# do SupE2eAutomation.
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"

# Token do GitHub CLI (gh) para abrir/consultar PRs — lido de arquivo local (não versionado, nunca
# embutido neste script), reaproveitado do SupE2eAutomation.
$env:GH_TOKEN = (Get-Content (Join-Path $PSScriptRoot ".gh-token") -Raw).Trim()
$env:Path = "$env:Path;$env:LOCALAPPDATA\Programs\gh\bin"

# Checagem determinística (sem custo de chamada ao Claude): só vale a pena chamar `claude -p` se
# houver algo pra processar em fila-merge/. A garantia do PR único reviewAgents->master (item 2 da
# seção 3.3) fica sem checar nos ciclos vazios, mas isso é seguro: uma vez criado ele se mantém
# (nunca é fechado por esse fluxo), e volta a ser conferido no próximo ciclo que efetivamente rodar
# o claude. Ver seção "Pré-checagem em PowerShell antes de chamar claude -p" do CLAUDE.md.
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
Você é o Agent Master do Sup AutomaçãoUteis. Leia AGENTE.md nesta pasta e siga suas regras fixas à
risca — em especial (fluxo mudou em 2026-09-14, pedido explícito do Thiago, mesmo padrão do
SupE2eAutomation): você faz merge direto com push na reviewAgents de cada tarefa aprovada nos
testes, SEM PR nem aprovação humana por tarefa. Você NUNCA mergeia/dá push direto na master: o
único ponto de revisão manual do Thiago é um PR unico e continuo reviewAgents para master, que
voce garante que existe (cria uma vez se faltar, nunca recria) e que reflete sozinho no GitHub
cada commit novo pusheado na reviewAgents. gh CLI ja autenticado via GH_TOKEN. Execute agora UM
unico ciclo da logica operacional:

1. Leia ../docs/conhecimento-geral.md (raiz do Supervisor) inteiro, depois docs/documentacao.md
   inteiro.
2. Garanta o PR unico: rode gh pr list --base master --head reviewAgents --state open. Se nao
   existir nenhum aberto, crie um com gh pr create (base master, head reviewAgents, titulo curto
   tipo Integracao continua reviewAgents para master, corpo com um resumo do que esta pendente de
   revisao). Se ja existir, nao mexa nele.
3. Legado: se houver algo em fila-merge/aguardando-aprovacao/ (resquicio do modelo antigo de PR
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
4. Para cada aviso em fila-merge/pendentes/ (fluxo normal, novo): no repo/, busque a branch e faça
   um merge de teste LOCAL contra reviewAgents para achar conflito; se houver, resolva com a skill
   /resolve-conflicts e comite a resolução na própria branch da feature antes de mesclar de
   verdade. Atualize repo/.env se necessário (mesma lógica de sempre, nunca invente/deixe em
   branco). Rode os testes relevantes (npm run test:safety sempre; cenário/tag Cucumber da tarefa
   via npx cypress run --env tags=<tag> quando aplicável) contra a branch mesclada
   preventivamente. Se passar: finalize o merge de verdade e de push direto na reviewAgents (sem
   PR, sem esperar aprovacao), mova o aviso de fila-merge/pendentes/ direto para
   fila-merge/concluidos/ (nunca passa por aguardando-aprovacao/ nesse fluxo). Se falhar/não
   resolver conflito: trate como dúvida bloqueante, desfaça o merge local (não deixe a
   reviewAgents local suja), deixe o aviso em fila-merge/pendentes/.
5. Depois de processar os avisos, sincronize C:\multiplica\cypress-uteis (pasta PESSOAL do Thiago
   — reaproveitada por decisão dele mesmo, pode ter mudanças não commitadas) sempre para a
   reviewAgents (não há mais branch de PR-por-tarefa pra testar antes de aprovar), rode npm
   install --legacy-peer-deps se necessário (nunca npm ci, o repo nao versiona
   package-lock.json). Em qualquer caso, copie repo/.env por cima do .env dessa pasta. Nunca
   exponha conteúdo de .env/token em docs/documentacao.md, duvidas.md ou no log de saída — só
   confirme que foi sincronizado. Se o pull/checkout falhar (working tree suja, divergência), não
   force nada: registre em duvidas.md.
6. Registre em docs/documentacao.md tudo que foi feito (merges feitos direto na reviewAgents,
   conflitos resolvidos, variáveis de .env novas só o nome, estado do PR único pra master, e
   estado da sincronização da pasta de teste manual). Se o aprendizado valer para qualquer módulo,
   registre também em ../docs/conhecimento-geral.md (releia antes de escrever).
7. Nunca responda sua própria dúvida.
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
