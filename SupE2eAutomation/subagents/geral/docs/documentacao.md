# Conhecimento acumulado do módulo geral

## Login via Keycloak (tarefa 20260911181703-login-keycloak-usuario-master)

- Implementado: `cypress/support/pages/shared/LoginPage.js` (Page Object puro dos seletores do
  Keycloak), `cy.loginComoPerfil(perfil)` e `cy.tentarLoginComCredenciais(username, password)` em
  `cypress/support/commands.js`, `cypress/config/environments.js` (mapa `usuarios` por perfil,
  ambiente `hml`, perfil `master` provisionado), `.env.example` com as variáveis novas, cenários
  em `cypress/e2e/features/shared/login.feature` + `cypress/support/step_definitions/shared/login.js`.
  `@badeball/cypress-cucumber-preprocessor` instalado e configurado (`cypress.config.js` +
  `package.json`).
- **Gotcha de `cy.session`**: o setup/`validate()` do `cy.session` só restabelece
  cookies/localStorage — ao final, o Cypress limpa a página para `about:blank`. Sem um `cy.visit`
  extra logo após o `cy.session`, a asserção de "autenticado com sucesso" falha (URL fica em
  `about:blank`) mesmo com a sessão válida. `cy.loginComoPerfil` já faz esse `cy.visit` adicional —
  manter esse padrão em qualquer novo comando de login/sessão.
- Credencial do perfil `master` em HML: usuário `automacao`, senha `Automacao@123` (atenção à
  capitalização do "A" — a variação em minúsculo (`automacao@123`) causa `invalid_grant` no
  Keycloak, sem relação com bug de seletor/implementação).
- Perfis `operador`/`aprovador`/etc. ainda não provisionados em HML — dependência externa
  conhecida, documentada também no `CLAUDE.md` do repo; tratar em tarefas futuras à medida que
  novos usuários forem criados.
- Branch `feature/login-keycloak-usuario-master` commitada, pushada e aviso deixado em
  `agent-master/fila-merge/pendentes/` para merge em `reviewAgents`.

## Concluído: erro "Cypress.env() was removed in Cypress version 16.0.0" (tarefa 20260911194503-correcao-cypress-env-removido)

- **Não é um bug do código do projeto.** `cypress/config/environments.js` usa `Cypress.env(...)`,
  que na versão instalada (15.20.1, tanto em `repo/` quanto em `C:\multiplica\cypress-e2e`) está
  apenas `@deprecated` (ver `node_modules/cypress/types/cypress.d.ts`), não removida — a API
  ainda funciona normalmente. Nenhum arquivo do pacote `cypress` 15.20.1 instalado contém a string
  de erro "was removed in Cypress version" em lugar nenhum (runtime ou tipos).
- `npx cypress version` rodado agora em `C:\multiplica\cypress-e2e` confirma package **e** binary
  em 15.20.1, sem reproduzir o erro — ou seja, o estado atual está consistente.
- **Achado-chave**: o cache de binários do Cypress é **global por usuário do Windows**
  (`%LOCALAPPDATA%\Cypress\Cache`), compartilhado por *todos* os projetos Cypress da máquina (não
  é por-repo). Nesse cache havia, além de `15.14.2` e `15.20.1`, uma pasta `16.0.0` criada
  11/09/2026 19:32 — cerca de 13 minutos antes do horário em que a falha foi reportada (19:45).
  `16.0.0` é exatamente a versão citada na mensagem de erro. Hipótese mais provável: o
  `npx cypress open` manual do Thiago rodou concorrente com algum processo que baixou/instalou
  Cypress 16.x nessa mesma máquina (possivelmente o `npm ci`/`npm install` automático do Agent
  Master na sincronização da pasta de teste manual — CLAUDE.md seção 3.3 item 5), deixando
  `node_modules/cypress` num estado transitório que resolveu o binário 16.0.0 por engano naquele
  instante. Nenhum `package.json` do repo (subagents/geral/repo ou cypress-e2e) declara Cypress
  >=16 — o pin continua `^15.14.2` em ambos.
