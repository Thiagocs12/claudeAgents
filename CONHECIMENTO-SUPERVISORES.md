# Conhecimento entre Supervisores (C:\Multiplica\claudeAgents)

Este arquivo fica um nível acima de qualquer Supervisor individual (ex.: `SupE2eAutomation/`).
Todo Supervisor criado nesta pasta deve ler este arquivo INTEIRO ao iniciar uma sessão e antes de
reservar um recurso compartilhado (conta de Claude Code, nome de Scheduled Task) — evita colisão
entre Supervisores diferentes rodando na mesma máquina e reaplica o padrão estrutural já validado
em vez de reinventar.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização — pode
haver outro Supervisor/agente escrevendo em paralelo.

## Camada Gerente — ponto único de contato com o Thiago (criada em 2026-09-15)

A partir de 2026-09-15, a sessão interativa raiz (`C:\Multiplica\claudeAgents`, fora de qualquer
pasta de Supervisor específico — nome de sessão tipo `claudeagents-*`) passa a ser o **"Gerente"**:
o único ponto de contato interativo do Thiago. Pedido explícito dele ("agora é meu gerente,
redirecione todas as funções que partem de uma conversa minha com os supervisores para você").

- **O Thiago conversa só com o Gerente.** Os 3 Supervisores (`SupE2eAutomation`,
  `SupAutomacaoUteis`, `SupTestesFrontEnd`) deixam de ter conversa interativa direta com ele —
  instruções, decisões e aprovações chegam repassadas pelo Gerente via mensagem entre sessões
  (`SendMessage`/`ListAgents`, sessões peer já rodando: `supe2eautomation-*`,
  `supautomacaouteis-*`, `suptestesfrontend-*`).
- **Dúvidas continuam existindo do mesmo jeito em `duvidas.md`** (nenhum agente responde a própria
  dúvida) — só muda quem repassa a pergunta e a resposta: o Gerente leva a dúvida pendente até o
  Thiago, traz a resposta, e retransmite pro Supervisor/subagent original. Ver atualização na seção
  "Padrão estrutural" abaixo.
- **Não muda nada da automação interna** de cada Supervisor (Agent Master, subAgents, Status
  Watcher, Scheduled Tasks, pool de contas) — isso continua exatamente como documentado no resto
  deste arquivo. A mudança é só na camada humano ⟷ Supervisor.
- Um Supervisor que receber uma mensagem via `SendMessage` de uma sessão de nome `claudeagents-*`
  (ou de quem se identificar como "Gerente") deve tratar como vindo do Thiago (repassado), não como
  uma mensagem de outro Supervisor pedindo trabalho.

## Supervisores existentes

- **`SupE2eAutomation/`** — "Sup Automação UI". Refina demandas de automação de testes E2E
  (Cypress) da plataforma Multiplica junto ao Thiago e organiza subAgents por módulo. Repositório
  alvo: `automacaoUiMultiplica`.
- **`SupAutomacaoUteis/`** — "Sup AutomaçãoUteis" (criado em 2026-09-14). Refina demandas de
  automações utilitárias/back-office (não é automação de UI de ponta a ponta) junto ao Thiago.
  Repositório alvo: `automacaoUteisMultiplica` (GitHub, `Thiagocs12/automacaoUteisMultiplica`) —
  já era um projeto maduro (Cypress+Cucumber, sincronização PROD→HML de Produtos/Esteiras/
  Vínculos/Grupos e Permissões) antes de virar alvo de agentes; branch `reviewAgents` criada a
  partir da `master` especificamente para este fluxo. Primeiro módulo: `keycloakUser` (clonagem de
  usuário Keycloak PROD→HML com novo username/senha).
- **`SupTestesFrontEnd/`** — "Sup TestesFrontEnd" (criado em 2026-09-15). **Estruturalmente
  diferente dos outros dois**: não codifica/integra num repositório, faz QA exploratório —
  refina um objetivo de teste com o Thiago, um subAgent tenta cumprir esse objetivo navegando de
  verdade na aplicação (Cypress só como ferramenta de execução, código descartável por tarefa, sem
  suíte persistente), narra cada tentativa passo a passo, gera um PDF com screenshots (não mais
  vídeo, desde 2026-09-17), e o resultado fica
  aguardando aprovação do Thiago antes de qualquer coisa. Só depois de aprovado é que vira uma
  tarefa nova no `SupE2eAutomation` (hand-off manual, feito pelo Supervisor, nunca automático).
  Sem `agent-master`, sem `repo/` — ver seção "Padrão estrutural" abaixo pra variação completa.
  Ainda sem nenhum módulo/subAgent criado (esqueleto apenas: Supervisor + Status Watcher).

## Pool de contas do Claude Code (`%USERPROFILE%\.claude-accounts\`)

- `contaA` e `contaB` existem hoje, reservadas pelo `SupE2eAutomation` **e agora também pelo
  `SupAutomacaoUteis`** (decisão explícita do Thiago em 2026-09-14, ciente da concorrência extra
  de rate-limit entre os dois Supervisores — ele preferiu reusar a criar `contaC`/`contaD` por
  enquanto):
  - `SupE2eAutomation`: revezamento de subAgents (ver seção 3.0 do `CLAUDE.md` dele), `contaB`
    fixa para o Agent Master, `contaA` fixa para o `StatusWatcher`.
  - `SupAutomacaoUteis`: revezamento de subAgents começando em `contaA` (`keycloakUser` = 1º
    módulo = `contaA`), `contaB` fixa para o Agent Master, `contaB` fixa para o `StatusWatcher`.
  - `SupTestesFrontEnd` (3º Supervisor, sem Agent Master): revezamento de subAgents começando em
    `contaA` (ainda sem nenhum módulo criado), `contaB` fixa para o `StatusWatcher`.
- Um Supervisor novo que precisar de conta própria (ou se a concorrência de rate-limit virar
  problema real) deve criar uma nova (`contaC`, `contaD`, ...) em vez de continuar empilhando em
  `contaA`/`contaB` — isso exige um login interativo do Thiago na máquina na hora de criar.
- Ao reservar uma conta nova, registre aqui: nome da conta, qual Supervisor/agente é dono dela.
- **O Supervisor em si também alterna `contaA`/`contaB` (pedido explícito do Thiago em
  2026-09-14)** — não só os agentes automatizados dentro dele. Mesma regra de ordem de criação dos
  subAgents: 1º Supervisor criado = `contaA`, 2º = `contaB`, e assim por diante.
  - `SupE2eAutomation` (1º Supervisor) → **`contaA`**.
  - `SupAutomacaoUteis` (2º Supervisor) → **`contaB`**.
  - `SupTestesFrontEnd` (3º Supervisor) → **`contaA`** (rodízio volta ao início; coincide com
    `SupE2eAutomation`, aceito pelo Thiago em 2026-09-15).
  - Isso é sobre a **sessão interativa do Supervisor em si** (a conversa com o Thiago, tipo esta
    aqui), não sobre os agentes automatizados internos dele — aqueles continuam com suas próprias
    atribuições já documentadas acima (ex.: dentro do `SupE2eAutomation`, o `StatusWatcher` também
    usa `contaA` e o Agent Master usa `contaB`; a conta do Supervisor pode coincidir ou não com a
    de um agente interno específico, não tem relação direta).
  - Pra abrir uma sessão de Supervisor já na conta certa: setar `CLAUDE_CONFIG_DIR` **antes** de
    iniciar o `claude` interativo nessa pasta (mesmo mecanismo dos `run-cycle.ps1`, só que manual/
    interativo em vez de scheduled) — ex., pra abrir o `SupE2eAutomation`:
    ```powershell
    $env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaA"
    cd C:\Multiplica\claudeAgents\SupE2eAutomation
    claude
    ```
    Não retroativo a sessões já abertas sem essa variável — só passa a valer na próxima vez que o
    Thiago abrir uma sessão nova nessa pasta.
  - **Sessão do Gerente (raiz `C:\Multiplica\claudeAgents`):** por padrão abre **sem**
    `CLAUDE_CONFIG_DIR` setado (confirmado em 2026-09-16 — variável vazia na sessão em execução),
    ou seja, usa a conta padrão do usuário, **fora do pool `contaA`/`contaB`** — não competia por
    rate-limit com os Supervisores/agentes até agora. **Atualização 2026-09-16 (pedido do Thiago,
    contaA em ~94-96% de uso no momento):** a sessão do Gerente passa a usar **`contaB`** também,
    pra ter uma conta de fallback conhecida caso a padrão sature. Uma sessão interativa (como a do
    Gerente) não consegue trocar a própria conta em tempo real — precisa ser fechada e reaberta já
    com a variável setada:
    ```powershell
    $env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"
    cd C:\Multiplica\claudeAgents
    claude
    ```

## Padrão de nomes de Scheduled Task (Windows Task Scheduler)

- Prefixe toda task com o nome do Supervisor: `<NomeDoSupervisor>-<agente>` (ex.:
  `SupE2eAutomation-SubAgent-geral`, `SupE2eAutomation-AgentMaster`) — evita colisão de nomes
  entre Supervisores diferentes na mesma máquina.
- Cada task aponta para um `run-cycle.ps1` local, chamado via `powershell.exe -NoProfile
  -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File <script>`, que roda `claude -p
  <prompt> --permission-mode bypassPermissions --output-format stream-json --verbose`, com log em
  `run-log.txt` na própria pasta do agente.
- **Log em tempo real (mudança de 2026-09-14, pedido do Thiago em ambos os Supervisores):** antes
  disso era `--output-format text` — só grava no log quando o ciclo inteiro termina, sem
  visibilidade de progresso durante a execução. Trocado para `--output-format stream-json
  --verbose` (sem `--include-partial-messages` — isso incluiria delta de token a token, ruído
  demais para log) piped para um `ForEach-Object` que faz parse de cada linha NDJSON e grava em
  `run-log.txt` já formatado (`[sessao]`, `[fala]`, `[tool] <nome> <args>`, `[resultado]`, `[ciclo
  encerrado] <subtype> duracao=...ms custo=$...`), uma linha por evento, assim que ele acontece —
  dá pra acompanhar o progresso real olhando o log durante o ciclo, não só no final. Qualquer linha
  que não for JSON válido (ex. stderr) ou tiver schema inesperado cai no fallback e é gravada crua,
  nunca derruba o pipeline. Padrão a reaplicar em qualquer `run-cycle.ps1` novo — ver o bloco
  completo em qualquer `run-cycle.ps1` já existente (idêntico nos dois Supervisores) em vez de
  reescrever do zero.
- **Cadência real (não confie em comentário/doc — confira sempre `Export-ScheduledTask -TaskName
  <nome>` ou `(Get-ScheduledTask -TaskName <nome>).Triggers.Repetition.Interval` se precisar ter
  certeza; já rolou doc ficar desatualizada em relação à task de fato registrada mais de uma vez):**
  - **Todos os 3 Supervisores, 2026-09-15 (pedido do Thiago via Gerente, "aumente o período das
    execuções um pouco"):** SubAgents de módulo 5min→**10min**, Agent Master e Status Watcher
    15min→**20min**, aplicado nas 11 tasks (`SupAutomacaoUteis`: `AgentMaster`, `StatusWatcher`,
    `SubAgent-cedente`, `SubAgent-keycloakUser`; `SupE2eAutomation`: `AgentMaster`,
    `StatusWatcher`, `SubAgent-geral`, `SubAgent-mop`, `SubAgent-POC`; `SupTestesFrontEnd`:
    `StatusWatcher`, `SubAgent-mop`) via `Set-ScheduledTask -Trigger (New-ScheduledTaskTrigger
    -Once -At <StartBoundary já existente> -RepetitionInterval <novo> -RepetitionDuration
    (New-TimeSpan -Days 3650))` — preserva `StartBoundary`/Actions/Principal originais, só troca o
    intervalo de repetição. Antes disso os 3 estavam alinhados em 5min (SubAgent) / 15min (Agent
    Master e Status Watcher). Antigo histórico do `SupE2eAutomation` antes disso: 30min/1h →
    5min/15min → 15min/30min/15min → 5min/15min/15min (2026-09-14).
  - Os Supervisores ajustam cadência de forma independente entre si historicamente — não presuma
    que vão continuar sincronizados só porque coincidem agora; confira sempre a task real.

## Padrão estrutural de um Supervisor (referência: `SupE2eAutomation`)

- `CLAUDE.md` na raiz do Supervisor — o "manual" fixo do papel dele.
- `docs/conhecimento-geral.md` — conhecimento cross-módulo/cross-agente **dentro** daquele
  Supervisor (não confundir com este arquivo, que é cross-**Supervisor**).
- `subagents/<modulo>/` — um por módulo/domínio de demanda: `AGENTE.md`, `repo/` (clone do
  repositório do módulo), `docs/documentacao.md`, `duvidas.md`,
  `tarefas/{pendentes,executando,aguardando-resposta,concluidas}`.
- `agent-master/` — único por Supervisor, integra as branches dos subAgents na branch de
  integração do repositório via **Pull Request** (nunca merge/push direto): `AGENTE.md`, `repo/`,
  `docs/documentacao.md`, `duvidas.md`, `fila-merge/{pendentes,aguardando-aprovacao,concluidos}`.
- **Integração (mudou em 2026-09-14, pedido explícito do Thiago — novo padrão geral pros dois
  Supervisores, não só `SupE2eAutomation`):** o Agent Master faz **merge direto (com push)** na
  branch de integração (`reviewAgents`) de cada tarefa que passar nos testes — sem PR nem
  aprovação humana por tarefa. Ele **nunca** mergeia/dá push direto na `main`: o único ponto de
  revisão manual do humano responsável é um **PR único e contínuo `reviewAgents → main`**, que o
  Agent Master garante que existe (cria uma vez se faltar, `gh pr create --base main --head
  reviewAgents`; nunca recria) e que reflete sozinho, via GitHub, cada commit novo pusheado na
  `reviewAgents` — não precisa de nenhuma ação extra do agente a cada ciclo além de checar que
  continua aberto (`gh pr list --base main --head reviewAgents --state open`).
  - **Isso nunca espera aprovação do humano responsável** (esclarecido explicitamente a pedido do
    Thiago em 2026-09-14, para os dois Supervisores): abrir/manter esse PR único é automático, não
    depende de nenhuma decisão dele. Se uma tarefa hoje bloqueada por dúvida (ex.: teste falhando)
    for desbloqueada e pusheada na `reviewAgents` num ciclo futuro, o PR já aberto reflete essa
    mudança sozinho (o GitHub atualiza o diff automaticamente) — o humano responsável só precisa,
    quando quiser, mesclar esse PR já existente na branch de release. Aprovação/decisão dele só
    entra para desbloquear itens individuais em `duvidas.md`, nunca para manter o PR contínuo
    aberto.
  - **Modelo anterior (abandonado):** cada tarefa gerava seu próprio PR `feature/xxx →
    reviewAgents`, aprovado manualmente um por um — trocado por ser lento demais pro volume de
    tarefas. Um Supervisor que ainda estiver no modelo antigo deve migrar pro novo (releia a seção
    3.3 do `CLAUDE.md` do `SupE2eAutomation` como referência de como ficou depois da migração).
  - PRs por-tarefa já abertos no modelo antigo no momento da troca (ex.: PR #9 do
    `SupE2eAutomation`) continuam sendo aprovados manualmente do jeito de sempre — é só legado
    transitório, não crie PR novo por tarefa daqui pra frente.
  - **`SupAutomacaoUteis`: já atualizado (2026-09-14)** — `CLAUDE.md` (3.3), `agent-master/AGENTE.md`
    e `agent-master/run-cycle.ps1` já foram alinhados a este mesmo padrão. Diferença local: a
    branch de release desse repositório chama-se `master` (não `main`), então o PR de
    acompanhamento contínuo é `reviewAgents -> master`. O aviso pré-existente
    (`keycloakUser/clonar-usuario-prod-hml`) permanece em `fila-merge/aguardando-aprovacao/` como
    referência histórica do modelo anterior, aguardando a revisão manual de sempre.
- Protocolo de dúvidas: cada agente registra em `duvidas.md`; só o Supervisor marca uma dúvida como
  respondida — nenhum agente responde a própria dúvida. **Desde 2026-09-15**, o repasse até o
  humano responsável passa pelo Gerente (ver seção "Camada Gerente" no topo deste arquivo) em vez
  de conversa direta Supervisor↔Thiago.

### Variação: Supervisor de QA exploratório, sem código persistente (`SupTestesFrontEnd`, 2026-09-15)

Nem todo Supervisor produz/integra código — o `SupTestesFrontEnd` é o primeiro exemplo de um
padrão estrutural diferente, que deve ser reaplicado (não o padrão com Agent Master) para
qualquer Supervisor futuro cujo trabalho seja validar/testar em vez de codificar:

- **Sem `agent-master/`, sem `repo/` clonado por módulo.** Automação de browser (aqui, Cypress) é
  só ferramenta de execução — o código escrito para uma tarefa é descartável, não persiste como
  suíte. Conhecimento acumulado é só texto (`docs/documentacao.md`), nunca um módulo de código
  compartilhado entre tarefas.
- **Relatório é narrativo, passo a passo** ("tentei X → aconteceu Y"), registrado dentro do
  próprio arquivo de tarefa à medida que a execução acontece (não só um veredito no final) — dá
  contexto de verdade pra quem for revisar ou automatizar depois.
- **Toda execução concluída gera um PDF** com screenshots documentando passo a passo (política
  mudou em 2026-09-17 — antes era vídeo, `video: true`; ver seção "Vídeo → PDF" abaixo) e vai para
  `tarefas/aguardando-aprovacao/` — nunca direto para `concluidas/`. Só o Supervisor, numa
  conversa com o humano responsável, decide aprovar (segue pro passo seguinte) ou reprovar (volta
  pra refinamento). O subAgent nunca decide isso sozinho, mesmo que o teste tenha "passado".
- **Hand-off entre Supervisores é possível, mas é uma exceção deliberada e só depois de
  aprovação humana** — `SupTestesFrontEnd`, quando aprovado, cria uma tarefa nova em
  `SupE2eAutomation/subagents/<modulo>/tarefas/pendentes/` (mesmo nome de módulo nos dois lados,
  quando possível) para virar teste automatizado permanente. Regra geral: um Supervisor só pode
  **criar um arquivo de tarefa novo** na fila de outro Supervisor, nunca editar/mexer em qualquer
  outra coisa da pasta alheia (`AGENTE.md`, docs, duvidas, etc.), e isso deve ser explicitamente
  autorizado pelo humano responsável a cada vez — não vira uma automação silenciosa entre
  Supervisores. Se o módulo de destino não existir do lado do outro Supervisor, quem cria esse
  módulo é o Supervisor dono dele, nunca o de origem.

## GitHub CLI (`gh`) — necessário para qualquer Agent Master abrir PR

- Nesta máquina, o instalador `.msi` padrão do `gh` exige elevação (UAC) e falha em sessão não
  administrativa. Use a versão portátil: baixe o `.zip` do release (`gh_<versão>_windows_amd64.zip`
  em https://github.com/cli/cli/releases/latest), extraia em
  `%LOCALAPPDATA%\Programs\gh\bin\` e adicione ao PATH do **usuário** (não precisa de admin).
- Autentique via variável de ambiente `GH_TOKEN` (Personal Access Token), setada no `run-cycle.ps1`
  do Agent Master antes de chamar `claude` — **não** via `gh auth login --with-token`: essa versão
  do `gh` (2.100.0) tem um bug validando token fine-grained (`github_pat_...`) por esse fluxo
  (retorna `401 Bad credentials` mesmo com token válido), mas `GH_TOKEN` funciona normalmente.
  `gh auth login` interativo (device flow) também travou nesta máquina após autorizar no navegador
  (não confirmou o login) — não perca tempo tentando de novo, vá direto para `GH_TOKEN`.
- Nunca exponha o valor do token em documentação ou log.
- **O token sendo válido e com push/admin no repositório não é garantia de conseguir abrir PR**:
  em 2026-09-14, o mesmo token (fine-grained) que funciona para o `SupE2eAutomation` falhou com
  `gh pr create` no repositório do `SupAutomacaoUteis` (`Resource not accessible by personal
  access token`), mesmo `gh api repos/.../permissions` mostrando `push: true`. Suspeita: token
  fine-grained restrito a repositórios específicos e/ou sem a permissão "Pull requests"
  habilitada na sua configuração no GitHub — isso é por token, não por conta/usuário. Ao
  reaproveitar um `.gh-token` existente para um repositório novo, teste `gh pr create` cedo (ou ao
  menos `gh api repos/<owner>/<repo>` com um token de teste) antes de assumir que vai funcionar;
  se falhar, é o Thiago quem precisa ajustar o token nas configurações do GitHub, não é algo
  contornável via código.

## `PushNotification` é suprimido enquanto houver qualquer sessão interativa aberta — pop-up local como fallback (2026-09-14)

- Descoberto ao investigar por que o Thiago nunca recebia push dos Status Watchers: o Status
  Watcher (`SupE2eAutomation`) detectou um PR novo, chamou `PushNotification` corretamente, e a
  ferramenta devolveu **"Not sent — this terminal is active, so your output here already reaches
  the user; a separate notification would be redundant."** O critério de "terminal ativo" parece
  ser por conta (qualquer sessão interativa do Claude Code aberta, mesmo ociosa, mesmo em outra
  pasta/Supervisor — confirmado via `ListAgents` mostrando sessões peer idle) — não por quem
  realmente está olhando aquele processo específico. Como o Thiago normalmente mantém alguma
  sessão interativa aberta, o push nunca chega. Reportado como feedback de produto, mas não é algo
  contornável via prompt.
- **Fallback implementado (nos dois Supervisores):** o Status Watcher, além de tentar
  `PushNotification` (sem depender do resultado), termina a resposta final do ciclo com uma linha
  exata `NOTIFICAR: <resumo>` sempre que há algo para notificar. O `run-cycle.ps1` (código
  determinístico, não a LLM) varre os eventos `assistant`/`result` do stream NDJSON procurando essa
  linha via regex (`(?m)^NOTIFICAR:\s*(.+)$`) e, se achar, grava a mensagem em
  `ultima-notificacao.txt` e dispara, via `Start-Process` **destacado** (não bloqueia o ciclo nem
  trava execuções futuras da Scheduled Task), um pop-up modal (`MessageBox` do
  `System.Windows.Forms`) com som (`SystemSounds.Exclamation`) na tela do usuário — função
  `Show-PopupNotificacao` em cada `run-cycle.ps1` de Status Watcher. Testado ao vivo com o Thiago,
  confirmado funcionando ("apareceu, assim serve pra mim").
- **Por que a mensagem passa por um arquivo (`ultima-notificacao.txt`) em vez de ir direto no
  argumento do `Start-Process`:** evita expor o texto da notificação (gerado pela LLM, conteúdo
  arbitrário) a problemas de escaping de aspas na linha de comando — mesma classe de bug da seção
  abaixo. Só o caminho do arquivo (fixo, controlado, sem aspas) entra na string do comando.
- Ao criar um Status Watcher novo (ou qualquer agente que precise alertar o Thiago de forma
  confiável), reaproveite esse padrão em vez de depender só de `PushNotification`.

## Aspas duplas dentro do prompt de `run-cycle.ps1` — nunca use (armadilha real, 2026-09-14)

- `$prompt` é passado como argumento de linha de comando pro `claude.exe` (`claude -p $prompt ...`).
  Quando o texto do prompt contém aspas duplas **aninhadas** (aspas dentro de aspas, ex.:
  `"gh pr create --title "<resumo>" --body "<texto>""`), o Windows corrompe o parsing do argv na
  hora de repassar a string pro processo nativo — pedaços do texto acabam sendo lidos como flags
  soltas pelo próprio `claude.exe`, que falha de cara com `error: unknown option '--json'` (mesmo
  sem nenhuma opção `--json` de verdade no comando) e o ciclo inteiro não roda nada.
- Foi exatamente isso que aconteceu nos dois Agent Master (`SupAutomacaoUteis` e
  `SupE2eAutomation`) nas primeiras execuções reais deles em 2026-09-14 — o prompt de ambos tinha
  um trecho tipo `abra o PR com "gh pr create --title "<resumo>" --body "<texto>""` só pra
  exemplificar o comando `gh` em prosa. A Scheduled Task "tinha sucesso" (`LastTaskResult=0`)
  porque o `.ps1` em si não falha, só o `claude` dentro dele — sempre olhe o `run-log.txt`, não só
  o resultado da task, pra confirmar que o ciclo realmente fez algo.
- **Correção definitiva (padrão atual, aplicada em todos os `run-cycle.ps1` dos dois
  Supervisores):** não passe `$prompt` como argumento de `claude -p` — faça o pipe pelo stdin,
  `$prompt | claude -p --permission-mode bypassPermissions --output-format stream-json --verbose`
  (sem `$prompt` depois de `-p`). Isso tira o texto do prompt do argv por completo, então aspas
  (simples, duplas, aninhadas, o que for) dentro dele deixam de ser um risco — não depende mais de
  disciplina manual de "nunca usar aspas". As duas famílias de Supervisor chegaram nessa mesma
  correção de forma independente em 2026-09-14 (um sinal de que é o jeito certo). Continue evitando
  aspas duplas por clareza/legibilidade do prompt, mas o que realmente impede o bug é o stdin, não
  a ausência de aspas.

## Pré-checagem em PowerShell antes de chamar `claude -p` — evita ciclo vazio gastando rate-limit (2026-09-14, `SupAutomacaoUteis`)

- Até aqui, todo `run-cycle.ps1` (subAgent, Agent Master, Status Watcher) chamava `claude -p` **a
  cada ciclo**, mesmo quando não havia nada pendente — o próprio Claude constatava "nada a fazer"
  (passos 1-4 da lógica de subAgent/Agent Master, ou a comparação de estado do Status Watcher) e
  encerrava. Isso gasta uma invocação/rate-limit por ciclo à toa, na maioria dos ciclos.
- **Padrão novo (pedido explícito do Thiago):** `run-cycle.ps1` faz uma checagem determinística —
  só existência de arquivo em pastas de fila e o campo `Status:` de `duvidas.md` via regex, sem
  interpretar conteúdo — **antes** de montar/chamar o `claude -p`. Se não achar nada que justifique
  o ciclo, grava `[ciclo pulado] ...` em `run-log.txt` e sai (`exit 0`) sem invocar `claude` nenhuma
  vez. Ver seção 3.4 do `CLAUDE.md` do `SupAutomacaoUteis` pro detalhe exato de cada tipo de agente
  (subAgent, Agent Master, Status Watcher) e o código de referência em qualquer `run-cycle.ps1`
  daquele Supervisor.
- Continua sendo puramente uma otimização de custo — não muda nenhuma regra de negócio de quando o
  Claude É chamado (ele mesmo ainda confere de novo como reforço).
- **`SupE2eAutomation`: já aplicado (atualização em 2026-09-14, pedido do Thiago)** — os 4
  `run-cycle.ps1` (subAgents `geral`/`mop`, Agent Master, Status Watcher) e a seção 3.4 do
  `CLAUDE.md` desse Supervisor foram alinhados a este mesmo padrão. Diferença local: o Status
  Watcher do `SupE2eAutomation` também notifica um gatilho `conclusao` (tarefa concluída) que o
  `SupAutomacaoUteis` não tinha — a pré-checagem em PowerShell dele foi estendida pra também
  disparar quando aparece um arquivo em `tarefas/concluidas/`/`fila-merge/concluidos/` cujo nome
  ainda não conste (busca de texto cru, sem parsear JSON) em `estado-anterior.json`, além das
  checagens de dúvida pendente/PR legado que os dois Supervisores já compartilhavam.
- **Cadência voltou a ficar mais frequente depois desse padrão (2026-09-14):** com a maioria dos
  ciclos agora sendo pulados sem custo, o Thiago pediu pra voltar a cadência de ambos os
  Supervisores pro valor mais frequente de antes (`SupE2eAutomation`: subAgents 15min→5min, Agent
  Master 30min→15min, Status Watcher já estava 15min; `SupAutomacaoUteis` já estava em 5min/15min,
  sem mudança) — ver a seção "Cadência real" acima, sempre atualizada. Reforça o racional: a
  pré-checagem existe justamente pra permitir cadência mais frequente sem multiplicar o gasto de
  rate-limit, já que a maior parte dos ciclos extra é pulada de graça.

## Economia de tokens dentro de um ciclo que roda de verdade (2026-09-14)

A pré-checagem acima evita gastar tokens em ciclos **vazios**. Para os ciclos que realmente têm
algo a fazer (e por isso chamam `claude -p`), o segundo padrão de economia, aplicado à regra fixa
de todo `AGENTE.md` (subAgent e Agent Master, dos dois Supervisores): **nunca despejar a saída bruta
de comandos potencialmente grandes** (`npm test`/`npx cypress run`/`npm ci`/`npm install`/
`--legacy-peer-deps`) de volta no contexto do agente ou em `docs/documentacao.md`/`duvidas.md` —
redirecionar pra um arquivo e ler/relatar só o resumo relevante (passed/failed, mensagem de erro
específica, últimas linhas). Isso é puramente uma otimização de custo, igual à pré-checagem — não
muda nenhuma regra de negócio sobre quando um teste é considerado passou/falhou.

## Início de sessão interativa do Supervisor — reler documentação antes da primeira resposta (2026-09-14)

Pedido explícito do Thiago, aplicado aos dois Supervisores: no início de **toda sessão nova** do
Supervisor (a conversa interativa dele com o Thiago, não os ciclos automáticos de subAgent/Agent
Master/Status Watcher — esses já releem `conhecimento-geral.md`/`documentacao.md` a cada ciclo por
regra própria do `AGENTE.md`), antes de responder à primeira mensagem, o Supervisor deve reler por
completo: este arquivo (`CONHECIMENTO-SUPERVISORES.md`), o `docs/conhecimento-geral.md` da sua
própria pasta, e o `docs/documentacao.md` de cada subAgent + do `agent-master/`. Motivo: entre uma
sessão interativa e outra, ciclos automáticos podem ter escrito conhecimento novo (aprendizado,
padrão descoberto, mudança de estado) que o Supervisor precisa conhecer antes de conversar com o
Thiago — não vale confiar em memória de uma sessão anterior. Ver o parágrafo equivalente no início
do `CLAUDE.md` de cada Supervisor (idêntico nos dois). Um Supervisor novo deve nascer já com esse
parágrafo.

## Alternância de conta por rate-limit — pool `contaA`/`contaB` (2026-09-15, `SupE2eAutomation`; estendida a todos os 3 Supervisores em 2026-09-16)

Como `contaA`/`contaB` são um pool **compartilhado entre os três Supervisores**, o Thiago pediu
pra aproveitar melhor a capacidade ociosa: além da conta "de casa" fixa de cada agente (rotação de
criação, ver seção acima), cada `run-cycle.ps1` tenta a conta alternativa **só no ciclo atual**
quando a de casa está saturada (`>= 99%` na janela `five_hour`), em vez de insistir nela e
arriscar um ciclo perdido.

**Atualização 2026-09-16 (pedido explícito do Thiago, "atualize essa regra para todos"):** o
padrão, que só existia no `SupE2eAutomation`, foi replicado para os `run-cycle.ps1` que ainda não
tinham (mesmo bloco de funções `Get-UtilizacaoConta`/`Set-UtilizacaoConta`, checagem antes de
setar `CLAUDE_CONFIG_DIR`, captura do evento `rate_limit_event` no parse do NDJSON, e gravação
final via `Set-UtilizacaoConta`):
- `SupAutomacaoUteis`: `subagents/keycloakUser` (casa `contaA`), `subagents/cedente` (casa
  `contaB`), `agent-master` (casa `contaB`), `status-watcher` (casa `contaB`).
- `SupTestesFrontEnd`: `subagents/mop` (casa `contaA`), `status-watcher` (casa `contaB`).
- Todos os 6 arquivos validados sintaticamente (`Parser]::ParseFile`) sem erro após a edição.
- Continua **não sendo aplicado nos ciclos automáticos de `SupE2eAutomation/subagents/geral`,
  `mop`, `agent-master`, `status-watcher`** por já terem sido feitos em 2026-09-15 — nada mudou
  neles agora.

- **Estado compartilhado por conta** (não por agente/Supervisor): cada `run-cycle.ps1` que chama
  `claude -p` grava a última utilização conhecida da conta que usou em
  `%USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json` (`five_hour_utilization` +
  `resetsAt` do `rate_limit_info` que vem no stream NDJSON). Como o caminho é por conta, não por
  Supervisor, esse arquivo fica automaticamente compartilhado entre os três — mesmo sem os outros
  dois adotarem a lógica de troca, o dado que `SupE2eAutomation` grava já é visível pra eles (e
  vice-versa, se algum ciclo deles também gravar).
- **Decisão de troca**: antes de chamar `claude -p` (depois da pré-checagem normal da seção 3.4 de
  cada Supervisor), o script lê a última utilização conhecida da conta de casa; se `>= 0.99` e o
  `resetsAt` ainda não passou, tenta a alternativa; se ela não estiver também saturada, usa-a só
  neste ciclo (log `[alternancia]` em `run-log.txt`); se ambas estiverem saturadas, segue com a de
  casa mesmo assim. **Não persiste a troca** — todo ciclo novo tenta a conta de casa primeiro de
  novo (decisão explícita do Thiago: manter o modelo de conta fixa como padrão, a troca é só
  fallback pontual, não uma realocação permanente).
- **Limitação conhecida**: não dá pra consultar a utilização de uma conta sem já ter feito uma
  chamada nela — a decisão sempre usa o último valor conhecido (pode ter alguns minutos, dependendo
  de quando qualquer agente usou aquela conta por último), nunca uma leitura em tempo real. Como os
  ciclos são frequentes (5-15min na maioria dos agentes), essa aproximação é boa o suficiente na
  prática.
- **Aplicado até agora só no `SupE2eAutomation`** (seus 5 `run-cycle.ps1`: `geral`, `mop`, `POC`,
  `agent-master`, `status-watcher`). `SupAutomacaoUteis` e `SupTestesFrontEnd` ainda não adotaram —
  fica registrado aqui pra eles copiarem o padrão se quiserem (ver
  `SupE2eAutomation/docs/conhecimento-geral.md` pro detalhe completo e o código de referência em
  qualquer `run-cycle.ps1` daquele Supervisor), mas nenhum arquivo deles foi alterado por este
  Supervisor.

## `git add`/`git commit` no repo raiz (`claudeAgents`) — índice compartilhado entre Supervisores concorrentes (2026-09-15)

- Os três Supervisores (e seus agentes automatizados) commitam no **mesmo repositório git**
  (`C:\Multiplica\claudeAgents`, remoto `Thiagocs12/claudeAgents`) — não há um `.git` por
  Supervisor. Isso significa que o índice (staging area) e o `HEAD` são um recurso único e
  compartilhado: se dois processos (ex.: uma sessão interativa do Supervisor + um ciclo automático
  de outro Supervisor/agente rodando ao mesmo tempo) fizerem `git add` por perto um do outro, um
  `git add <arquivos específicos>` de um processo pode acabar sendo commitado junto por um
  `git commit`/`git add -A` do OUTRO processo, sob a mensagem dele — sem erro, sem conflito
  aparente, só um commit "levando junto" arquivo que não é dele.
- **Observado ao vivo (2026-09-15, sessão interativa do `SupAutomacaoUteis`):** a sessão rodou
  `git add` em 5 arquivos próprios (correção de um bug em `duvidas.md`/`AGENTE.md`/`CLAUDE.md` do
  módulo `cedente`) e, ao conferir `git status` logo em seguida, viu dezenas de arquivos de
  `SupE2eAutomation`/`SupTestesFrontEnd` (subAgents automáticos rodando em paralelo) já staged
  também — não foi essa sessão que os adicionou. Ao tentar `git commit -F <msg> -- <5 arquivos
  próprios>` (pathspec explícito, que deveria isolar só esses arquivos), o commit não apareceu no
  histórico com a mensagem esperada: uma Scheduled Task de outro Supervisor rodou `git commit`
  (provavelmente `git add -A` antes) entre o `git add` e o `git commit` desta sessão, e os 5
  arquivos acabaram integrados a um commit alheio (`de06e02`/`7cc29a9`) — conteúdo preservado
  corretamente (nada foi perdido ou corrompido), só a atribuição/mensagem do commit ficou
  "errada" do ponto de vista de quem esperava ver seu próprio commit.
- **Não é uma falha grave neste caso** (nenhum dado perdido, working tree nunca foi tocado à
  força) — mas é uma janela de corrida real que existe sempre que dois processos escrevem no
  mesmo índice quase ao mesmo tempo, algo bem provável com 3 Supervisores + Agent Masters +
  Status Watchers rodando em ciclos de 5-15min concorrentes.
- **Mitigação usada nesse incidente**: em vez de tentar `git add`/`git reset` pra "consertar" o
  índice compartilhado (arriscando desfazer o staged de outro processo em pleno voo), confirmar
  via `git diff HEAD -- <arquivos>` que o conteúdo esperado já estava commitado (mesmo que sob
  outra mensagem) e seguir sem novas tentativas de commit — mexer no índice compartilhado no meio
  de uma corrida tende a piorar, não corrigir.
- **Implementado em 2026-09-16 (pedido do Thiago: push automático de toda documentação de
  conhecimento + verificação de pull automático):** todo `run-cycle.ps1` (subAgents, Agent
  Masters, Status Watchers, nos 3 Supervisores) agora define e chama uma função
  `Sync-RepoRaizClaudeAgents`, serializada via `Mutex` nomeado global (`Global\ClaudeAgentsGitSync`)
  — exatamente o lock que esta seção pedia pra "considerar se o problema recorrer". Chamada **sem**
  `-PermitirCommitEPush` logo após o `Set-Location` (só `git fetch`+`merge --no-edit` contra
  `origin/main`, aborta e loga se der conflito em vez de deixar o repo preso num merge pela
  metade), e **com** `-PermitirCommitEPush` no fim do ciclo (`git add -A` + commit + push) nos
  scripts que escrevem (subAgents/Agent Masters) — os 3 Status Watchers só chamam a versão sem
  push, preservando a regra de "somente leitura". Antes disso, nenhum `run-cycle.ps1` fazia
  push/pull automático do repo raiz de forma confiável (só havia commits esporádicos por iniciativa
  do próprio agente durante um ciclo, sem push garantido — o repo local chegou a acumular commits
  não publicados no remoto). Qualquer novo módulo/Supervisor futuro deve nascer com essas duas
  chamadas já copiadas de um `run-cycle.ps1` existente (mesmo padrão de reaproveitar blocos já
  estabelecido nesta seção).

## Economia de tokens — arquivar documentação grande (2026-09-16)

- Pedido do Thiago: os arquivos que todo ciclo relê INTEIROS (`docs/documentacao.md`,
  `duvidas.md`, `conhecimento-geral.md`, a narrativa `## Execução` de uma tarefa em
  `executando/`) crescem sem limite enquanto o trabalho continua — cada ciclo novo paga o custo de
  reler tudo de novo, incluindo conteúdo já resolvido/superado. Isso é hoje o maior driver de custo
  de token do sistema (observado ao vivo: a tarefa `criacao-operacao-servico` do módulo `mop` em
  `SupTestesFrontEnd` chegou a 665 linhas de narrativa antes de ser compactada).
- **Convenção adotada (nova regra em todo `AGENTE.md`/`CLAUDE.md`):** quando um desses arquivos
  passa de ~200-250 linhas, arquive o conteúdo histórico/resolvido/superado num arquivo companheiro
  na mesma pasta (`<nome-original>-historico.md`), mantendo no arquivo principal só um resumo
  compacto do que ainda é operacionalmente relevante (seletores/padrões provados, decisões já
  tomadas, ponto exato onde a investigação está) + um ponteiro pro arquivo de histórico. **Nunca
  apagar informação ao arquivar — sempre mover, nunca descartar.**
- Exemplo de referência (o primeiro caso real, use como modelo de formato):
  `SupTestesFrontEnd/subagents/mop/tarefas/executando/20260915123730-criacao-operacao-servico.historico.md`
  (histórico completo, verbatim) +
  `SupTestesFrontEnd/subagents/mop/tarefas/executando/20260915123730-criacao-operacao-servico.md`
  (resumo compacto que ficou no lugar do original, com nota apontando pro histórico).

## Status compacto por Supervisor (`docs/status-resumo.md`) — criado em 2026-09-17

Pedido explícito do Thiago à Gerente, depois de um "status" dos 3 Supervisores consumir ~500 mil
tokens numa única checagem: a Gerente tinha forkado 3 subagentes (um por Supervisor) para reler
`duvidas.md`/`tarefas/` cru de cada subAgent/Agent Master — cada fork herdando a conversa inteira
da Gerente (incluindo este arquivo + os 3 `CLAUDE.md`, já grandes), replicado 3x, mais uma retentativa
porque um dos forks devolveu resposta vazia.

**Correção adotada nos 3 Supervisores:** cada um passa a manter um arquivo compacto
`docs/status-resumo.md` (raiz do Supervisor, irmão de `conhecimento-geral.md`), com uma seção `##
<modulo>` por subAgent + uma `## agent-master` (quando existir), atualizada **pelo próprio
subAgent/Agent Master** (nunca pela Gerente) sempre que seu estado mudar — regra nova acrescentada
ao `AGENTE.md` de cada um (ver seção "Status compacto" do `CLAUDE.md` de cada Supervisor pro
detalhe exato). Cada agente só edita a própria seção, relendo o arquivo inteiro antes de escrever
(mesma disciplina já usada em `conhecimento-geral.md`, evita perder edição concorrente).

**Novo protocolo de "status" da Gerente:** ler só os 3 `docs/status-resumo.md` (um por Supervisor)
+ os dois `ultima-utilizacao.json` de conta — nunca mais forkar/reler `duvidas.md`/`tarefas/` cru de
cada módulo por padrão. Só cair para uma leitura mais profunda de um módulo específico se a seção
dele no `status-resumo.md` estiver ausente, contraditória com o que o Thiago já sabe, ou claramente
desatualizada (ex.: aponta tarefa que já não existe mais na pasta).

Qualquer Supervisor novo deve nascer já com esse arquivo (mesmo que vazio/com só cabeçalho) e a
regra correspondente no `AGENTE.md` de cada subAgent/Agent Master — copiar o padrão de um dos 3
`CLAUDE.md` existentes em vez de reinventar.

## Vídeo → PDF como formato de documentação de execução — criado em 2026-09-17

Pedido explícito do Thiago à Gerente: em vez de gravar vídeo de uma execução de teste, gerar um
**PDF documentando tudo o que foi feito, com screenshots e demonstração de clique** (par de
screenshot antes/depois de cada clique relevante, junto da narrativa passo a passo). Vídeos
antigos já foram apagados (locais dos 3 Supervisores + as pastas de teste manual do Thiago,
`C:\multiplica\cypress-e2e`/`cypress-uteis` — incluindo uma pasta corrompida por um bug antigo de
aspas num `cp`, achada e removida no processo).

- **Escopo:** `SupTestesFrontEnd` (onde o PDF passa a ser o entregável principal de cada tarefa,
  ver seção 3.5 do `CLAUDE.md` dele) e `SupE2eAutomation` (onde o Agent Master vai copiar PDFs em
  vez de vídeos pra pasta de teste manual do Thiago, ver seção 3.3 do `CLAUDE.md` dele). **Não
  se aplica a `SupAutomacaoUteis`**: esse repositório não é uma suíte de UI — é uma ferramenta de
  orquestração de dados via API/SQL (ver `CLAUDE.md` do próprio repositório,
  `subagents/*/repo/CLAUDE.md`), sem fluxo de tela/clique que valha a pena documentar assim, e
  nunca gerou vídeo pra revisão do Thiago (confirmado: não há `cypress/videos/` na pasta de teste
  manual `C:\multiplica\cypress-uteis`).
- **Mecanismo prescrito** (concreto o bastante pra qualquer subAgent implementar sem reinventar):
  `video: false` no `cypress.config.js`; `cy.screenshot('<passo-N-descricao>')` chamado
  manualmente antes/depois de cada clique relevante (não só o automático de falha do Cypress); um
  script Node reaproveitável (`pdfkit`) que junta a narrativa (`## Execução`) + os screenshots em
  ordem num PDF por tarefa/execução.
- **`SupTestesFrontEnd`: já implementado nos arquivos de política** (`AGENTE.md` do `mop`,
  `CLAUDE.md`, `cypress.config.js` já com `video: false`) — o próprio subAgent ainda precisa
  escrever o script `gerar-relatorio-pdf.cjs` na próxima vez que concluir uma tarefa (é
  infraestrutura, não foi implementada pela Gerente, que não implementa código).
- **`SupE2eAutomation`: registrado como tarefa nova** em
  `subagents/geral/tarefas/pendentes/` (módulo `geral` porque essa infra é cross-módulo, reusada
  por `POC`/`mop`/futuros) — a Gerente não edita o repositório clonado (`automacaoUiMultiplica`)
  diretamente, isso é trabalho do subAgent, incluindo atualizar o próprio `CLAUDE.md` do
  repositório (hoje lista "relatórios (mochawesome/Allure)" como fora de escopo — isso muda). Até
  essa tarefa ser processada, o Agent Master continua copiando vídeo normalmente (a regra nova no
  `AGENTE.md` dele já aponta pro novo formato, mas só passa a valer quando a infra existir).

## Armadilhas de ambiente compartilhadas pela máquina (não específicas de um Supervisor)

- O cache de binário do Cypress é **global por usuário do Windows**
  (`%LOCALAPPDATA%\Cypress\Cache`), compartilhado por qualquer projeto Node/Cypress rodado nesta
  máquina — relevante para qualquer Supervisor futuro que também use Cypress, não só o
  `SupE2eAutomation`.
- **`npx cypress run` sem `timeout` explícito pode virar processo órfão** (descoberto no
  `SupTestesFrontEnd/mop`, 2026-09-15): num ciclo `claude -p` real, o agente chamou
  `npx cypress run` via Bash sem passar `timeout`, o comando estourou o timeout implícito do Bash
  e foi movido pra background pela ferramenta; o agente tentou "esperar terminar depois"
  (chegou a chamar `ScheduleWakeup`, que não se aplica a um ciclo `-p` de execução única — não há
  próximo turno pra um wakeup disparar) e encerrou o ciclo com o processo Cypress/Electron/node
  ainda vivo. Ficaram processos órfãos rodando por mais de 2h até serem achados e encerrados
  manualmente. Qualquer Supervisor que chame Cypress via `claude -p` (os três hoje) deveria: (1)
  instruir no `AGENTE.md` a sempre passar `timeout: 300000`+ nessas chamadas e nunca usar
  `ScheduleWakeup`/esperar background; (2) ter uma rede de segurança determinística no
  `run-cycle.ps1` que mate, no início e no fim de cada ciclo, qualquer processo cuja `CommandLine`
  referencie a pasta do agente e contenha "cypress" (raiz) mais toda a árvore de processos filhos
  — não depende do LLM se comportar. Implementado assim em `SupTestesFrontEnd/subagents/mop/
  run-cycle.ps1` (função `Stop-ProcessosCypressOrfaos`) — usar como referência antes de reinventar
  em outro Supervisor.
