# Conhecimento geral do sistema (leitura obrigatória para todo agente)

Conteúdo histórico/resolvido/superado arquivado em `conhecimento-geral-historico.md` (mesma pasta).

Este arquivo reúne aprendizados e convenções que atravessam módulos — todo subAgent e o Agent
Master devem ler este arquivo INTEIRO antes de iniciar qualquer ciclo, além do
`docs/documentacao.md` do próprio módulo. Se você (agente) aprender algo que outro módulo também
precisaria saber, registre aqui — não só no seu `docs/documentacao.md` local.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização, para não
perder uma edição feita por outro agente rodando em paralelo (não há lock automático entre
ciclos).

## Segurança — nunca ecoe GH_TOKEN (ou qualquer secret) em comando de diagnóstico

- **Nunca rode um comando que possa imprimir `$env:GH_TOKEN` (ou qualquer variável de
  credencial) por inteiro** — nem para depurar. Se precisar confirmar que a variável está setada,
  cheque só o comprimento/prefixo (`$env:GH_TOKEN.Length`, `$env:GH_TOKEN.Substring(0,4)`), nunca
  o valor completo.
- Se acontecer de novo (qualquer secret vazar em `run-log.txt`, `docs/documentacao.md`, ou
  qualquer arquivo lido por outro agente/Supervisor): registre dúvida bloqueante imediatamente
  (não tente redigir/apagar sozinho — isso é decisão do Supervisor/Thiago) e não repita o comando
  que causou o vazamento tentando "corrigir" — pare e espere resposta.
- Motivo da regra: incidente real de vazamento de `GH_TOKEN` em `run-log.txt` — narrativa completa
  em `conhecimento-geral-historico.md`.

## Convenções do repositório do projeto (automacaoUiMultiplica)

- Branch de integração: **`reviewAgents`** (nunca `reviewAgent`, no singular). `main` só recebe
  merge de `reviewAgents` em momentos de release — nunca commit/merge direto.
- O padrão de arquitetura do projeto está documentado no `README.md` e `CLAUDE.md` **do próprio
  repositório clonado** (não confundir com o `CLAUDE.md`/`docs/` do Supervisor, que é sobre como
  os agentes se organizam, não sobre a automação de UI em si).
