# Conhecimento acumulado do Agent Master

## 2026-09-14 — Setup inicial

- Repositório clonado em `repo/`, branch `reviewAgents` criada a partir de `master` e publicada.
- Branch `chore/bootstrap-agentes-automacao` aberta a partir de `reviewAgents` com: seção
  "Collaboration workflow" no `CLAUDE.md` do repo, `.claude/settings.json` (hook SessionStart) e
  `.claude/skills/resolve-conflicts/` — ainda **sem PR aberto** por causa da pendência de GH_TOKEN
  abaixo. Assim que o token for corrigido, abrir o PR (`gh pr create --base reviewAgents --head
  chore/bootstrap-agentes-automacao`) antes de processar qualquer outro aviso.
- `.env` copiado (sem exibir conteúdo) de `C:\multiplica\cypress-uteis\.env` para `repo/.env`.
- `.gh-token` copiado (sem exibir conteúdo) de `SupE2eAutomation/agent-master/.gh-token`.

## 2026-09-14 — PR de bootstrap aberto com sucesso

- Causa raiz da falha de `gh pr create` (ver `duvidas.md`, dúvida `setup-gh-token`, já
  respondida): o token estava com a permissão "Pull requests" em "Read-only" nas configurações do
  próprio token no GitHub — não era falta de acesso ao repositório (já estava em "All
  repositories"). Thiago ajustou para "Read and write".
- PR aberto: `chore/bootstrap-agentes-automacao` → `reviewAgents`:
  https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/4 — ainda **aguardando aprovação
  manual do Thiago**. Depois de mergeado, os próximos ciclos vão herdar `.claude/settings.json`
  (hook de sync automático) e a skill `/resolve-conflicts` em qualquer clone que der pull na
  `reviewAgents`.

## 2026-09-14 — Ciclo: PR #4 mergeado + PR #5 aberto (tarefa `keycloakUser`)

- **PR #4** (`chore/bootstrap-agentes-automacao` → `reviewAgents`) confirmado `MERGED` (via
  `gh pr view`). `repo/` atualizado com `git pull origin reviewAgents` (fast-forward). Sem
  variável nova em `.env.example` nesse merge.
- **Aviso `20260914115110-clonar-usuario-keycloak-prod-hml`** (módulo `keycloakUser`,
  branch `keycloakUser/clonar-usuario-prod-hml`), que estava em `fila-merge/pendentes/`:
  - Merge de teste local contra `reviewAgents`: sem conflitos.
  - `.env.example`: sem variáveis novas nessa branch.
  - `node_modules` de `repo/` estava ausente (reinstalado com `npm install --legacy-peer-deps`
    — necessário por causa de um conflito de peer dependency entre `cypress` (pinado em
    `15.14.2`) e `@badeball/cypress-cucumber-preprocessor@latest`; `npm ci` não é opção aqui,
    `package-lock.json` é intencionalmente gitignored pelo repo). Registrado em
    `../docs/conhecimento-geral.md` para os demais agentes não se surpreenderem com isso.
  - `npm run test:safety`: 27/27 (10 novas desta branch). `npm run lint`: 0 erros, só os 4
    warnings pré-existentes já conhecidos.
  - Cenário `@keycloakUsuario` fim a fim **não rodado** por decisão do Agent Master: exige
    escolher um `usuarioOrigem` real de PROD, decisão que nenhum agente deve tomar sozinho (o
    próprio `CLAUDE.md` do repo documenta essa regra do domínio). Fica para o Thiago validar
    manualmente via `cypress-uteis`.
  - PR aberto: `keycloakUser/clonar-usuario-prod-hml` → `reviewAgents`:
    https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/5 — aguardando aprovação manual
    do Thiago. Aviso movido de `fila-merge/pendentes/` para `fila-merge/aguardando-aprovacao/`.
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): working tree estava limpa
  (branch `master`, sem mudanças pendentes do Thiago). Checkout para
  `keycloakUser/clonar-usuario-prod-hml` (branch do PR #5, único aguardando aprovação no fim do
  ciclo) — `origin` já configurado, `node_modules` já presente (não precisou `npm ci`). `.env`
  copiado de `repo/.env` por cima do `.env` local dessa pasta.