- Achado à parte: no momento desta investigação **não existe `.env`** em
  `C:\multiplica\cypress-e2e` — a pasta de teste manual do Thiago está sem esse arquivo (fora do
  escopo do subAgent mexer nele, conforme regra do Agent Master).
- **Resposta do Thiago**: confirmado que foi ele mesmo quem rodou `npx cypress open` manualmente
  em `cypress-e2e` e aceitou a instalação do Cypress 16.0.0 quando o npx perguntou — sem relação
  com o `npm ci`/`npm install` automático do Agent Master. Não há bug de compatibilidade real no
  `Cypress.env()`/`environments.js` — não trocar por `cy.env()`/`Cypress.expose()`. A correção
  aprovada foi pinar a versão do Cypress no `package.json`. Sobre o `.env` ausente em
  `cypress-e2e`: passou a ser responsabilidade do Agent Master (sincronização automática do
  `.env` na regra 3.3.5), não do subAgent `geral`.
- **Correção aplicada**: pin exato `"cypress": "15.20.1"` em `package.json` (era `^15.14.2`) +
  `package-lock.json` regenerado via `npm install --package-lock-only`. Isso elimina a
  possibilidade de `npm ci`/`npm install` resolver acidentalmente uma versão >=16 nesse projeto,
  mesmo que o cache global do Windows tenha outras versões instaladas.
- **Achado extra durante o autoteste de `npx cypress open`**: mesmo na 15.20.1, ao usar
  `Cypress.env()` a interface mostra o aviso `allowCypressEnv... Cypress.env() será removido em
  versão futura major` — ou seja, a depreciação é real e teria que ser endereçada (migrar para
  `cy.env()`/`Cypress.expose()`) antes de eventualmente atualizar para Cypress 16.x no futuro.
  Não é bloqueante agora (Thiago já validou não mexer nisso nesta tarefa), mas registrar como
  trabalho pendente conhecido para quando a atualização para Cypress 16 for cogitada.
- **Autoteste**: `npx cypress run --spec cypress/e2e/features/shared/login.feature` passou 2/2 em
  execuções consecutivas (uma tentativa isolada teve falha transiente de rede no `cy.origin()` ao
  abrir o Keycloak — não relacionada à mudança, não voltou a ocorrer). `npx cypress open` não
  reproduz mais o erro "was removed".
- Branch `fix/pin-cypress-versao-15.20.1` commitada, pushada, e aviso deixado em
  `agent-master/fila-merge/pendentes/` para merge em `reviewAgents`.

## Concluído: docs do repo desatualizadas sobre fluxo de integração (tarefa 20260914125955-atualizar-claude-md-fluxo-integracao)

- `repo/CLAUDE.md` (seção "## Collaboration workflow" + frase em "## Project overview") e
  `repo/README.md` (seção "## Fluxo de trabalho") ainda descreviam o modelo antigo — PR por tarefa
  (`feature/xxx → reviewAgents`), aprovado manualmente pelo Thiago um a um, com a frase "The Agent
  Master never merges or pushes directly to `reviewAgents` or `main`". Esse texto nunca tinha sido
  corrigido desde a mudança de fluxo de 2026-09-14 (merge direto na `reviewAgents` + PR único
  contínuo `reviewAgents → main`) — já havia sido sinalizado como risco em
  `../../docs/conhecimento-geral.md`.
- Corrigido em ambos os arquivos para descrever o fluxo atual: Agent Master mergeia direto (com
  push) na `reviewAgents` por tarefa validada, sem PR/aprovação humana por tarefa; único ponto de
  revisão manual passa a ser o PR único e contínuo `reviewAgents → main`.
- Tarefa só de documentação — sem mudança de código/teste. Autoteste = revisão de consistência do
  texto contra `SupE2eAutomation/CLAUDE.md` (seção 3.3) e `docs/conhecimento-geral.md`.
- Branch `feature/atualizar-claude-md-fluxo-integracao` commitada, pushada, e aviso deixado em
  `agent-master/fila-merge/pendentes/` para merge em `reviewAgents`.

## Concluído: viewport 1920x1080 + vídeo de execução (tarefa 20260914130450-resolucao-viewport-e-video-execucao)