- **Fluxo de integração vigente:** o Agent Master faz merge direto (com push) de cada tarefa
  aprovada nos testes **na `reviewAgents`** — sem PR nem aprovação humana por tarefa. Ele **nunca**
  mergeia/dá push direto na `main`: o único ponto de revisão manual do Thiago é um **PR único e
  contínuo `reviewAgents → main`**, que reflete sozinho no GitHub cada commit novo pusheado na
  `reviewAgents` — o Agent Master só garante que ele existe a cada ciclo (`gh pr list`/
  `gh pr create` se faltar), nunca recria. **O número do PR muda** toda vez que o anterior é
  mergeado pelo Thiago sem commit novo pendente (`gh pr create` falha com "No commits between main
  and reviewAgents" nesse caso — normal) — não hardcode o número; confira sempre com `gh pr list`.
  `fila-merge/aguardando-aprovacao/` do Agent Master é resquício de um modelo antigo (PR por
  tarefa, aprovado manualmente um a um) abandonado por ser lento demais para o volume de tarefas —
  só processa avisos legados que já tinham PR aberto na troca de fluxo; nenhum aviso novo passa por
  ali. Histórico completo (números de PR específicos, datas da mudança) em
  `conhecimento-geral-historico.md`.
- Arquitetura alvo: camadas Pages / Etapas / Esteiras, com Cucumber como camada fina de
  legibilidade sobre as Esteiras (não orquestra nada sozinho).

## Contas de Claude Code por agente

- Cada subAgent/Agent Master roda um `claude -p` fixado numa conta própria via
  `CLAUDE_CONFIG_DIR` (pastas em `%USERPROFILE%\.claude-accounts\<conta>`), setada no início do
  `run-cycle.ps1` antes do `claude` iniciar.
- **`contaB` é a conta padrão de tudo** (Agent Master, todo subAgent, Status Watcher) — desde
  2026-09-17, pedido explícito do Thiago (`contaB` é a conta pessoal dele). `contaA` só entra como
  fallback de rate-limit (ver seção 3.0 do `CLAUDE.md` do Supervisor e
  `CONHECIMENTO-SUPERVISORES.md`). Modelo anterior (revezamento por ordem de criação) é histórico,
  não usar mais como referência de "casa" atual.

## Alternância de conta por rate-limit (pedido do Thiago, 2026-09-15)

Cada agente (subAgent, Agent Master, Status Watcher) tem uma conta "de casa" fixa (ver
atribuições acima) — mas além disso, todo `run-cycle.ps1` deste Supervisor tenta usar a conta
alternativa **só no ciclo atual** quando a conta de casa está saturada, para não desperdiçar
capacidade ociosa da outra conta.

- **Como funciona:** logo após um ciclo que efetivamente chama `claude -p`, o script grava a
  última utilização conhecida da conta usada (janela `five_hour` do `rate_limit_info` que vem no
  stream NDJSON) em `%USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json` (funções
  `Set-UtilizacaoConta`/`Get-UtilizacaoConta` em cada `run-cycle.ps1`). Esse arquivo é um estado
  **por conta**, compartilhado entre qualquer agente/Supervisor que use aquela conta (pool
  `contaA`/`contaB` é cross-Supervisor — ver `CONHECIMENTO-SUPERVISORES.md`).
- **Antes de chamar `claude -p`** (depois da pré-checagem normal da seção 3.4), o script lê a
  última utilização conhecida da sua conta de casa. Se for `>= 0.99` (99%) na janela `five_hour`
  **e** o `resetsAt` gravado ainda não tiver passado, tenta a conta alternativa: se ela não estiver
  também `>= 0.99`, usa a alternativa **só neste ciclo**; se as duas estiverem saturadas, segue com
  a conta de casa mesmo assim. Registra a decisão em `run-log.txt` com a tag `[alternancia]`.
- **Não persiste a troca**: no próximo ciclo, o agente sempre tenta a conta de casa primeiro de
  novo — a troca é só um fallback pontual, não uma reatribuição permanente.
- **Limitação conhecida**: não existe forma de consultar a utilização de uma conta sem já ter
  feito uma chamada `claude -p` nela — o valor usado na decisão é sempre o último conhecido (de
  até ~5-30min atrás), não uma leitura em tempo real.
- Aplicado nos 5 `run-cycle.ps1` deste Supervisor (`geral`, `mop`, `POC`, `agent-master`,
  `status-watcher`) em 2026-09-15. Os outros Supervisores (`SupAutomacaoUteis`,
  `SupTestesFrontEnd`) ainda não adotaram esse padrão.

## `.env` / variáveis de ambiente — quem cuida do quê

- O Agent Master mantém `agent-master/repo/.env` atualizado automaticamente: a cada merge, compara
  `.env.example` antes/depois para achar variáveis novas e busca o valor em
  `subagents/<modulo>/docs/documentacao.md` e/ou na tarefa concluída correspondente. Nunca inventa
  nem deixa em branco — se não achar, vira dúvida bloqueante.
- O Agent Master sincroniza `C:\multiplica\cypress-e2e` (pasta de teste manual do Thiago, mesmo
  repositório em clone separado) a cada ciclo: `npm ci`/`npm install` se necessário, e copia
  `repo/.env` por cima do `.env` de lá. Essa pasta fica sempre na `reviewAgents` — o Thiago não
  precisa criar/manter esse `.env` na mão.
- **Nunca** exponha valores de variáveis de `.env` em `docs/documentacao.md`, `duvidas.md` ou em
  log de saída — só o nome da variável e de onde veio o valor.

## Armadilhas conhecidas de ambiente (Windows / Cypress)

- O cache de binário do Cypress é **global por usuário do Windows**
  (`%LOCALAPPDATA%\Cypress\Cache`), compartilhado entre **todos** os projetos da máquina — não é
  isolado por repositório. Rodar `npx cypress open`/`run` num projeto cujo `node_modules` ainda
  não tem o Cypress resolvido localmente pode disparar a instalação de uma versão diferente da
  pinada no `package.json`. Prefira versão **exata** (sem `^`) de `cypress` no `package.json`
  quando isso for um risco, e garanta que `npm ci`/`npm install` já rodou antes de qualquer
  `cypress open`/`run`.
- `cy.session`: o `setup`/`validate` só restaura cookies/localStorage — ao final, a página fica em
  `about:blank`. Sempre fazer um `cy.visit` adicional logo após o `cy.session` para que a asserção
  de "autenticado com sucesso" funcione (senão a URL fica em `about:blank` mesmo com sessão
  válida). Ver `cy.loginComoPerfil` em `commands.js` como referência já implementada.
- Widget de menu do Beyond (`mc-menu.js`, carregado de `beyond-hml.grupomultiplica.com.br`): ao
  clicar em "Beyond BackOffice" às vezes lança uma exceção não tratada própria
  (`Cannot read properties of undefined (reading 'content')`) que derruba o teste por padrão, sem
  afetar a navegação visual real. Corrigido globalmente em `cypress/support/e2e.js` com um handler
  `Cypress.on('uncaught:exception', ...)` que ignora especificamente essa mensagem (commit
  `a83b438`). Qualquer módulo que navegue por esse menu já herda a correção.
- **Inputs controlados por React (ex.: `input[type="date"]` do Monitor Diário do MOP) não reagem a
  `.val()`/`.type()` do jQuery/Cypress da forma ingênua** — setar o valor sem passar pelo setter
  nativo não dispara o `onChange` do React, então o componente não percebe a mudança. Solução:
  pegar o setter nativo do protótipo antes de disparar os eventos manualmente:
  ```js
  const nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set
  nativeSetter.call(input, novoValor)
  input.dispatchEvent(new Event('input', { bubbles: true }))
  input.dispatchEvent(new Event('change', { bubbles: true }))
  ```
  Útil para qualquer módulo que precise setar programaticamente um input controlado por React em
  vez de digitar caractere a caractere com `cy.type()`.

## Instabilidade de login/HML (`cy.origin`, Keycloak, rede) — catálogo de sintomas e estado da investigação (atualizado 2026-09-17)

Investigação em andamento há vários dias (módulos `mop`, `POC`, Agent Master), causa raiz **ainda
não confirmada**. Histórico completo (cada recorrência, data, hipóteses testadas e descartadas) em
`conhecimento-geral-historico.md` — aqui só o estado atual e o catálogo de sintomas.

- **Sintomas já catalogados, todos dentro/logo após `cy.loginComoPerfil`/`cy.session`** (registrar
  o sintoma exato sempre que reaparecer — não presumir que é sempre o mesmo problema):
  1. `CypressError: cy.origin() failed to create a spec bridge...` — o mais recorrente.
  2. `CypressError: Timed out after waiting 60000ms for your remote page to load`.
  3. `Error: connect ETIMEDOUT 10.101.10.254:443` — falha de rede ao IP **privado** de
     `beyond-hml.grupomultiplica.com.br`, **antes** de qualquer interação com Keycloak (indica
     VPN/rede interna instável/caída, não é sintoma de `cy.origin`). Confirmar com
     `curl --max-time 20 https://beyond-hml.grupomultiplica.com.br/`; se der timeout e
     `keycloak-new-2.grupomultiplica.com.br` responder normalmente (mesmo que `403`), é isso —
     `nslookup` mostra que `beyond-hml` resolve para IP privado enquanto `keycloak-new-2` resolve
     para IPs públicos (Cloudflare).
  4. `AssertionError: ... expected '...keycloak-new-2.../login-actions/authenticate...' to include
     'https://beyond-hml.grupomultiplica.com.br/'` — depois de submeter credenciais, a página não
     redireciona de volta pra `beyond-hml` (visto 2026-09-17, Agent Master).
  - Sintomas específicos de `mop/mop-monitor-diario.feature`, ocorrendo **depois** do login (não
    confundir com os 4 acima): `ResizeObserver loop completed with undelivered notifications`
    (**RESOLVIDO** — tratado como `uncaught:exception` conhecido em `cypress/support/e2e.js`,
    mesmo padrão do handler do widget de menu do Beyond, commit `a2f2d88`, já em `reviewAgents`);
    `cy.click() failed because this element is disabled` (botão `Mui-disabled`); `cy.click()
    failed because ... is being covered by ... menu-MuiBackdrop-root` (clique disparado antes do
    backdrop/transição do menu terminar). Esses três parecem timing/estado de UI da própria tela,
    não rede/Keycloak — ainda sem causa raiz confirmada.
- **Protocolo padrão ao encontrar qualquer sintoma acima:** não decidir sozinho, não insistir em
  múltiplas tentativas em sequência rápida; no máximo uma checagem (`curl`, para o sintoma de
  rede); registrar dúvida bloqueante descrevendo o sintoma **exato**.
- **Estado mais recente da investigação (2026-09-17):** a hipótese de que "`shared/login.feature`
  isolado é sempre confiável, só specs de outros módulos falham no mesmo ciclo" (que sugeriria algo
  específico de timing/ordem de spec, não do Keycloak/HML em si) foi **contradita no mesmo dia**:
  num ciclo do Agent Master, `login.feature` também falhou (sintoma 4 acima), junto com
  `mop-monitor-diario.feature` no mesmo ponto, na mesma execução. Ou seja: **nenhuma hipótese está
  confirmada como causa raiz até agora** — não usar "login.feature passou" como prova de que o
  problema é de outro spec/timing sem checar a data/hora deste registro. Instabilidade de
  rede/VPN (sintoma 3) é um fator real e distinto confirmado, mas não explica os sintomas 1/2/4.