- Nenhuma dúvida nova registrada neste ciclo — a única entrada em `duvidas.md`
  (`setup-gh-token`) já estava `respondida` e o PR #5 confirmou que o `GH_TOKEN` está
  funcionando normalmente agora.

## 2026-09-14 — Ciclo de rotina: nada novo a processar

- Nota sobre o prompt de invocação deste ciclo: ele instruía "se a dúvida `setup-gh-token`
  ainda estiver `Status: pendente`, pule tentativa de abrir PR". Conferido: a dúvida já está
  `respondida` desde o ciclo anterior, e `gh auth status`/`gh pr view` confirmaram o `GH_TOKEN`
  funcionando normalmente — instrução de invocação estava desatualizada em relação ao estado
  real, então segui o fluxo normal (nenhum PR novo a abrir, ver abaixo).
- `fila-merge/aguardando-aprovacao/`: só o aviso `20260914115110-clonar-usuario-keycloak-prod-hml`
  (PR #5). `gh pr view keycloakUser/clonar-usuario-prod-hml` → `state: OPEN`, `mergedAt: null`.
  Ainda aguardando aprovação manual do Thiago — nenhuma ação tomada, conforme regra 3.
- `fila-merge/pendentes/`: vazio, nada a processar.
- Sincronização de `C:\multiplica\cypress-uteis`: já estava na branch correta
  (`keycloakUser/clonar-usuario-prod-hml`, a do único PR aguardando aprovação), working tree
  limpa, `git pull` sem novidades, `node_modules` presente, `.env` já idêntico ao
  `repo/.env` (nenhuma cópia necessária).
- Nenhuma dúvida nova registrada. Nenhum aprendizado novo para `../docs/conhecimento-geral.md`
  neste ciclo (tudo já documentado).

## 2026-09-14 — Ciclo: PR único `reviewAgents → master` criado (PR #6)

- **PR único de integração**: `gh pr list --base master --head reviewAgents --state open` não
  retornou nenhum aberto — criado agora: **PR #6**
  (https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/6). Diferença atual `master` vs.
  `reviewAgents`: só o merge do PR #4 (`chore/bootstrap-agentes-automacao`), 2 commits. Este PR
  fica sempre aberto e reflete sozinho, via GitHub, cada commit novo pusheado em `reviewAgents` —
  não recriar em ciclos futuros, só conferir que continua aberto.
- **Legado (`fila-merge/aguardando-aprovacao/`)**: único aviso, PR #5
  (`keycloakUser/clonar-usuario-prod-hml`), conferido via `gh pr view` → `state: OPEN`,
  `mergedAt: null`. Nenhuma ação tomada (regra: só o Thiago mexe nesse PR antigo).
- **`fila-merge/pendentes/`**: vazio, nada a processar neste ciclo.
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): working tree limpa na branch
  antiga (`keycloakUser/clonar-usuario-prod-hml`) — sem mudanças do Thiago perdidas. Checkout para
  `reviewAgents` (novo padrão do fluxo, não há mais branch de PR-por-tarefa pra testar antes de
  aprovar) + `git pull origin reviewAgents` (já atualizada). `node_modules` presente, não precisou
  `npm install`. `.env` comparado (nomes de variável e conteúdo, sem exibir valores) contra
  `repo/.env` — já idêntico, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada neste ciclo. Nenhum aprendizado novo específico deste módulo além
  do já registrado em `../docs/conhecimento-geral.md` (o fato de existir agora um PR contínuo
  `reviewAgents → master` já estava documentado como parte do fluxo — só faltava o PR em si ser
  criado, o que ficou pendente do primeiro ciclo em que não havia mais nada em
  `fila-merge/pendentes/` pra processar antes).

## 2026-09-14 — Ciclo: GH_TOKEN inválido, contornado parcialmente com git puro

- **`GH_TOKEN` inválido**: `gh auth status` e `gh pr list`/`gh pr view` falharam com "The token in
  GH_TOKEN is invalid" — testado tanto com `agent-master/.gh-token` quanto com o token de origem
  em `SupE2eAutomation/agent-master/.gh-token` (diferentes entre si, ambos inválidos agora).
  Dúvida bloqueante registrada em `duvidas.md` (`gh-token-invalido-20260914`) pedindo um token
  novo. Detalhe cross-módulo em `../docs/conhecimento-geral.md`.
