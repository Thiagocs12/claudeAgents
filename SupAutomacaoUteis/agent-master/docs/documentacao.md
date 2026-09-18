# Conhecimento acumulado do Agent Master

> Histórico completo de ciclos anteriores (2026-09-14 a 2026-09-15) arquivado em
> `documentacao-historico.md` — consulte lá para detalhes de cada merge/ciclo passado. Este
> arquivo mantém só o resumo do que ainda é operacionalmente relevante.

## Estado atual (atualizado no ciclo de 2026-09-17 — merge de `cedente/clonar-cedente-completo-prod-hml`)

- **PR único de integração contínua `reviewAgents → master`**: **PR #8**
  (https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/8), aberto. Substituiu o **PR #7**,
  que o Thiago mergeou manualmente em `2026-09-15T15:23:05Z` — passou **despercebido por dois
  ciclos** (nenhum aviso em `fila-merge/pendentes/` entre 2026-09-15 e 2026-09-17 até este ciclo,
  então a checagem do PR único não rodou nesse intervalo, ver regra 3.4 do `CLAUDE.md` do
  Supervisor: só reconferido em ciclo que processa algo). Recriado neste ciclo assim que detectado
  (`gh pr list` vazio) — comportamento esperado, ver "Decisões de processo" abaixo. Não recriar
  enquanto #8 continuar aberto.
- **Último commit mergeado em `reviewAgents`**: `f3542ec` (merge da tarefa
  `cedente/clonar-cedente-completo-prod-hml` — primeira automação completa do módulo `cedente`:
  clona um cedente inteiro de PROD para HML, prospect→POC→comitê→cedente, com `criar` e
  `apagar-e-recriar`, e cascata de `MC_CED_CEDENTE_VINCULADO`; sem conflito, sem variável nova de
  `.env.example`). Histórico de commits anteriores: `ef441f7` (PR #5) → `78ea304` → `a1de77b` →
  `c9bf535` → `f4c41cf` → `f3542ec` (atual).
- **`fila-merge/aguardando-aprovacao/`** (modelo antigo de PR-por-tarefa): vazio, legado 100%
  processado (só resta histórico em `fila-merge/concluidos/`). Nenhum aviso novo deve passar por
  ali — modelo abandonado.
- **`.env` / `.env.example`**: nenhuma variável nova foi introduzida em nenhum merge até agora
  (todos os diffs de `.env.example` vieram vazios, incluindo o merge do `cedente` — reaproveita
  credenciais PROD/HML/SQL Server já existentes). `repo/.env` e o `.env` de
  `C:\multiplica\cypress-uteis` seguem idênticos em nomes de variável — nenhuma variável pendente
  de valor conhecido no momento.
- **`GH_TOKEN`**: funcionando normalmente desde o ciclo de 2026-09-14 que confirmou a correção
  (Thiago gerou PAT novo). Bloqueio anterior (~8 ciclos consecutivos de token inválido) está
  encerrado — detalhes só no histórico.
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): mantida na branch
  `reviewAgents`, sincronizada até o commit `f3542ec` (fast-forward puro, sem `npm install`
  necessário — sem mudança em `package.json`). Há (desde 2026-09-15) uma alteração **não
  commitada do Thiago** em `cypress/fixtures/usuariosParaClonar.json` (dado pessoal de teste) —
  preservada intencionalmente, nenhum merge até agora tocou esse arquivo. `node_modules` presente
  nessa pasta, sem necessidade de reinstalar.
- **Observação para o teste manual do `cedente`**: o subAgent reportou que `npx cypress run` não
  roda na máquina dele desde o Ciclo 20 (binário baixa mas o unzip nunca termina — parece ambiente/
  IO local, não código); o Agent Master não tentou reproduzir aqui (regra do módulo é não re-rodar
  teste que o subAgent já rodou, e este nunca chegou a rodar de fato). Teste manual fim a fim em
  HML (`criar` e `apagar-e-recriar`, idealmente com `idCedenteVinculado` preenchido pra exercitar a
  cascata) ainda não foi feito por ninguém — recomendado ao Thiago antes de mesclar o PR #8.

## Decisões de processo vigentes

- Merge direto (com push) na `reviewAgents`, sem PR por tarefa e sem aprovação humana individual
  (pedido do Thiago em 2026-09-14). Único ponto de revisão manual é o PR único contínuo acima.
- Exceção implícita à regra "PR único nunca precisa ser recriado": se o Thiago mergear
  manualmente o PR contínuo, o próximo ciclo detecta via `gh pr list --base master --head
  reviewAgents --state open` vazio e recria normalmente, sem precisar de decisão dele pra isso.
- Quando o merge de teste for fast-forward puro (sem branch local própria criada para a tarefa):
  **nunca rodar `git push --delete` na branch remota** — não há branch local equivalente pra
  "limpar"; a branch remota deve ser preservada como nos demais casos (erro cometido e corrigido
  no ciclo de 2026-09-15, ver histórico para o caso concreto).
- Cenários que dependem de escolha de dado sensível/real (ex.: `usuarioOrigem` de PROD) nunca são
  decididos pelo Agent Master/subAgent sozinho — ficam para validação manual do Thiago.
- `cypress/temp/tokens.json` precisa existir como `{}` antes de rodar os testes — armadilha
  pré-existente do `cy.readFile(...).then(sucesso, erro)` em `ambiente.js`/`utils.js` (a API
  pública do `cy.then()` só aceita um único callback, o segundo argumento é ignorado
  silenciosamente); contorno imediato é criar o arquivo com `{}` antes da primeira execução.
- `npm install --legacy-peer-deps` (nunca `npm ci`) é necessário quando `node_modules` estiver
  ausente — `package-lock.json` é intencionalmente gitignored pelo repo, e há conflito de peer
  dependency entre `cypress@15.14.2` (pinado) e `@badeball/cypress-cucumber-preprocessor@latest`.
- Observação em aberto, ainda não resolvida (desde 2026-09-14): branches remotas `esteiras` e
  `esteirasmop` apareceram em `repo/` sem aviso correspondente em `fila-merge/` nem subAgent
  próprio em `../subagents/`. Se aparecer um aviso de merge para essas branches, tratar como
  incerteza a esclarecer com o Supervisor antes de mexer.
