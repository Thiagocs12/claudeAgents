# Conhecimento geral do sistema (leitura obrigatória para todo agente)

Este arquivo reúne aprendizados e convenções que atravessam módulos — todo subAgent e o Agent
Master devem ler este arquivo INTEIRO antes de iniciar qualquer ciclo, além do
`docs/documentacao.md` do próprio módulo. Se você (agente) aprender algo que outro módulo também
precisaria saber, registre aqui — não só no seu `docs/documentacao.md` local.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização, para não
perder uma edição feita por outro agente rodando em paralelo (não há lock automático entre
ciclos).

## Convenções do repositório do projeto (automacaoUteisMultiplica)

- Repositório: `https://github.com/Thiagocs12/automacaoUteisMultiplica.git`. Já é um projeto
  maduro (Cypress + Cucumber) que sincroniza dados de referência PROD→HML nos domínios Produtos,
  Esteiras, Vínculos e Grupos e Permissões (Keycloak) — não é um repositório vazio criado para os
  agentes.
- Branch de integração: **`reviewAgents`** (criada em 2026-09-14, a partir da `master`, só para
  este propósito). `master` só recebe merge de `reviewAgents` em momentos de release — nunca
  commit/merge direto.
- O padrão de arquitetura do projeto está documentado no `README.md` e `CLAUDE.md` **do próprio
  repositório clonado** (não confundir com o `CLAUDE.md`/`docs/` do Supervisor, que é sobre como
  os agentes se organizam, não sobre a automação em si). O `CLAUDE.md` do repo já tem uma seção
  "Collaboration workflow" descrevendo esse mesmo fluxo de agentes/PR.