- `cypress.config.js` (bloco `e2e`) define explicitamente `viewportWidth: 1920`,
  `viewportHeight: 1080` e `video: true` (antes ficava no default do Cypress instalado).
- **Achado principal**: a resolução do `.mp4` gravado em `cypress/videos/` **não** corresponde ao
  viewport configurado — não é bug corrigível via `cypress.config.js` (a captura de vídeo é um
  pipeline interno separado da renderização do viewport; `node_modules/cypress/types/cypress.d.ts`
  só expõe `video`/`videoCompression`/`videosFolder`, nenhuma opção de resolução). Medido lendo o
  box `tkhd` do `.mp4` diretamente (sem `ffprobe` disponível na máquina):
  - Electron headless (`npm test`/`cypress run` padrão, o que qualquer Scheduled Task usa): **1280x720**.
  - Chrome headless (`--browser chrome --headless`): **1264x624**.
  - Electron `--headed` (só manual): **1920x982** (largura bate, altura varia por decoração de
    janela/DPI).
- **Decisão do Thiago** (via `duvidas.md`): considerar a tarefa concluída assim mesmo — o viewport
  1920x1080 segue correto e é o que importa pro app renderizar certo durante o teste; a resolução
  menor do vídeo em modo headless é uma limitação conhecida do Cypress, não vale a pena investigar
  mais fundo. Documentar a tabela acima em vez de tentar corrigir.
- Documentado em `README.md` (seção "Rodando os testes") e `CLAUDE.md` do repo, e também em
  `../../docs/conhecimento-geral.md` (aprendizado cross-módulo — qualquer módulo que grave vídeo
  headless tem a mesma limitação).
- **Autoteste**: `npx cypress run --spec cypress/e2e/features/shared/login.feature` rodado 2x. 1ª
  execução teve 1 falha transiente de rede no `cy.origin()` (já documentado como intermitente,
  não relacionado a esta mudança). 2ª execução passou 2/2. `.mp4` gerado normalmente em
  `cypress/videos/` em ambas.
- Branch `feature/resolucao-viewport-e-video-execucao` (commits `792e06f` + `45fb200`) commitada,
  pushada, e aviso deixado em `agent-master/fila-merge/pendentes/` para merge em `reviewAgents`.

## Concluído: relatório em PDF substitui vídeo (tarefa 20260917111432-migrar-video-para-relatorio-pdf)

- `cypress.config.js`: `video: false` (era `true`). `cypress/support/etapas/EtapaBase.js` ganhou
  `this.passo(descricao, acao)` — tira `cy.screenshot` antes/depois de `acao()`, com nome de
  arquivo `<cenario-slug>__<NN>-<passo-slug>-<antes|depois>.png` (`<cenario-slug>` vem de
  `Cypress.currentTest.title`, confiável porque o cucumber-preprocessor roda cada Cenário como um
  `it()` do Mocha). `EtapaAnalisarOperacaoMonitorDiario` (mop) migrada como exemplo de referência.
- Novo `scripts/gerar-relatorio-pdf.cjs` (dependência nova `pdfkit@0.20.2`, em `dependencies`)
  agrupa os screenshots por cenário e gera `relatorios/<cenario>.pdf` (uma página por screenshot,
  com legenda do passo). Rodado automaticamente após `cypress run` via `"test": "cypress run &
  node scripts/gerar-relatorio-pdf.cjs"` — `&` (não `&&`) para o PDF sair mesmo quando a suíte
  falha, já que os screenshots tirados antes da falha ainda são úteis. Também disponível via
  `npm run relatorio` (útil pra regenerar sem re-rodar a suíte).
- **Avaliado `cypress-mochawesome-reporter` antes de implementar do zero** (pedido explícito da
  tarefa): ele gera relatório HTML com screenshots embutidos, não PDF — converter pra PDF exigiria
  um passo extra (ex.: Puppeteer print-to-PDF), dependência mais pesada que só gerar o PDF direto
  com `pdfkit`, e não mapeia bem o par "antes/depois" pedido. Optado pelo script customizado.
  Decisão registrada aqui e no `CLAUDE.md` do repo — não foi levada como dúvida ao Supervisor por
  não ser bloqueante (a própria tarefa já sugeria essa avaliação e aceitava a alternativa).