- Dúvidas bloqueantes abertas com o histórico completo pergunta-a-resposta:
  `agent-master/duvidas.md` (`20260914125955-atualizar-claude-md-fluxo-integracao`,
  `20260917111432-migrar-video-para-relatorio-pdf`), `subagents/POC/duvidas.md`
  (`20260915131339-criar-prospect-cedente-cnpj`).

## Git — branch nova pode não aparecer sem `fetch`

- Um checkout local (`repo/` do Agent Master ou de um subAgent) pode não listar uma branch remota
  recém-criada em `git branch -a` até rodar `git fetch` (`--prune` para também limpar branches
  remotas apagadas). Sempre dar `git fetch` (ou `--prune`) antes de concluir que uma branch
  referenciada não existe.

## Tarefas que não cabem em um ciclo (retomada)

- Um ciclo de subAgent roda `claude -p` uma única vez; tarefas que exigem investigação ao vivo de
  tela (sem prints/spec prontos, ex.: descobrir seletores de uma tela nova) podem esgotar o ciclo
  antes de terminar. Se `executando/` já tiver uma tarefa, a regra é **retomar**, não encerrar o
  ciclo: procure uma branch já criada para aquela tarefa em `repo/` e continue de onde parou, em
  vez de ficar preso para sempre.
- Consequência prática: ao implementar algo que pode não caber num ciclo só, sempre faça commit do
  progresso parcial na branch antes do ciclo terminar — nunca deixe só em arquivos não commitados
  (o próximo ciclo não teria como saber o que já foi descoberto/feito).
