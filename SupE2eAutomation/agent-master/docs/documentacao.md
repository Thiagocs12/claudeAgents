# Conhecimento acumulado do Agent Master

> **Nota (2026-09-15):** este arquivo foi compactado pelo Supervisor a pedido do Thiago — o
> histórico tinha ~1780 linhas, a maior parte ciclos de rotina idênticos ("nada a fazer",
> repetidos dezenas de vezes) que só confirmavam o mesmo estado sem informação nova. Todo conteúdo
> com valor de conhecimento foi preservado abaixo, reorganizado por tema em vez de ciclo a ciclo.

## Fluxo de integração — histórico de merges e PRs

- **2026-09-11 — `feature/login-keycloak-usuario-master`** (módulo `geral`): fast-forward em
  `reviewAgents` (`0492943 → e3f5ae9`), sem conflito. Integrou a fundação de login via Keycloak
  (`LoginPage`, `cy.loginComoPerfil`, `environments.js`/`.env.example`, cenários Cucumber).
  `.env.example` trouxe 4 variáveis novas, já preenchidas em `repo/.env`. Testes pós-merge: 2/2
  passando (1ª execução teve falha isolada de rede no `cy.origin`, não reproduzida na 2ª).
- **2026-09-11 — `fix/pin-cypress-versao-15.20.1`** (módulo `geral`): merge `--no-ff`
  (`cc85538 → b7afaf9`). Corrige o erro "Cypress.env() was removed in Cypress version 16.0.0" do
  teste manual, pinando `"cypress": "15.20.1"` exato no `package.json` (causa raiz: cache global de
  binários do Cypress por usuário do Windows, não bug de código). Testes 2/2 passando.
- **2026-09-14 — PR #9** (`feature/mop-monitor-diario-analisar-operacao`, módulo `mop`, modelo
  antigo de PR-por-tarefa): aberto, testado (`mop-monitor-diario.feature` 1/1,
  `shared/login.feature` 2/2 de regressão), depois **MERGED** pelo Thiago em 2026-09-14. Processado
  como legado (fast-forward `69cc6cd → cab0630` no fetch/pull local).
- **2026-09-14 — mudança de fluxo:** de "PR por tarefa aprovado manualmente" para "merge direto na
  `reviewAgents` + PR único e contínuo `reviewAgents → main`" (pedido explícito do Thiago). PR #10
  criado no primeiro ciclo do novo fluxo (resumindo 5 commits pendentes), mergeado pelo Thiago no
  mesmo dia. PR #11 criado em seguida (4 commits: viewport/vídeo config, docs de fluxo, fix do
  handler `ResizeObserver`, merge commit) — **estado no momento desta compactação (2026-09-15):
  ainda OPEN**, refletindo automaticamente qualquer commit novo pushado em `reviewAgents`; não deve
  ser recriado enquanto continuar aberto.
- **Discrepância de docs do repo corrigida:** `repo/CLAUDE.md`/`repo/README.md` tinham ficado
  descrevendo o modelo antigo (PR por tarefa) mesmo depois da mudança de fluxo — corrigido pela
  tarefa `20260914125955-atualizar-claude-md-fluxo-integracao` do módulo `geral` (ver seção
  "Tarefa bloqueada" abaixo — o merge dessa correção ficou preso por causa do teste flaky do MOP).

## Incidente de segurança — `GH_TOKEN` exposto em log (2026-09-14)

Um comando de diagnóstico rodado por erro de quoting ecoou o valor completo do `GH_TOKEN` em
`agent-master/run-log.txt` (log em tempo real do `stream-json`). Ações tomadas: (a) confirmado que
a exposição ficou isolada a esse arquivo (busca em todo `C:\Multiplica\claudeAgents`); (b) valor
redigido em `run-log.txt` (substituído por `[REDACTED-GH-TOKEN-2026-09-14]`, histórico do arquivo
preservado). **Pendente:** a rotação do token em si (revogar o antigo e gerar um novo no GitHub) é
responsabilidade exclusiva do Thiago e não foi confirmada como feita em nenhum registro posterior
— tratar como prioridade caso ainda não tenha sido rotacionado.