- `relatorios/*.pdf` **não entrou no `.gitignore`** (decisão: versionar, seguindo a recomendação
  já dada na própria tarefa — PDF é leve, diferente do vídeo). `cypress/screenshots/` e
  `cypress/videos/` seguem gitignored (vídeo só não é mais gerado, entrada ficou inofensiva).
- `CLAUDE.md` (nova seção "PDF execution report", linha "Fora de escopo" atualizada) e `README.md`
  (seção "Rodando os testes") atualizados descrevendo o novo mecanismo.
- **Autoteste**: `npm test` rodado 2x contra HML — ambas esbarraram em instabilidade de
  login/HML já catalogada em `../../docs/conhecimento-geral.md` (não relacionada a esta mudança):
  1ª tentativa chegou a capturar 1 screenshot real via `passo()` (step "navegar até o Monitor
  Diário") e gerou 1 PDF real antes de falhar num clique de menu coberto por um `MuiBackdrop`
  (sintoma novo, não catalogado antes, ver nota em `conhecimento-geral.md`); 2ª tentativa falhou
  já no login/sessão (`cy.session` setup, keycloak não redirecionou a tempo). Não retentei uma 3ª
  vez seguida (protocolo já estabelecido). Para validar a lógica do script (agrupamento/ordenação
  por passo, múltiplas páginas) sem depender do HML, gerei screenshots sintéticos (3 passos x
  antes/depois) e rodei `npm run relatorio` — PDF de 6 páginas gerado corretamente; removido depois
  (não commitado, só serviu de verificação).
- Branch `feature/migrar-video-para-relatorio-pdf` commitada, pushada, aviso deixado em
  `agent-master/fila-merge/pendentes/`.

## Descartado (sem merge): reverter handler de ResizeObserver (tarefa 20260915110528-reverter-handler-resizeobserver)

- A tarefa pedia remover, do handler de `uncaught:exception` em `cypress/support/e2e.js`, a
  checagem específica de `ResizeObserver loop completed with undelivered notifications`
  (introduzida no commit `a2f2d88`, tarefa `20260914130450-resolucao-viewport-e-video-execucao`),
  mantendo intacto o tratamento do erro conhecido do widget de menu do Beyond
  (`Cannot read properties of undefined (reading 'content')`).
- **A reversão foi implementada e funcionou tecnicamente**: branch
  `feature/reverter-handler-resizeobserver`, commit `2866b45`, partindo da `reviewAgents`
  atualizada (`9f38a75`). Autoteste (`mop/mop-monitor-diario.feature`) confirmou que, sem o
  handler, o `ResizeObserver loop completed with undelivered notifications` volta a derrubar o
  teste normalmente (0 passing / 1 failing) no cenário "Analisar uma operação que não está em
  Inclusão OPE", em `https://beyond-hml.grupomultiplica.com.br/mop/monitor` — ou seja, esse erro
  continua ocorrendo de verdade na tela do Monitor Diário do MOP; só deixou de ser mascarado.
- **Decisão do Thiago (via `duvidas.md`): descartar a reversão.** O mascaramento introduzido no
  commit `a2f2d88` permanece valendo — não houve mudança de comportamento. Motivo: remover o
  handler não corrige a causa raiz (o ResizeObserver na tela do Monitor Diário), só volta a expor
  uma falha de teste já existente; sem uma correção real da causa pronta, o Thiago preferiu manter
  o teste passando (erro mascarado) a deixá-lo falhando.
- Branch `feature/reverter-handler-resizeobserver` (commit `2866b45`) **abandonada localmente, sem
  push e sem aviso em `agent-master/fila-merge/pendentes/`** — não há nada para mergear. Repo
  voltou para `reviewAgents`.
- Se a causa raiz do ResizeObserver no Monitor Diário do MOP for investigada/corrigida de verdade
  no futuro, deve virar uma tarefa nova (do módulo `mop`, já que é específica dessa tela) — não
  reaproveitar esta.