- **Nunca inicie um processo em segundo plano (ex.: `cypress open`, `cypress run` em background) e
  encerre o ciclo "esperando ele terminar depois"** — isso trava a tarefa para sempre, porque o
  processo em segundo plano não sobrevive entre ciclos (cada ciclo é uma execução nova e isolada do
  `claude -p`). Qualquer comando de investigação/teste deve ser executado de forma síncrona
  (aguardar terminar) dentro do próprio ciclo. Se mesmo assim não der tempo de terminar a tarefa,
  faça commit do progresso parcial e pare — nunca apenas diga "continuo depois" sem persistir nada
  de concreto.

## GitHub CLI (`gh`) — usado pelo Agent Master para abrir PR

- Instalado como versão portátil em `%LOCALAPPDATA%\Programs\gh\bin\gh.exe` (sem precisar de
  admin/UAC — o instalador `.msi` padrão exige elevação e falha nesta máquina).
- Autenticado via variável de ambiente `GH_TOKEN` (não via `gh auth login` — essa versão do `gh`
  tem um bug validando token fine-grained (`github_pat_...`) nesse fluxo; `GH_TOKEN` funciona
  normalmente). O token está setado dentro de `agent-master/run-cycle.ps1` (acesso total aos
  repositórios, sem expiração) — nunca exponha esse valor em documentação/log (ver seção
  "Segurança" acima).
