## 20260911181703-login-keycloak-usuario-master
Status: respondida
Pergunta: A implementação do login (LoginPage, `cy.loginComoPerfil`, environments.js, .env.example, feature + step definitions, cucumber-preprocessor) está pronta e o autoteste do cenário de credenciais inválidas passa. O cenário de credenciais válidas falha porque o Keycloak real rejeita o usuário master informado na tarefa (`automacao` / `automacao@123`, ambiente HML, realm `multiplicacapital`, client_id `autenticacao`) com `invalid_grant: Invalid user credentials` — confirmado tanto pela UI quanto diretamente no endpoint de token do Keycloak (fora do Cypress), então não é bug de seletor/implementação. Pode confirmar o usuário/senha corretos do perfil master em HML (ou se a conta precisa de reset/ativação)?
Resposta: A senha estava errada por causa da capitalização. É "Automacao@123" (A maiúsculo), usuário continua "automacao". Atualize o valor usado pelo perfil master e retome a tarefa.

## 20260911194503-correcao-cypress-env-removido
Status: respondida
Pergunta: Investiguei a causa raiz do erro "Cypress.env() was removed in Cypress version 16.0.0" no teste manual de `C:\multiplica\cypress-e2e` e não é um bug do código do projeto: (1) o `environments.js` usa `Cypress.env(...)`, que na 15.20.1 instalada (repo e cypress-e2e) está só `@deprecated`, não removida — a string de erro "was removed in Cypress version" não existe em lugar nenhum do pacote `cypress` 15.20.1; (2) rodando `npx cypress version` agora em `C:\multiplica\cypress-e2e`, package e binary batem em 15.20.1, sem reproduzir o erro; (3) o cache de binários do Cypress é global por usuário do Windows (`%LOCALAPPDATA%\Cypress\Cache`, compartilhado por todos os projetos da máquina) e continha uma pasta `16.0.0` criada às 19:32 de hoje, ~13min antes do horário em que você reportou a falha (19:45) — exatamente a versão citada no erro. Nenhum `package.json` do repo declara Cypress >=16. Minha hipótese: o `npx cypress open` manual rodou concorrente com algum processo que baixou Cypress 16.x nessa máquina (possivelmente o `npm ci`/`npm install` automático do Agent Master ao sincronizar essa pasta, CLAUDE.md 3.3.5), deixando `node_modules/cypress` num estado transitório que resolveu o binário 16.0.0 por engano naquele instante. Preciso confirmar: (a) você rodou/instalou Cypress 16.x manualmente nessa máquina perto desse horário (outro projeto/teste avulso)? (b) você concorda que a correção correta é isolar o cache de binário do Cypress por projeto (`CYPRESS_CACHE_FOLDER` dedicado ao repo, evitando esse compartilhamento entre execuções concorrentes), em vez de trocar `Cypress.env()` por `cy.env()`/`Cypress.expose()` no código (que não é a causa real)? Achado à parte: não existe `.env` em `C:\multiplica\cypress-e2e` agora — é esperado (ainda não recriado) ou foi apagado sem querer?
Resposta: Confirmado — foi o próprio Thiago rodando `npx cypress open` manualmente em
`C:\multiplica\cypress-e2e` sem o Cypress ainda resolvido localmente; o npx perguntou "Need to
install cypress@16.0.0" e ele aceitou (`y`), instalando a 16.0.0 no cache global e é isso que
gerou o erro — não tem relação com o `npm ci`/`npm install` automático do Agent Master. Então:
não há bug de compatibilidade real para corrigir no `Cypress.env()`/`environments.js` — não
precisa trocar por `cy.env()`/`Cypress.expose()`. Pode ajustar/pinar a versão do Cypress no
`package.json` do repositório se isso ajudar a evitar esse tipo de instalação acidental futura
(ex.: versão exata sem `^`, garantindo que `npm ci` sempre resolva a versão certa antes de
qualquer `npx cypress open`) — fique à vontade para mudar a versão, não tem problema. Sobre o
`.env` ausente: não se preocupe mais com isso nesta tarefa — configurei o Agent Master (regra 5
do `AGENTE.md` dele) para copiar automaticamente o `.env` dele para `C:\multiplica\cypress-e2e`
toda vez que sincronizar essa pasta após um merge, então isso passa a ser responsabilidade do
Agent Master, não do subAgent `geral`. Ajuste o que fizer sentido no `package.json` (pin de
versão do Cypress) e feche a tarefa — atualize `docs/documentacao.md` com o que foi aprendido
(cache global do Cypress por usuário, cuidado ao usar `npx cypress open` num projeto sem
`node_modules` populado).

## 20260914130450-resolucao-viewport-e-video-execucao
Status: respondida
Pergunta: Já configurei `viewportWidth: 1920`, `viewportHeight: 1080` e `video: true` no bloco
`e2e` de `cypress.config.js` (branch `feature/resolucao-viewport-e-video-execucao`, commit
`792e06f`), documentei em `README.md`/`CLAUDE.md` que as execuções gravam vídeo em
`cypress/videos/`, e rodei `npx cypress run --spec cypress/e2e/features/shared/login.feature`
várias vezes pra confirmar. O autoteste funcional passa 2/2 sempre e o `.mp4` é gerado
normalmente — mas descobri que **a resolução do vídeo gravado não bate com o viewport
configurado**, e isso não é algo que dá pra corrigir só via `cypress.config.js` (o Cypress não
expõe nenhuma opção de config para resolução de vídeo — só `video`/`videoCompression`/
`videosFolder`, conferido em `node_modules/cypress/types/cypress.d.ts`; a captura de vídeo é um
pipeline interno separado da renderização do viewport). Medi a resolução real de cada `.mp4`
lendo o box `tkhd` do MP4 diretamente (sem `ffprobe` disponível na máquina):
- Electron headless (`cypress run` padrão, é o que qualquer Scheduled Task automatizada usa):
  vídeo saiu em **1280x720**, não 1920x1080.