- **Integração (mudou em 2026-09-14, pedido explícito do Thiago — mesmo padrão do
  `SupE2eAutomation`):** o Agent Master faz **merge direto (com push) na `reviewAgents`** de cada
  tarefa aprovada nos testes — sem PR nem aprovação humana por tarefa. Ele **nunca** mergeia/dá
  push direto na `master`: o único ponto de revisão manual do Thiago é um **PR único e contínuo
  `reviewAgents → master`**, que o Agent Master garante que existe (cria uma vez se faltar, `gh pr
  create --base master --head reviewAgents`; nunca recria) e que reflete sozinho, via GitHub, cada
  commit novo pusheado na `reviewAgents`. Modelo anterior (PR por tarefa, aprovado manualmente um a
  um) abandonado por ser lento demais pro volume de tarefas — `fila-merge/aguardando-aprovacao/` só
  guardava o legado desse modelo (PR #5, branch `keycloakUser/clonar-usuario-prod-hml`), já
  mergeado e movido para `concluidos/`; a pasta deve estar vazia agora, nenhum aviso novo passa por
  ali. Ver seção 3.3 do `CLAUDE.md` do Supervisor e `CONHECIMENTO-SUPERVISORES.md` para o detalhe
  completo.
- Produção é **somente leitura por construção** (`validarSomenteLeituraEmProducao`) — qualquer
  requisição não-GET para os ambientes `prod`/`keycloakProd` lança erro. Nenhum agente deve tentar
  contornar isso.
- Realm do Keycloak usado por tudo: `multiplicacapital` (não `master`). Ambientes definidos em
  `cypress/support/commands/ambiente.js`: `prod`, `hml`, `keycloak` (Keycloak HML), `keycloakProd`
  (Keycloak PROD, só leitura).

## Contas de Claude Code por agente

- Cada subAgent/Agent Master roda um `claude -p` fixado numa conta própria via
  `CLAUDE_CONFIG_DIR` (pastas em `%USERPROFILE%\.claude-accounts\<conta>`), setada no início do
  `run-cycle.ps1` antes do `claude` iniciar.
- Contas **reaproveitadas do `SupE2eAutomation`** (decisão do Thiago em 2026-09-14, ciente da
  concorrência extra de rate-limit — ver `CONHECIMENTO-SUPERVISORES.md` na raiz de
  `C:\Multiplica\claudeAgents`).
- **Agent Master**: fixo em `contaB`. **Status Watcher**: fixo em `contaB`.
- **SubAgents de módulo**: revezam `contaA`/`contaB` pela ordem de criação. Atribuição atual:
  `keycloakUser` = `contaA` (1º módulo). Próximo módulo novo = `contaB`.

## GitHub CLI (`gh`) — usado pelo Agent Master para abrir PR

- Instalado como versão portátil em `%LOCALAPPDATA%\Programs\gh\bin\gh.exe` (reaproveitado da
  instalação já feita para o `SupE2eAutomation`).
- Autenticado via variável de ambiente `GH_TOKEN`, setada em `agent-master/run-cycle.ps1` a partir
  de `agent-master/.gh-token` (arquivo local, não versionado — mesmo token pessoal reaproveitado
  do `SupE2eAutomation`).
- **Pendência conhecida (2026-09-14, resolvida no mesmo dia):** esse token, apesar de ter
  push/admin no repositório `automacaoUteisMultiplica`, retornou `Resource not accessible by
  personal access token` ao tentar `gh pr create` — token fine-grained sem a permissão "Pull
  requests" habilitada na configuração do próprio token no GitHub. Thiago ajustou para "Read and
  write" e o token voltou a funcionar (PR #4 aberto com sucesso).
- **Pendência nova (2026-09-14, ciclo seguinte): token ficou totalmente inválido.** Num ciclo
  posterior, `gh auth status`/`gh pr list`/`gh pr view` passaram a falhar com "The token in
  GH_TOKEN is invalid" (não é mais o erro de permissão de antes — o token em si não autentica).
  Testado tanto `agent-master/.gh-token` quanto o token de origem em
  `SupE2eAutomation/agent-master/.gh-token` (diferentes entre si, ambos inválidos) — não é
  problema de sincronização entre as pastas dos dois Supervisores, os dois tokens pararam de
  funcionar (provável expiração/revogação). Dúvida bloqueante registrada em
  `agent-master/duvidas.md` (`gh-token-invalido-20260914`) pedindo um PAT novo — **isso afeta
  também o Agent Master do `SupE2eAutomation`**, já que reaproveita o mesmo token; vale conferir
  se ele já bateu no mesmo problema. Contorno parcial: operações puramente `git` (pull, log,
  detectar merge de uma branch específica olhando o histórico) continuam funcionando sem `gh` —
  só abrir/checar PR via `gh` que fica bloqueado até o token ser trocado.
- Só o Agent Master precisa de `gh`; subAgents de módulo não usam.

## `npm install` no repositório do projeto — `package-lock.json` é gitignored

- `automacaoUteisMultiplica` propositalmente não versiona `package-lock.json` (ver
  `CLAUDE.md`/seção "Segurança / não commitar" do próprio repo) — **não use `npm ci`** em nenhum
  clone (`agent-master/repo/`, `subagents/<modulo>/repo/`, `C:\multiplica\cypress-uteis`), ele
  falha sem lockfile. Use `npm install`.
- Nessa máquina, `npm install` puro falha com `ERESOLVE` (peer dependency: `cypress` pinado em
  `15.14.2` no `package.json` vs. `@badeball/cypress-cucumber-preprocessor@latest` pedindo outra
  faixa) — use `npm install --legacy-peer-deps`. Isso é só uma flag de instalação local, não altera
  nada no repositório; não "conserte" isso mexendo nas versões do `package.json` sem confirmar com
  o Thiago antes.
- Se um `node_modules/` de algum clone sumir/ficar incompleto (ex.: depois de um `npm install` que
  falhou pela metade), rode `npm install --legacy-peer-deps` de novo ali antes de rodar
  `test:safety`/lint/cypress — sem isso, testes que dependem de módulos nativos (ex.: `mssql`)
  falham com `Cannot find module`, um falso negativo que não tem nada a ver com a branch sendo
  validada.

## `.env` / variáveis de ambiente — quem cuida do quê

- O Agent Master mantém `agent-master/repo/.env` atualizado: a cada merge, compara `.env.example`
  antes/depois para achar variáveis novas e busca o valor em
  `subagents/<modulo>/docs/documentacao.md`/tarefa concluída. Nunca inventa nem deixa em branco —
  se não achar, vira dúvida bloqueante.
- `.env` inicial de `agent-master/repo/` e de `subagents/keycloakUser/repo/` foi copiado (sem
  exibir conteúdo) do clone pessoal do Thiago em `C:\multiplica\cypress-uteis\.env`.
- O Agent Master sincroniza `C:\multiplica\cypress-uteis` (pasta **pessoal** do Thiago, decisão
  dele em 2026-09-14 de reusar em vez de criar uma pasta dedicada) como pasta de teste manual a
  cada ciclo — cuidado: se ela tiver mudanças não commitadas do Thiago, o Agent Master não força
  nada, registra dúvida.
- **Nunca** exponha valores de variáveis de `.env`/tokens em `docs/documentacao.md`, `duvidas.md`
  ou em log de saída — só o nome da variável e de onde veio o valor.

## Scheduled Tasks (Windows Task Scheduler)

- `SupAutomacaoUteis-SubAgent-<modulo>`: a cada 5 minutos.
- `SupAutomacaoUteis-AgentMaster`: a cada 15 minutos.
- `SupAutomacaoUteis-StatusWatcher`: a cada 15 minutos.
- Cadência **igual à real** do `SupE2eAutomation` (não à documentação antiga dele, que ainda cita
  30min/1h em alguns arquivos — a Scheduled Task de fato registrada lá roda em 5min/15min;
  decisão do Thiago em 2026-09-14 de manter as duas famílias de Supervisor na mesma cadência).
- Todas via `run-cycle.ps1` de cada pasta, chamando `powershell.exe -NoProfile -NonInteractive
  -ExecutionPolicy Bypass -WindowStyle Hidden -File <script>`, com `claude -p ... --permission-mode
  bypassPermissions --output-format stream-json --verbose`, log em `run-log.txt` na própria pasta.
- **Log em tempo real (2026-09-14):** trocado de `--output-format text` (só grava no fim do ciclo)
  para `stream-json --verbose` piped para um `ForEach-Object` que formata cada evento NDJSON em
  uma linha legível (`[sessao]`/`[fala]`/`[tool]`/`[resultado]`/`[ciclo encerrado]`) e grava em
  `run-log.txt` assim que acontece — dá pra ver o progresso real olhando o log durante a execução.
  Ver detalhe completo em `CONHECIMENTO-SUPERVISORES.md`. Aplicado também no `SupE2eAutomation` a
  pedido do Thiago.

## Cypress + `node:test`/Promises nativas — armadilhas descobertas rodando e2e de verdade pela primeira vez (2026-09-14, módulo `keycloakUser`)

Ao implementar um recurso que precisa **continuar processando itens de uma lista mesmo quando um
item específico falha numa forma esperada** (ex.: clonagem em lote, onde um usuário não encontrado
não deve interromper os demais), duas armadilhas relevantes para qualquer módulo que vier a
precisar de algo parecido:

1. **Cypress não permite `try/catch`/`.catch()` em volta de um comando `cy.` que pode falhar.**
   Uma vez que um comando lança erro dentro de uma cadeia, a fila de comandos do teste é
   interrompida — nem `cy.once('fail', ...)` ajuda (só suprime a falha do teste como um todo, não
   permite retomar comandos seguintes na mesma cadeia). A única forma de "continuar após uma falha
   esperada" é o próprio código nunca lançar erro para os casos que devem permitir continuação —
   use um retorno discriminado (`{ ok: boolean, motivo?, valor? }`) em vez de `throw`, e decida no
   nível de cada modo de uso (ex.: modo único converte `ok: false` em `throw`; modo em lote não).
2. **Nunca misture uma `Promise` nativa com comandos `cy.` invocados de dentro dela.** O Cypress
   detecta e falha explicitamente ("Cypress detected that you returned a promise from a command
   while also invoking one or more cy commands in that promise") se uma função pura (testável via
   `node:test`, ex. `Promise.resolve([]).reduce(...)`) for chamada em produção passando comandos
   `cy.` como a função injetada. Se a função pura precisa funcionar tanto com `node:test` (Promise
   nativa) quanto dentro do Cypress real (`Cypress.Chainable`), receba o **acumulador inicial** como
   parâmetro em vez de fixá-lo em `Promise.resolve(...)` — no uso real passe `cy.wrap(valorInicial,
   { log: false })`, mantendo toda a cadeia dentro do sistema de comandos do Cypress; nos testes,
   `Promise.resolve(valorInicial)` continua funcionando normalmente.
3. **Nunca invoque um comando `cy.` (ex.: `cy.logExecucao(...)`) dentro de um `.then()` sem
   retornar/encadear esse comando, se aquele `.then()` também terminar retornando um valor
   síncrono.** O Cypress falha com "you invoked 1 or more cy commands but then returned a
   synchronous value". É fácil escrever isso sem perceber (`cy.logExecucao(msg); return valor;`) —
   e como não há erro de lint/typecheck para isso, só aparece rodando o cenário de verdade. Prefira
   sempre `return cy.logExecucao(msg).then(() => valor);`.
4. **Comandos longos (ex.: `npx cypress run` contra Keycloak real) podem estourar o timeout padrão
   do Bash (~120s) e virar processo em segundo plano — isso quebra a regra 5 do `AGENTE.md`
   ("nunca inicie um processo em segundo plano e encerre o ciclo esperando ele terminar depois")
   mesmo sem querer.** Observado ao vivo em 2026-09-14 (`keycloakUser`, tarefa de correção de
   email): `npx cypress run --env tags=...` passou de 120s, a ferramenta moveu o comando pra
   segundo plano sozinha, e o agente tentou "esperar" rodando comandos no-op (`echo`, `true`) em vez
   de efetivamente bloquear — isso não impede o ciclo de terminar, e o processo em segundo plano
   **não sobrevive ao fim do `claude -p`** (é filho dele). Resultado: ciclo encerrado com o teste
   ainda rodando, autoteste/commit final daquela etapa não aconteceram, ~$1,30 de custo perdido
   (mitigado só porque a tarefa continua em `tarefas/executando/` e o próximo ciclo retoma a mesma
   branch com as alterações de código já commitadas anteriormente intactas). **Correção**: ao rodar
   qualquer comando que pode passar de ~2min (qualquer `npx cypress run` contra ambiente real,
   `npm install` do zero, etc.), passe um `timeout` explícito bem acima do padrão (o suficiente pro
   comando terminar de verdade, ex. 300000-600000ms) para a chamada de Bash, em vez de deixar
   estourar o padrão e cair em segundo plano — isso faz a chamada bloquear de verdade dentro do
   próprio ciclo até o comando terminar, com o resultado real disponível pra decidir os próximos
   passos (autoteste passou/falhou, commit, etc.) sem depender de "esperar" um processo que pode
   nunca ser aguardado de fato.
5. **`cypress/temp/tokens.json` (gitignored) não existe na primeira execução num clone novo** —
   `cy.readFile(...).then(sucesso, erro)` em `ambiente.js`/`utils.js` tenta tratar isso via um
   segundo argumento de `.then()`, mas a API pública do `cy.then()` do Cypress só aceita um único
   callback (`then(options?, fn)` — sem `onRejected`); esse segundo argumento é silenciosamente
   ignorado, e um arquivo ausente vira uma falha "dura" do comando (retry até o timeout, depois
   falha o teste), não uma rejeição capturável por esse padrão. Isso é um bug pré-existente
   (afeta qualquer domínio, não só `keycloakUser`) que só aparece na primeira execução de verdade
   contra o Keycloak/API num ambiente novo — ainda não corrigido (fora do escopo de quem descobriu,
   arquivo compartilhado por todos os domínios). Contorno imediato: criar
   `cypress/temp/tokens.json` com `{}` antes de rodar pela primeira vez. Correção real sugerida:
   trocar por um `cy.task` que checa existência no Node (`fs.existsSync`) em vez de depender do
   `cy.readFile` "assertivo" do Cypress para um arquivo opcional.

## PR único `reviewAgents → master` — o que fazer se o Thiago já mergeou manualmente (2026-09-15)

- A regra "cria uma vez, nunca recria" do PR único pressupõe que ele continua aberto até o Agent
  Master decidir recriar. Na prática, o Thiago pode mesclar esse PR manualmente no GitHub a
  qualquer momento (é o ponto de revisão dele, ele tem controle total sobre quando mesclar) —
  aconteceu pela primeira vez em 2026-09-15 (PR #6 mergeado às 14:38 UTC sem aviso prévio a nenhum
  agente).
- Isso **não é um evento excepcional que precise de dúvida bloqueante**: o próximo ciclo do Agent
  Master detecta via `gh pr list --base master --head reviewAgents --state open` retornando vazio
  e simplesmente cria um novo PR contínuo (regra 3 do `AGENTE.md`), com o corpo explicando que foi
  recriado por causa do merge anterior. Não precisa perguntar ao Thiago nem esperar decisão dele —
  abrir/manter esse PR já é descrito como automático e independente de aprovação.