- Só o Agent Master precisa de `gh` (é ele quem abre/consulta PRs); subAgents de módulo não usam.
- **`gh pr list`/`gh pr view` retornam `[]`/vazio silenciosamente (sem erro) se o cwd não estiver
  dentro do clone git correto** (ex.: rodar de `agent-master/` em vez de `agent-master/repo/`) — o
  `gh` detecta o repositório pelo `remote` do diretório atual, não por config global; mesmo com
  `GH_TOKEN` válido e `gh auth status` OK, o comando "funciona" sem erro mas não acha nada. Sempre
  rodar comandos `gh pr *`/`gh repo *` com cwd dentro de `repo/`.

## Git — checkout local de `main` pode ficar obsoleto sem ninguém perceber

- Como o Agent Master nunca faz checkout de `main` (só mergeia/push em `reviewAgents`), o `git
  fetch` atualiza `origin/main` mas **não** avança o ponteiro local do branch `main` — ele só se
  move com checkout explícito ou `git branch -f main origin/main`/merge. Antes de comparar
  `main..reviewAgents` (p.ex. pra decidir se cria o PR único), confirme que o `main` local está em
  dia com `origin/main` (`git merge-base --is-ancestor main origin/main` deve dar sucesso; se sim,
  é seguro `git branch -f main origin/main` antes de comparar).

## Scheduled Tasks (Windows Task Scheduler)

- `SupE2eAutomation-SubAgent-<modulo>`: a cada 15 min.
- `SupE2eAutomation-AgentMaster`: a cada 30 min.
- `SupE2eAutomation-StatusWatcher`: **DESATIVADO em 2026-09-17** (ver seção 7 do `CLAUDE.md` do
  Supervisor) — pasta/script intactos, mas a Scheduled Task foi removida.
- Todas via `run-cycle.ps1` de cada pasta, chamando `powershell.exe -NoProfile -NonInteractive
  -ExecutionPolicy Bypass -WindowStyle Hidden -File <script>`, com `claude -p ... --permission-mode
  bypassPermissions --output-format stream-json --verbose`, log em `run-log.txt` na própria pasta.
- **Log em tempo real:** `stream-json --verbose` piped para um `ForEach-Object` que formata cada
  evento NDJSON em uma linha legível (`[sessao]`/`[fala]`/`[tool]`/`[resultado]`/`[ciclo
  encerrado]`) e grava em `run-log.txt` assim que acontece — dá pra ver o progresso real olhando o
  log durante a execução. Detalhe completo em `CONHECIMENTO-SUPERVISORES.md`.

## Remote `origin` de `C:\multiplica\cypress-e2e` ainda aponta pro nome antigo do repositório

- O clone de teste manual do Thiago (`C:\multiplica\cypress-e2e`) tem `origin` configurado como
  `git@github.com:Thiagocs12/automacaoMultiplica.git` (nome antigo), enquanto todo o resto (ex.:
  `agent-master/repo/`, `subagents/<modulo>/repo/`) usa
  `https://github.com/Thiagocs12/automacaoUiMultiplica.git` (nome atual, pós-rename). Verificado
  que não há divergência de conteúdo (`git rev-parse reviewAgents` bateu o mesmo hash nas duas
  URLs) — o GitHub redireciona automaticamente pull/fetch/push do nome antigo pro repositório
  renomeado. Não é um problema agora, mas **se o Thiago um dia liberar/reutilizar o nome antigo no
  GitHub, esse redirect quebra** e qualquer `git pull`/`fetch` feito contra essa URL (só a pasta
  `cypress-e2e`, que não é gerenciada por nenhum agente/repo/) passaria a falhar. Se algum agente
  notar erro de fetch/clone inesperado nessa pasta específica, checar primeiro se é isso antes de
  tratar como bug — a correção seria só `git remote set-url origin
  https://github.com/Thiagocs12/automacaoUiMultiplica.git` nessa pasta.

## Pré-checagem (seção 3.4) não distingue "pendente normal" de "pendente deliberadamente parado" — bug conhecido, não corrigido

- Quando o Thiago responde uma dúvida bloqueante dizendo "não reprocesse automaticamente até eu
  trazer instrução nova" mas o item continua fisicamente em `fila-merge/pendentes/` (Agent Master)
  ou `tarefas/pendentes/` (subAgent) — em vez de ser movido para um estado de espera — a
  pré-checagem em PowerShell da seção 3.4 do `CLAUDE.md` continua achando "há arquivo em
  pendentes/" e chamando o `claude -p` a cada ciclo, mesmo que a resposta já registrada diga
  explicitamente para não fazer nada. Isso já gerou **21 ciclos idênticos** de "nada a fazer" num
  único dia (Agent Master, aviso `20260914125955-atualizar-claude-md-fluxo-integracao`) — gasto de
  invocação/rate-limit sem trabalho real.