## Handler de `uncaught:exception` em `cypress/support/e2e.js` — histórico

- Erro do widget de menu do Beyond (`Cannot read properties of undefined (reading 'content')`):
  tratado desde a implementação original do módulo `mop` (commit `a83b438`) — nunca alterado desde
  então.
- Erro `ResizeObserver loop completed with undelivered notifications` (Monitor Diário do MOP):
  descoberto durante testes de 2026-09-14, inicialmente tratado como dúvida bloqueante (branches
  só-docs sendo bloqueadas por falha de um teste que não tocavam). Thiago autorizou estender o
  handler para ignorá-lo também (commit `a2f2d88`, mesmo padrão do widget do Beyond) — mudança
  incluída no PR #11.
- **2026-09-15:** Thiago pediu para reverter essa extensão (achava que o mascaramento causava
  quebras "sem mais nem menos"). SubAgent `geral` reverteu (branch
  `feature/reverter-handler-resizeobserver`, commit `2866b45`) e confirmou via autoteste que, sem o
  handler, `mop-monitor-diario.feature` volta a falhar de verdade (o `ResizeObserver` continua
  ocorrendo na tela — o handler só escondia isso). Depois de entender essa implicação, Thiago
  decidiu **manter o handler como estava** (mascarando o erro) — a branch de reversão deve ser
  abandonada, sem merge. Ver `subagents/geral/duvidas.md` para o registro completo.

## Tarefa bloqueada — `atualizar-claude-md-fluxo-integracao` (módulo `geral`)

Branch só de documentação, bloqueada repetidamente porque `mop-monitor-diario.feature` falhava no
merge de teste preventivo — com sintomas variados ao longo das tentativas (`cy.origin() failed to
create a spec bridge`, timeout de carregamento de página, `ResizeObserver loop...`), enquanto
`shared/login.feature` nunca falhou nos mesmos ciclos. Isso aponta para um problema específico
daquele teste/tela, não instabilidade genérica do HML (ver também
`../subagents/geral/docs/documentacao.md`).

- 2026-09-14: Thiago disse que investigaria a causa raiz por conta própria e instruiu **não
  reprocessar automaticamente** este aviso até trazer uma decisão nova via Supervisor.
- 2026-09-15: essa instrução, combinada com a pré-checagem da seção 3.4 (que só olha existência de
  arquivo em `pendentes/`), gerou **~28 ciclos de rotina idênticos** num único dia — o Agent Master
  confirmando repetidamente "nada mudou" sem gastar trabalho real, mas consumindo invocação/
  rate-limit à toa a cada ciclo. Resolvido movendo o aviso para uma pasta nova,
  `fila-merge/pausados/` (fora do escopo da pré-checagem), decisão tomada pelo Supervisor a pedido
  do Thiago — nenhuma mudança de lógica no `run-cycle.ps1`.
- 2026-09-15 (mais tarde): Thiago autorizou liberar o item de volta para `fila-merge/pendentes/`
  (Supervisor moveu de volta, com instrução registrada em `duvidas.md` deixando claro que é só
  autorização para tentar de novo esse item específico — a pergunta de política sobre tolerar falha
  do `mop-monitor-diario.feature` em merges só-docs/config segue **em aberto**).
