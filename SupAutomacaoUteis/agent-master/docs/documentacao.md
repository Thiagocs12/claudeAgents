# Conhecimento acumulado do Agent Master

> Histórico completo de ciclos anteriores (2026-09-14 a 2026-09-15) arquivado em
> `documentacao-historico.md` — consulte lá para detalhes de cada merge/ciclo passado. Este
> arquivo mantém só o resumo do que ainda é operacionalmente relevante.

## Estado atual (atualizado no ciclo de 2026-09-15 — merge de `keycloakUser/nao-quebrar-parametros-clonagem-unica-ausentes`)

- **PR único de integração contínua `reviewAgents → master`**: **PR #7**
  (https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/7), aberto. Substituiu o **PR #6**,
  que o Thiago mergeou manualmente em `2026-09-15T14:38:34Z` (primeira vez que isso aconteceu —
  ver "Decisões de processo" abaixo). Não recriar enquanto #7 continuar aberto.
- **Último commit mergeado em `reviewAgents`**: `f4c41cf` (tarefa `keycloakUser/nao-quebrar-parametros-clonagem-unica-ausentes`).
  Histórico de commits anteriores: `ef441f7` (PR #5) → `78ea304` (`clonar-usuarios-em-lote`) →
  `a1de77b` (`normalizar-case-usuario-minusculas`) → `c9bf535` (`remover-clonados-fixture...`) →
  `f4c41cf` (atual).
- **`fila-merge/aguardando-aprovacao/`** (modelo antigo de PR-por-tarefa): vazio, legado 100%
  processado (só resta histórico em `fila-merge/concluidos/`). Nenhum aviso novo deve passar por
  ali — modelo abandonado.
- **`.env` / `.env.example`**: nenhuma variável nova foi introduzida em nenhum merge até agora
  (todos os diffs de `.env.example` vieram vazios). `repo/.env` e o `.env` de
  `C:\multiplica\cypress-uteis` seguem idênticos em nomes de variável — nenhuma variável pendente
  de valor conhecido no momento.
- **`GH_TOKEN`**: funcionando normalmente desde o ciclo de 2026-09-14 que confirmou a correção
  (Thiago gerou PAT novo). Bloqueio anterior (~8 ciclos consecutivos de token inválido) está
  encerrado — detalhes só no histórico.
- **Sincronização da pasta manual** (`C:\multiplica\cypress-uteis`): mantida na branch
  `reviewAgents`, sincronizada até o commit `f4c41cf`. Há (desde 2026-09-15) uma alteração **não
  commitada do Thiago** em `cypress/fixtures/usuariosParaClonar.json` (dado pessoal de teste) —
  preservada intencionalmente, nenhum merge até agora tocou esse arquivo. `node_modules` presente
  nessa pasta, sem necessidade de reinstalar.

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