- Dúvida registrada pedindo decisão do Thiago (`agent-master/duvidas.md`,
  `20260915-ciclos-vazios-fila-merge-pendentes`): ajustar a pré-checagem para também tratar como
  "sem novidade" um item cuja resposta mais recente instrua explicitamente a não reprocessar, aceitar
  o custo, ou mover esse tipo de item para uma pasta de espera própria enquanto aguarda instrução.
- Até essa decisão: qualquer agente (subAgent ou Agent Master) que receber uma resposta do tipo
  "não reprocesse automaticamente, aguarde instrução nova" para um item que continua em
  `pendentes/` deve esperar o mesmo padrão de ciclos vazios repetidos — não é bug do ciclo em si, é
  uma lacuna conhecida da pré-checagem.

## Bug em `Test-DuvidaRespondida` (`run-cycle.ps1`): considera um id "respondido" para sempre após a 1ª rodada, ignorando rodadas posteriores ainda pendentes — não corrigido, já recorreu 2x (achado pelo `POC`)

- A função `Test-DuvidaRespondida` divide `duvidas.md` em blocos por `## ` e retorna no
  **primeiro** bloco cujo cabeçalho bate com o id da tarefa. Tarefas com várias rodadas de dúvida
  sob o **mesmo id** (comum neste projeto) sempre têm seu primeiro bloco como o mais antigo — uma
  vez que essa 1ª pergunta é respondida, a função retorna `true` **para sempre** para aquele id,
  mesmo que rodadas mais recentes estejam `Status: pendente`. Isso já moveu automaticamente uma
  tarefa do `POC` de volta pra `executando/` sem que a pergunta mais recente (bloqueio real)
  tivesse sido respondida — **recorreu 2x** (achado e depois confirmado de novo em 2026-09-16).
- **Correção sugerida, ainda não aplicada** (script compartilhado, copiado em cada
  subAgent/Agent Master/Status Watcher — melhor coordenar de uma vez em todas as cópias): iterar os
  blocos em ordem reversa (ou `Where-Object`/`Select-Object -Last 1` sobre os blocos que batem com
  o id) para checar o `Status:` do bloco **mais recente**, não do primeiro.
- Até a correção: qualquer agente que encontrar uma tarefa recém-movida para `pendentes/`/
  `executando/` por essa pré-checagem, numa tarefa com múltiplas rodadas de dúvida sob o mesmo id,
  deve conferir manualmente se a rodada **mais recente** em `duvidas.md` está mesmo
  `Status: respondida` antes de agir — não confiar cegamente na movimentação mecânica nesse caso
  específico.

## Vídeo substituído por relatório em PDF por cenário (módulo `geral`, tarefa `20260917111432-migrar-video-para-relatorio-pdf`, 2026-09-17)

- **Infra cross-módulo nova, disponível para qualquer Etapa:** `cypress.config.js` agora tem
  `video: false`. `cypress/support/etapas/EtapaBase.js` ganhou `this.passo(descricao, acao)` —
  tira `cy.screenshot` antes/depois de rodar `acao()`, nomeando o arquivo com o cenário (via
  `Cypress.currentTest.title`) + número do passo. Um novo `scripts/gerar-relatorio-pdf.cjs`
  (dependência `pdfkit`) agrupa esses screenshots por cenário e gera `relatorios/<cenario>.pdf`
  automaticamente depois de `npm test` (também via `npm run relatorio`). `relatorios/*.pdf` é
  **versionado** (não gitignored); `cypress/screenshots/` segue gitignored. Detalhe completo em
  `repo/CLAUDE.md` (seção "PDF execution report") e em `subagents/geral/docs/documentacao.md`.
  **Qualquer módulo (POC, mop, futuros) que queira o mesmo relatório visual só precisa envolver as
  ações relevantes de `executar()` em `this.passo(...)` em vez de chamar a Page direto** — só
  `EtapaAnalisarOperacaoMonitorDiario` (mop) foi migrada até agora, como referência.