- **Legado (`fila-merge/aguardando-aprovacao/`)**: PR #5 (`keycloakUser/clonar-usuario-prod-hml`)
  — não deu pra confirmar via `gh pr view` (token inválido), mas confirmei via `git log
  origin/reviewAgents` que o commit de merge do PR #5 (`ef441f7 Merge pull request #5 from
  Thiagocs12/keycloakUser/clonar-usuario-prod-hml`) já está em `reviewAgents` no GitHub — ou seja,
  foi mergeado (provavelmente aprovação manual direta do Thiago no GitHub). `repo/`: `git pull
  origin reviewAgents` (fast-forward, 66a512c→ef441f7). `.env.example`: sem variável nova nesse
  merge (diff vazio entre antes/depois). Aviso movido para `fila-merge/concluidos/`.
- **`fila-merge/pendentes/`**: vazio, nada a processar.
- **PR único `reviewAgents → master` (PR #6)**: **não verificado neste ciclo** por falta de `gh`
  funcional — não tentei recriar (evitar duplicata às cegas). Fica pendente de confirmação no
  próximo ciclo em que o token for corrigido.
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): working tree limpa, já na
  branch `reviewAgents`, `git pull` sem novidades (já estava em `ef441f7`), `node_modules`
  presente (523 pacotes, não precisou `npm install`). `.env` já idêntico ao `repo/.env` (comparado
  por conteúdo via `cmp`, sem exibir valores) — nenhuma cópia necessária.

## 2026-09-14 — Ciclo: GH_TOKEN continua inválido (dúvida `gh-token-invalido-20260914` ainda pendente)

- Testei de novo neste ciclo: `gh auth status` → "The token in GH_TOKEN is invalid." Mesmo
  problema do ciclo anterior, sem mudança. A dúvida `gh-token-invalido-20260914` em `duvidas.md`
  já cobre exatamente isso e continua com `Status: pendente` (sem resposta do Thiago ainda) — não
  registrei uma segunda dúvida duplicada, só confirmei que o bloqueio persiste.
- Como não dá pra usar `gh`, não foi possível: confirmar se o PR único `reviewAgents → master`
  (PR #6) continua aberto, nem checar status de qualquer PR.
- Contorno com `git` puro (sem `gh`): `git fetch origin` em `repo/` confirma que `reviewAgents`
  remoto continua exatamente em `ef441f7` (nenhum commit novo desde o ciclo anterior) e que
  `master` remoto ainda não contém `ef441f7`/`66a512c` — ou seja, consistente com o PR #6 ainda
  **não** ter sido mergeado (sinal indireto, não confirmação via `gh`).
- `fila-merge/aguardando-aprovacao/`: vazio (legado já totalmente processado em ciclo anterior).
  `fila-merge/pendentes/`: vazio, nada a processar.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): working tree limpa, já na branch
  `reviewAgents`, `git fetch`/estado sem novidades. `node_modules` presente, não precisou
  `npm install`. Comparei só os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa pasta
  (sem exibir valores) — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada (a existente já cobre o bloqueio). Nenhum aprendizado novo para
  `../docs/conhecimento-geral.md` — o problema do `GH_TOKEN` já está documentado lá desde o ciclo
  anterior.

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido, sem novidade a processar

- Testei de novo: `gh auth status` → "The token in GH_TOKEN is invalid." Mesmo bloqueio dos dois
  ciclos anteriores. A dúvida `gh-token-invalido-20260914` em `duvidas.md` continua
  `Status: pendente` (sem resposta do Thiago ainda) — não registrei duplicata.
- Como consequência, não deu pra confirmar via `gh` se o PR único `reviewAgents → master` (PR #6)
  continua aberto. Sinal indireto via `git` puro: `origin/master` ainda não contém `ef441f7`
  (commit de topo de `origin/reviewAgents`) — consistente com o PR #6 ainda não ter sido
  mergeado, mas não é confirmação real do estado do PR.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado). Nada a mesclar neste ciclo.
- `repo/`: `git fetch origin` sem novidade — `reviewAgents` local já em `ef441f7`, working tree
  limpa, sem necessidade de pull.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, já em `ef441f7` (sem pull necessário). `node_modules` presente. Comparei só
  os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa pasta (sem exibir valores) —
  idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada, nenhum aprendizado novo para `../docs/conhecimento-geral.md`.

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido (mesmo bloqueio, sem novidade)

- Testei de novo: `gh auth status` (com `GH_TOKEN` de `agent-master/.gh-token`) → "The token in
  GH_TOKEN is invalid." Mesmo bloqueio de todos os ciclos anteriores desde que quebrou. A dúvida
  `gh-token-invalido-20260914` em `duvidas.md` continua `Status: pendente` — não registrei
  duplicata.
- Sem `gh`, não deu pra confirmar o estado do PR único `reviewAgents → master` (PR #6). Sinal
  indireto via `git fetch origin` em `repo/`: `origin/reviewAgents` continua em `ef441f7` (mesmo
  commit de topo de todos os ciclos anteriores) e `git log origin/master..origin/reviewAgents`
  ainda lista os mesmos 4 commits (PR #4 + PR #5) — consistente com PR #6 ainda **não** mergeado,
  mas não é confirmação real via `gh`.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado, só resta o item em `concluidos/`). Nada a mesclar neste ciclo.
- `repo/`: `git fetch origin` sem novidade — `reviewAgents` local já em `ef441f7`, working tree
  limpa, sem necessidade de pull.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, `git pull` sem novidade (já em `ef441f7`). `node_modules` presente, não
  precisou `npm install`. Comparei só os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa
  pasta (sem exibir valores) — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada (a existente já cobre o bloqueio). Nenhum aprendizado novo para
  `../docs/conhecimento-geral.md` neste ciclo.

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido (mesmo bloqueio, sem novidade)

- Testei de novo: `gh auth status` → "The token in GH_TOKEN is invalid." Também tentei `gh pr
  list` diretamente dentro de `repo/` (git repo válido) → `HTTP 401: Bad credentials`. Mesmo
  bloqueio dos ciclos anteriores, sem mudança. A dúvida `gh-token-invalido-20260914` em
  `duvidas.md` continua `Status: pendente` — não registrei duplicata, só confirmei que o problema
  persiste.
- Sem `gh`, não deu pra confirmar o estado do PR único `reviewAgents → master` (PR #6). Sinal
  indireto via `git` puro: `git fetch origin` em `repo/` sem novidade — `origin/reviewAgents`
  continua em `ef441f7` (mesmo commit de topo dos ciclos anteriores), e
  `git log origin/master..origin/reviewAgents` ainda lista os mesmos 4 commits (PR #4 + PR #5) —
  consistente com PR #6 ainda **não** mergeado, mas não é confirmação real.
- Notei duas branches remotas novas em `repo/` que não apareciam em ciclos anteriores: `esteiras`
  e `esteirasmop`. Não há nenhum aviso correspondente em `fila-merge/pendentes/` nem
  `aguardando-aprovacao/`, então não processei nada — provavelmente trabalho de um módulo novo
  ainda não formalizado como subAgent, ou branch pessoal do Thiago. Fica só registrado aqui como
  observação; se um aviso de merge para essas branches aparecer sem um subAgent `esteiras`
  correspondente em `../subagents/`, tratar como incerteza a esclarecer com o Supervisor antes de
  mexer.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado, confirmado que só resta o item em `concluidos/`).
- `repo/`: `git fetch origin` sem novidade, working tree limpa em `reviewAgents`, já em `ef441f7`.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, já em `ef441f7` (sem pull necessário). `node_modules` presente. Comparei só
  os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa pasta (sem exibir valores) —
  idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada, nenhum aprendizado novo para `../docs/conhecimento-geral.md`
  além da observação sobre as branches `esteiras`/`esteirasmop` (não é cross-módulo o suficiente
  pra justificar entrada lá — é só uma observação local deste ciclo).

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido (mesmo bloqueio, sem novidade)

- Testei de novo: `gh auth status` (com `GH_TOKEN` de `agent-master/.gh-token`) → "The token in
  GH_TOKEN is invalid." Mesmo bloqueio dos ciclos anteriores. A dúvida
  `gh-token-invalido-20260914` em `duvidas.md` continua `Status: pendente` — não registrei
  duplicata.
- Sem `gh`, não deu pra confirmar o estado do PR único `reviewAgents → master` (PR #6). Sinal
  indireto via `git fetch origin` em `repo/`: `origin/reviewAgents` continua em `ef441f7` (mesmo
  commit de topo de todos os ciclos anteriores desde que o token quebrou) e
  `git log origin/master..origin/reviewAgents` ainda lista os mesmos 4 commits (PR #4 + PR #5) —
  consistente com PR #6 ainda **não** mergeado, mas não é confirmação real via `gh`.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado). Nada a mesclar neste ciclo.
- `repo/`: `git fetch origin` sem novidade — `reviewAgents` local já em `ef441f7`, working tree
  limpa, sem necessidade de pull.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, `git fetch` sem novidade (já em `ef441f7`). `node_modules` presente, não
  precisou `npm install`. Comparei só os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa
  pasta (sem exibir valores) — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada (a existente já cobre o bloqueio). Nenhum aprendizado novo para
  `../docs/conhecimento-geral.md` neste ciclo.

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido (mesmo bloqueio, sem novidade)

- Testei de novo: `gh auth status` (com `GH_TOKEN` de `agent-master/.gh-token`) → "The token in
  GH_TOKEN is invalid." Mesmo bloqueio de todos os ciclos anteriores desde que quebrou. A dúvida
  `gh-token-invalido-20260914` em `duvidas.md` continua `Status: pendente` (sem resposta do Thiago
  ainda) — não registrei duplicata.
- Sem `gh`, não deu pra confirmar o estado do PR único `reviewAgents → master` (PR #6). Sinal
  indireto via `git fetch origin` em `repo/`: `origin/reviewAgents` continua em `ef441f7` (mesmo
  commit de topo de todos os ciclos anteriores) e `git log origin/master..origin/reviewAgents`
  ainda lista os mesmos 4 commits (PR #4 + PR #5) — consistente com PR #6 ainda **não** mergeado,
  mas não é confirmação real via `gh`.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado, só resta o item em `concluidos/`). Nada a mesclar neste ciclo.
- `repo/`: `git fetch origin` sem novidade — `reviewAgents` local já em `ef441f7`, working tree
  limpa, sem necessidade de pull.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, `git status` sem novidade (já em `ef441f7`). `node_modules` presente, não
  precisou `npm install`. Comparei só os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa
  pasta (sem exibir valores) — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada (a existente já cobre o bloqueio). Nenhum aprendizado novo para
  `../docs/conhecimento-geral.md` neste ciclo.

## 2026-09-14 — Ciclo: GH_TOKEN ainda inválido (mesmo bloqueio, sem novidade)

- Testei de novo: `gh auth status` (com `GH_TOKEN` de `agent-master/.gh-token`) → "The token in
  GH_TOKEN is invalid." Mesmo bloqueio de todos os ciclos anteriores desde que quebrou — esta é a
  enésima confirmação consecutiva do mesmo estado. A dúvida `gh-token-invalido-20260914` em
  `duvidas.md` continua `Status: pendente` (sem resposta do Thiago ainda) — não registrei
  duplicata.
- Sem `gh`, não deu pra confirmar o estado do PR único `reviewAgents → master` (PR #6). Sinal
  indireto via `git fetch origin` em `repo/`: `origin/reviewAgents` continua em `ef441f7` (mesmo
  commit de topo de todos os ciclos anteriores) e `git log origin/master..origin/reviewAgents`
  ainda lista os mesmos 4 commits (PR #4 + PR #5) — consistente com PR #6 ainda **não** mergeado,
  mas não é confirmação real via `gh`.
- `fila-merge/pendentes/`: vazio. `fila-merge/aguardando-aprovacao/`: vazio (legado já todo
  processado, só resta o item em `concluidos/`). Nada a mesclar neste ciclo.
- `repo/`: `git fetch origin` sem novidade — `reviewAgents` local já em `ef441f7`, working tree
  limpa, sem necessidade de pull.
- Sincronização da pasta manual (`C:\multiplica\cypress-uteis`): já na branch `reviewAgents`,
  working tree limpa, `git fetch` sem novidade (já em `ef441f7`). `node_modules` presente, não
  precisou `npm install`. Comparei só os **nomes** das variáveis de `repo/.env` vs. o `.env` dessa
  pasta (sem exibir valores) — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada (a existente já cobre o bloqueio). Nenhum aprendizado novo para
  `../docs/conhecimento-geral.md` neste ciclo.

## 2026-09-14 — Ciclo: GH_TOKEN confirmado válido + merge direto de `keycloakUser/clonar-usuarios-em-lote`

- **`GH_TOKEN` funcionando de novo**: a dúvida `gh-token-invalido-20260914` já estava `Status:
  respondida` em `duvidas.md` (Thiago gerou um PAT novo e atualizou `.gh-token` numa sessão
  interativa anterior a este ciclo, não capturada num ciclo automático anterior deste arquivo).
  Confirmei neste ciclo: `gh auth status` autentica como `Thiagocs12`, `gh api
  repos/.../permissions` retorna `push`/`admin`, e `gh pr list --base master --head reviewAgents
  --state open` retorna o PR #6 aberto. Bloqueio de ~8 ciclos consecutivos está encerrado.
  - Nota técnica sem relação causal com o bloqueio em si (registrada por precaução, para não repetir
    a investigação): `agent-master/.gh-token` tinha um BOM UTF-8 (`EF BB BF`) antes do conteúdo do
    token. Isso quebra ferramentas que leem o arquivo cru byte-a-byte (ex.: `cat` em bash), mas
    **não afeta** o caminho de produção real (`Get-Content -Raw` no `run-cycle.ps1`), que já
    decodifica e descarta o BOM corretamente — testado isoladamente e confirmado. Removi o BOM do
    arquivo mesmo assim (mesmo valor de token, só formato), sem efeito funcional esperado.
- **PR único `reviewAgents → master` (PR #6)**: confirmado `OPEN`, não recriado.
- **`fila-merge/aguardando-aprovacao/`**: vazio (legado já todo processado).
- **`fila-merge/pendentes/`**: 1 aviso processado — `20260914174624-clonar-usuarios-em-lote.md`
  (módulo `keycloakUser`, branch `keycloakUser/clonar-usuarios-em-lote`, 2 commits: clonagem em
  lote de usuários Keycloak PROD→HML + correção para nunca copiar o email do usuário original).
  - Merge de teste local contra `reviewAgents`: sem conflitos.
  - `.env.example`: sem variável nova.
  - `cypress/temp/tokens.json` criado com `{}` antes dos testes (armadilha conhecida, ver
    `../docs/conhecimento-geral.md`).
  - `npm run lint`: 0 erros (mesmos 4 warnings pré-existentes). `npm run test:safety`: 34/34.
  - `npx cypress run --env tags=@clonarUsuariosEmLote` contra o Keycloak real: 1 falha — mas é
    comportamento esperado, não bug: a fixture commitada (`cypress/fixtures/usuariosParaClonar.json`)
    é um template vazio (`{}`) de propósito (decisão de "qual usuário copiar" não é da automação,
    mesmo raciocínio já aplicado pelo Agent Master ao pular o e2e completo do PR #5) — o código
    lança erro claro ("Fixture de usuários para clonar em lote está vazia") em vez de fazer algo
    incorreto silenciosamente. Tratado como guard-rail funcionando corretamente, não como falha de
    teste bloqueante. `cypress/screenshots/` gerado pelo run de teste foi removido antes do commit
    (artefato local, não versionado).
  - Merge finalizado e pushado direto em `reviewAgents` (commit `78ea304`, sem PR). Aviso movido de
    `fila-merge/pendentes/` para `fila-merge/concluidos/`. Branch local
    `keycloakUser/clonar-usuarios-em-lote` deletada após o merge (branch remota mantida).
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): working tree limpa, já em
  `reviewAgents`, `git pull` trouxe o novo commit (`ef441f7` → `78ea304`, fast-forward).
  `node_modules` presente, não precisou `npm install`. Nomes de variáveis de `.env` comparados
  (sem exibir valores) contra `repo/.env` — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada neste ciclo. Nenhum aprendizado cross-módulo novo além da nota
  técnica do BOM acima (não achei necessário replicar em `../docs/conhecimento-geral.md` por não
  ter causado o bloqueio real — mantenho só aqui para não reinvestigar à toa num ciclo futuro).

## 2026-09-15 — Ciclo: merge direto de `keycloakUser/normalizar-case-usuario-minusculas` (retomando merge de teste deixado incompleto)

- **Estado inicial de `repo/` neste ciclo**: já estava em `reviewAgents`, mas com um merge de
  teste **em andamento e incompleto** (`MERGE_HEAD` apontando pra
  `keycloakUser/normalizar-case-usuario-minusculas`, conflitos já resolvidos e staged, porém sem
  commit) — sinal de que um ciclo anterior (não capturado neste arquivo) chegou a rodar o merge de
  teste local e resolver conflitos, mas não terminou a etapa (rodar os testes / finalizar / push)
  antes do fim do ciclo. Retomado: dei `git commit --no-edit` pra concluir esse merge de teste
  local (ainda não publicado) e segui o fluxo normal da regra 5 a partir daí.
- **`fila-merge/pendentes/`**: 1 aviso processado — `20260915100931-normalizar-case-usuario-minusculas.md`
  (módulo `keycloakUser`, branch `keycloakUser/normalizar-case-usuario-minusculas`: normaliza
  `username`/`usuarioOrigem` para minúsculas antes de usar no Keycloak, corrigindo falha de
  `expect` no cenário `@keycloakUsuario` por divergência de case, não de dado real).
  - Merge de teste local contra `reviewAgents`: conflito (já resolvido pelo ciclo anterior,
    conforme acima) — só faltou o commit, que concluí agora.
  - `.env.example`: sem variável nova (`git diff 78ea304 origin/keycloakUser/normalizar-case-usuario-minusculas -- .env.example` vazio).
  - `npm run lint`: 0 erros (mesmos 4 warnings pré-existentes, arquivos não tocados por esta
    branch). `npm run test:safety`: 38/38 (bate com o relatado pelo subAgent no aviso).
  - `npx cypress run --env tags=@keycloakUsuario,usuarioOrigem=usuario-inexistente-teste-autoteste-agente,...`
    contra o Keycloak real: mesma falha esperada já documentada pelo subAgent ("Usuário de origem
    ... não encontrado em produção") — guard-rail funcionando, não regressão. Confirmado que só o
    spec `gerenciamentoDeUsuarios.feature` falha (os demais specs da suíte completa passam/ficam
    pending normalmente). `cypress/screenshots/` gerado pelo run removido antes do push (artefato
    local).
  - Merge finalizado e pushado direto em `reviewAgents` (commit `a1de77b`, sem PR). Aviso movido de
    `fila-merge/pendentes/` para `fila-merge/concluidos/`. Branch local
    `keycloakUser/normalizar-case-usuario-minusculas` deletada após o merge (branch remota
    mantida).
- **PR único `reviewAgents → master` (PR #6)**: confirmado `OPEN` via `gh pr list` (token válido,
  sem pendência), não recriado — reflete o novo commit automaticamente.
- **`fila-merge/aguardando-aprovacao/`**: vazio (legado já todo processado, nada novo).
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): working tree limpa, já em
  `reviewAgents`, `git pull` trouxe o novo commit (`78ea304` → `a1de77b`, fast-forward).
  `node_modules` presente, não precisou `npm install`. Nomes de variáveis de `.env` comparados
  (sem exibir valores) contra `repo/.env` — idênticos, nenhuma cópia necessária.
- Nenhuma dúvida nova registrada neste ciclo. Nenhum aprendizado cross-módulo novo — o único ponto
  digno de nota (merge de teste local deixado a meio caminho por um ciclo anterior, sem commit) já
  é coberto pela regra geral de retomar trabalho em andamento; não é um padrão novo que precise
  virar entrada própria em `../docs/conhecimento-geral.md`.