- Chrome headless (`--browser chrome --headless`): vídeo saiu em **1264x624**.
- Electron **headed** (`--headed`, só rodei manualmente pra comparar): vídeo saiu em **1920x982**
  — largura bate, altura não (provavelmente decoração da janela/DPI).
Ou seja: no modo que as automações de verdade usam (headless), o vídeo que você receberia pra
assistir sai bem menor que Full HD, apesar do `cypress.config.js` estar correto. Como quer
proceder? (a) considerar a tarefa concluída assim mesmo — o `viewportWidth`/`viewportHeight`
seguem corretos e explícitos (é o app/DOM que renderiza em 1920x1080 durante o teste, só a
gravação do vídeo em si que sai numa resolução menor por limitação do Cypress), documentando essa
limitação; (b) pedir que eu investigue mais fundo uma forma de forçar o vídeo a sair em Full HD
mesmo headless (não confirmei se é possível — pode não ser suportado pelo Cypress); ou (c) outra
prioridade que prefira.
Resposta: Opção (a) — considere a tarefa concluída assim mesmo. O viewport (1920x1080) segue
correto e é o que importa pro app renderizar certo durante o teste; a resolução menor do .mp4 em
modo headless é uma limitação conhecida do Cypress, não vale a pena investigar mais fundo agora.
Documente essa limitação (viewport configurado x resolução real do vídeo por modo/browser,
conforme a tabela que você já levantou) em docs/documentacao.md e no README.md/CLAUDE.md do repo,
feche a tarefa.

## 20260915110528-reverter-handler-resizeobserver
Status: respondida
Pergunta: Revertido o handler de `uncaught:exception` em `cypress/support/e2e.js`: removida a
checagem específica de `ResizeObserver loop completed with undelivered notifications` (introduzida
no commit `a2f2d88`), mantendo intacto o tratamento do erro conhecido do widget de menu do Beyond
(`Cannot read properties of undefined (reading 'content')`) — branch
`feature/reverter-handler-resizeobserver`, commit `2866b45`, partindo da `reviewAgents` atualizada
(`9f38a75`). Autoteste pedido pela tarefa (`mop/mop-monitor-diario.feature`) rodado uma única vez:
**falhou** com exatamente o sintoma esperado —
`Error: The following error originated from your application code, not from Cypress. >
ResizeObserver loop completed with undelivered notifications.`, disparado em
`https://beyond-hml.grupomultiplica.com.br/mop/monitor`, teste "Analisar uma operação que não está
em Inclusão OPE" (0 passing / 1 failing, ~35s). Ou seja: a reversão funcionou como pedido — o erro
volta a derrubar o teste normalmente, sem mascarar — mas isso significa que
`mop-monitor-diario.feature` deixa de passar nesse estado (o `ResizeObserver` segue ocorrendo de
verdade nessa tela, só que agora não é mais ignorado). A tarefa pede explicitamente para registrar
como dúvida bloqueante nesse caso, sem decidir sozinho re-adicionar o handler nem mascarar o erro
de novo. Como prefere proceder: (a) considerar a reversão do handler concluída mesmo assim (branch
pronta para merge) e tratar a falha do `mop-monitor-diario.feature` como um problema separado, a
ser corrigido na origem (ex.: investigar por que a tela do Monitor Diário do MOP dispara esse
ResizeObserver e corrigir o layout/componente, não o teste) — possivelmente como nova tarefa do
módulo `mop`; (b) pedir que eu (subAgent `geral`) investigue mais a fundo a causa do
ResizeObserver nessa tela antes de considerar a reversão pronta; ou (c) outra prioridade que
prefira. Branch e commit já estão prontos localmente (não pushado ainda) para qualquer um dos
caminhos.
Resposta: Thiago decidiu manter como estava antes desta tarefa — não prosseguir com a reversão. O
handler de `uncaught:exception` em `cypress/support/e2e.js` deve continuar ignorando
`ResizeObserver loop completed with undelivered notifications` (o mascaramento introduzido no
commit `a2f2d88` fica valendo, sem mudança). Motivo: depois de eu explicar que remover o
mascaramento não corrige nada na tela — só volta a expor uma falha que já existia (o
ResizeObserver continua acontecendo de verdade no Monitor Diário; sem o handler, o Cypress só
passa a acusar isso como falha do teste de novo) — ele preferiu manter o comportamento atual
(teste passando, erro mascarado) em vez de deixar o teste falhando sem uma correção real da causa
pronta.

Ação esperada: abandone a branch `feature/reverter-handler-resizeobserver`/commit `2866b45` (não
dar push, não deixar aviso em `agent-master/fila-merge/pendentes/` — não há nada para mergear).
Registre em `docs/documentacao.md` que a reversão foi tentada e funcionou tecnicamente (confirmado
que sem o handler o `ResizeObserver` volta a derrubar `mop-monitor-diario.feature`), mas foi
descartada a pedido do Thiago — o handler permanece como estava. Se um dia a causa raiz do
ResizeObserver na tela do Monitor Diário for investigada/corrigida de verdade, isso deve virar uma
tarefa nova (não reaproveitar esta). Mova esta tarefa de `aguardando-resposta/` para `concluidas/`
(encerrada sem merge, por decisão do Thiago).