- 2026-09-15 ("retomada 2"): reprocessado — merge de teste local limpo de novo (`e1d0437`, sem
  conflito, sem variável de `.env`/pacote novo). `npm test` rodado uma única vez:
  `shared/login.feature` 2/2, mas `mop/mop-monitor-diario.feature` falhou com um **terceiro sintoma
  ainda não catalogado**: `CypressError: Timed out retrying after 4050ms: cy.click() failed because
  this element is disabled` (botão `Mui-disabled` na tela "Analisar uma operação que não está em
  Inclusão OPE") — diferente do `cy.origin()`/spec bridge e do `ResizeObserver` já vistos. Diferença
  importante: os dois primeiros ocorriam durante o login (compatível com instabilidade de
  rede/Keycloak); este ocorre **depois** do login, numa interação de UI dentro da própria tela —
  indício mais forte de um problema real de timing/estado da aplicação ou do teste, não de
  flakiness genérica de ambiente (ver `../subagents/geral/docs/documentacao.md` para o registro
  completo).
  Merge local desfeito de novo, aviso mantido em `fila-merge/pendentes/`. **Nova dúvida bloqueante
  pendente** (`duvidas.md`, `20260914125955-atualizar-claude-md-fluxo-integracao (retomada 2)`,
  `Status: pendente`) perguntando como proceder.
- **2026-09-15 (encerramento):** Thiago decidiu abandonar esta tentativa de merge de vez ("reverta
  tudo, a `reviewAgents` já funciona, não tem por que mergear nada") — confirmou também que o único
  PR que segue sendo mantido é o contínuo `reviewAgents → main` (automático, sem ação extra). Aviso
  movido de `fila-merge/pendentes/` para `fila-merge/concluidos/`, marcado explicitamente como
  **descartado sem merge** (não confundir com os demais itens de `concluidos/`, que foram merges
  bem-sucedidos). `reviewAgents` permanece sem essa mudança; a branch remota
  `feature/atualizar-claude-md-fluxo-integracao` continua existindo, sem uso previsto. Efeito
  colateral: `repo/CLAUDE.md`/`repo/README.md` seguem desatualizados quanto ao fluxo de integração
  vigente (retomar isso exigiria decisão nova do Thiago). A pergunta de política mais ampla (tolerar
  falha de `mop-monitor-diario.feature` em merges só-docs) fica sem objeto para este item, mas segue
  em aberto para casos futuros.

## Armadilhas operacionais conhecidas

- **BOM UTF-8 em `.gh-token`:** ler o token via `cat`/`tr` cru (bash) não remove o BOM e causa
  `401 Bad credentials` no `gh`. Usar PowerShell `Get-Content -Raw` + `.Trim()` (o que
  `run-cycle.ps1` já faz corretamente). Confirmado repetidas vezes em diagnósticos manuais.
- **`GH_TOKEN` já vem setado pelo `run-cycle.ps1`** antes do `claude -p` iniciar — nunca precisa
  (nem deve) ser relido/re-derivado manualmente dentro de um ciclo.
- **Checkout local de `main` pode ficar obsoleto sem ninguém perceber**, já que o Agent Master
  nunca faz checkout dela — `git fetch` atualiza `origin/main` mas não avança o ponteiro local.
  Sempre confirmar `git merge-base --is-ancestor main origin/main` (e `git branch -f main
  origin/main` se precisar) antes de comparar `main..reviewAgents`.
- **Remote de `C:\multiplica\cypress-e2e` aponta pro nome antigo do repositório**
  (`automacaoMultiplica` em vez de `automacaoUiMultiplica`) — funciona hoje via redirect
  automático do GitHub (conteúdo confirmado idêntico), mas quebra se o nome antigo for reaproveitado
  no GitHub. Se algum agente notar erro de fetch/pull inesperado só nessa pasta, checar isso antes
  de tratar como bug.
- **Branch remota `docs/arquitetura-poc-mop`** apareceu no `git fetch --prune` em vários ciclos,
  sem nenhum aviso associado em `fila-merge/pendentes/` de nenhum módulo — não é papel do Agent
  Master agir sobre uma branch sem aviso correspondente; só registrar caso o Thiago pergunte ou um
  aviso apareça depois.

## Sincronização da pasta de teste manual (`C:\multiplica\cypress-e2e`)

Desde a mudança de fluxo (2026-09-14), essa pasta segue sempre a `reviewAgents` (não fica mais presa
a branch de PR por tarefa). A cada ciclo que sincroniza: `git pull origin reviewAgents`, `npm ci`
só se `package.json`/`package-lock.json` mudou, `.env` do Agent Master copiado por cima do `.env`
de lá, e vídeos de testes rodados no ciclo (`repo/cypress/videos/**`) copiados para
`cypress/videos/` dentro dessa pasta.

## Aviso bloqueado — `migrar-video-para-relatorio-pdf` (módulo `geral`, 2026-09-17)

- Aviso em `fila-merge/pendentes/` (`20260917111432-migrar-video-para-relatorio-pdf`,
  `feature/migrar-video-para-relatorio-pdf`). Merge de teste local limpo (sem conflito,
  fast-forward de um único commit sobre `9f38a75`). `.env.example` sem mudança (confirmado via
  diff). `package.json` trouxe dependência nova `pdfkit@0.20.2` — `npm install` rodado sem erro (19
  pacotes adicionados).
- `npm test` (2 specs) resultou em **2/2 specs falhando**, ambas no mesmo ponto (`cy.session`/
  `cy.loginComoPerfil`, submissão de credenciais no Keycloak nunca redirecionou de volta para
  `beyond-hml`, ficando presa na URL do Keycloak) — sintoma novo, não catalogado antes. Detalhe
  completo e evidência em `duvidas.md`/`../subagents/geral/docs/documentacao.md`. Merge local
  desfeito
  (`git reset --hard origin/reviewAgents`, `repo/` confirmado limpo). Aviso mantido em
  `fila-merge/pendentes/`, dúvida bloqueante registrada (`Status: pendente`). Nenhuma sincronização
  de `C:\multiplica\cypress-e2e` feita neste ciclo (nada foi mergeado em `reviewAgents`).

## Ciclos de rotina — resumo (compactado em 2026-09-15)

Entre 2026-09-14 e 2026-09-15, dezenas de ciclos (~30+) não encontraram nada para processar: PR #11
permaneceu `OPEN` o tempo todo, o único aviso em `pendentes/`
(`atualizar-claude-md-fluxo-integracao`) ficou parado por instrução explícita do Thiago, a fila de
legado (`fila-merge/aguardando-aprovacao/`) permaneceu vazia, e a pasta de teste manual já estava
sempre em dia. As entradas individuais e idênticas desses ciclos foram removidas nesta compactação
— nenhuma informação além da contagem de repetição em si foi perdida.

- **2026-09-15 (ciclo após a "retomada 2"):** mais um ciclo de rotina, sem trabalho novo. PR #11
  segue `OPEN` (reflete `9f38a75`, mesmo commit de `reviewAgents`/`main` locais e remotos, `main`
  local confirmado em dia com `origin/main`). Legado vazio. O único aviso em `pendentes/`
  (`20260914125955-atualizar-claude-md-fluxo-integracao`) segue com a dúvida "retomada 2" (terceiro
  sintoma do `mop-monitor-diario.feature`, botão `Mui-disabled`) com `Status: pendente` em
  `duvidas.md` — não reprocessado neste ciclo (aguardando resposta do Thiago, mesmo protocolo de
  não insistir sem instrução nova). `C:\multiplica\cypress-e2e` já estava no mesmo commit
  (`9f38a75`) e mesmo `.env` do Agent Master, working tree limpo — nenhuma sincronização/vídeo novo
  necessário (nenhum teste rodou neste ciclo).
- **2026-09-17 (ciclo de rotina):** nada novo. Legado (`fila-merge/aguardando-aprovacao/`) vazio.
  Único aviso em `pendentes/` (`20260917111432-migrar-video-para-relatorio-pdf`) segue bloqueado —
  dúvida em `duvidas.md` com `Status: pendente`, sem resposta nova do Thiago; não reprocessado
  (mesmo protocolo de não insistir sem instrução nova). `repo/` e `C:\multiplica\cypress-e2e` ambos
  em `9f38a75` (mesmo commit, working tree limpo, `.env` idênticos), `repo/relatorios/` ainda não
  existe (infra de PDF só chega com o merge deste mesmo aviso bloqueado) — nada para sincronizar
  neste ciclo. Confirmação/criação do PR único `reviewAgents → main` já é feita
  deterministicamente pelo `run-cycle.ps1` (função `Confirmar-PRUnico`) antes deste ciclo — não
  reconferida aqui.
- **2026-09-17 (ciclo seguinte):** mais um ciclo de rotina, sem trabalho novo. Legado vazio. Único
  aviso em `pendentes/` (`20260917111432-migrar-video-para-relatorio-pdf`) segue bloqueado — dúvida
  em `duvidas.md` com `Status: pendente`, sem resposta nova do Thiago; não reprocessado. `repo/` e
  `C:\multiplica\cypress-e2e` confirmados ambos em `9f38a75`, working tree limpo em ambos, `.env`
  idênticos (diff vazio) — nada para sincronizar. `repo/relatorios/` ainda não existe. **Achado
  potencialmente relevante para desbloquear esta dúvida:** `status-resumo.md` (seção `## POC`) e
  `../subagents/geral/docs/documentacao.md` registram, na mesma janela de tempo, um sintoma de
  login **diferente** mas correlato — o Keycloak rejeitando ativamente a credencial `automacao`
  ("usuário ou senha inválidos", não timeout/redirect) no módulo `POC`, com suspeita de senha
  rotacionada/expirada. O sintoma desta dúvida (redirect do Keycloak nunca completou, sem mensagem
  de rejeição) não é idêntico, mas ambos ocorrem no mesmo `cy.loginComoPerfil`/Keycloak
  compartilhado entre módulos — vale considerar como a mesma causa raiz (credencial ou
  intermitência do Keycloak em HML) ao decidir como proceder, em vez de tratar como dois problemas
  isolados.
- **2026-09-17 (ciclo seguinte, mais um):** sem trabalho novo. Legado vazio. Único aviso em
  `pendentes/` (`20260917111432-migrar-video-para-relatorio-pdf`) segue com `Status: pendente` em
  `duvidas.md`, sem resposta do Thiago; não reprocessado (mesmo protocolo). `repo/` e
  `C:\multiplica\cypress-e2e` confirmados no mesmo commit (`9f38a75`), working tree limpo em
  ambos, `.env` idênticos (diff vazio), `repo/relatorios/` ainda não existe — nada para
  sincronizar. PR único `reviewAgents → main` fica a cargo do `Confirmar-PRUnico` do
  `run-cycle.ps1`, não reconferido aqui.
- **2026-09-17 (ciclo seguinte, mais um ainda):** sem trabalho novo, estado idêntico ao ciclo
  anterior em tudo (legado vazio, aviso único em `pendentes/` ainda `Status: pendente` sem resposta
  nova, `repo/` e `C:\multiplica\cypress-e2e` ambos em `9f38a75` com working tree limpo e `.env`
  idênticos, `repo/relatorios/` ainda inexistente). Não reprocessado, mesmo protocolo.
- **2026-09-17 (ciclo seguinte, mais um ainda):** sem trabalho novo. Legado
  (`fila-merge/aguardando-aprovacao/`) vazio. Único aviso em `pendentes/`
  (`20260917111432-migrar-video-para-relatorio-pdf`) segue `Status: pendente` em `duvidas.md`, sem
  resposta nova do Thiago — não reprocessado (mesmo protocolo de não insistir sem instrução nova).
  Confirmado via `git rev-parse HEAD`: `repo/` e `C:\multiplica\cypress-e2e` ambos exatamente em
  `9f38a75` (igual a `origin/reviewAgents`), working tree limpo em ambos, `.env` idênticos (diff
  vazio), `repo/relatorios/` ainda inexistente — nada para sincronizar. PR único
  `reviewAgents → main` fica a cargo do `Confirmar-PRUnico` do `run-cycle.ps1`, não reconferido
  aqui.
