# Conhecimento acumulado do módulo mop

## Tarefa 20260911214610-monitor-diario-analisar-operacao (concluída em 2026-09-14)

Branch: `feature/mop-monitor-diario-analisar-operacao` (aberta a partir de `reviewAgents`),
commitada e enviada (`b279acd`). Aviso deixado em `agent-master/fila-merge/pendentes/` para o
Agent Master abrir o PR. Tarefa movida para `tarefas/concluidas/`.

O login (`cy.loginComoPerfil('master')`) voltou a funcionar normalmente neste ciclo — o erro
recorrente de `cy.origin()` registrado nas retomadas anteriores (ver abaixo e
`conhecimento-geral.md`) não se repetiu; o Thiago havia confirmado que o HML estava ok e liberado
retomar a investigação. Não foi possível confirmar a causa raiz do erro anterior (ambiente
instável vs. algo estrutural) — só que desta vez o login funcionou de ponta a ponta sem retry.

### Implementação final

- `cypress/support/etapas/EtapaBase.js` — contrato compartilhado (`perfil`, `logar()`,
  `executar()`, `validar()`), conforme já definido no `CLAUDE.md` do repo.
- `cypress/support/pages/mop/MonitorDiarioPage.js` — `navegarAte()` (Beyond BackOffice → Comercial
  → Monitor Diário), `buscar()`, `ampliarJanelaBusca()` (janela de 29 dias) e
  `selecionarOperacaoForaDeInclusaoOpe()` (captura o cedente na listagem antes de clicar em
  "Analisar Operação").
- `cypress/support/pages/mop/AnaliseOperacaoPage.js` — `obterNomeEmpresa()`, lê o nome da empresa
  no `h1` seguinte ao `h1` "OPERAÇÃO <número>" da tela de análise.
- `cypress/support/etapas/mop/EtapaAnalisarOperacaoMonitorDiario.js` (perfil `master`) e
  `cypress/support/esteiras/mop/EsteiraAnalisarOperacaoMonitorDiario.js` — orquestração padrão
  Etapa/Esteira.
- `cypress/e2e/features/mop/mop-monitor-diario.feature` +
  `cypress/support/step_definitions/mop/mopMonitorDiario.js` — camada fina Cucumber, sem lógica de
  orquestração.
- `CLAUDE.md` do repo atualizado (seção "Arquivos-chave") documentando o que foi criado no MOP.

### Descobertas estruturais da tela (seletores/comportamento reais de HML)

- O menu lateral (drawer MUI) do dashboard **Comercial** só mostra ícones (sem texto/aria-label no
  DOM estático). O ícone com `data-testid="LoopIcon"` funciona como toggle: clicar nele expande o
  drawer e revela o texto dos itens (é o que permite localizar "Monitor Diário" com segurança, sem
  depender de índice/posição do ícone, que pode mudar). Selector usado:
  `.menu-MuiDrawer-paper .menu-MuiListItem-root:has([data-testid="LoopIcon"])`.
- Após clicar no toggle, a expansão do drawer é uma transição CSS de largura — clicar em "Monitor
  Diário" cedo demais (antes da transição terminar) já causou clique acidental em outro item da
  lista durante a investigação; por isso há um `cy.wait` antes de localizar o texto.
- `cy.contains('.menu-MuiDrawer-paper *', 'Monitor Diário')` (com o `*`) é necessário — sem ele o
  `contains` casa com o próprio container do drawer (que "contém" o texto como descendente, mas
  não tem `onClick`), não o item interno clicável.
- Navegar para o Monitor Diário resulta em `pathname === '/mop/monitor'`.
- Os inputs de data (`input[type="date"]`) são controlados por React: setar `.val()` via jQuery não
  dispara o `onChange` — é preciso usar o setter nativo do protótipo
  (`Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set`) antes de
  disparar os eventos `input`/`change` manualmente. Mesma técnica útil para qualquer outro input
  controlado por React no restante do sistema.
- A tabela de resultados é `table.MuiTable-root tbody tr`. O status de cada linha (coluna "Etapa")
  fica em `.mop-MuiChip-label`; o nome do cedente é o 4º `<td>` (`querySelectorAll('td')[3]`).
- A ação "Analisar Operação" é acionada pelo botão de zoom/detalhe (último `<button>` da linha),
  que abre um menu/modal onde aparece a opção "Analisar Operação" para clicar.
- Na tela de análise, o cabeçalho tem dois `<h1 class="mop-MuiTypography-h1">` lado a lado:
  "OPERAÇÃO `<número>`" e, logo em seguida, o nome da empresa. A tela do Monitor Diário (por trás,
  ainda montada) também tem um `h1` próprio ("Operações"), então a Page localiza especificamente o
  `h1` que casa com `/^OPERAÇÃO\s+\d/` e lê o `h1` seguinte — não dá para simplesmente pegar "o h1
  que não é numérico".
- A tela de análise carrega de forma assíncrona (XHR de pré-operações) — usar `.should()` (com
  retry) em vez de `.then()` para aguardar o `h1` "OPERAÇÃO `<número>`" realmente aparecer.

### Navegação até a tela Comercial

- Home logada (`master`) mostra painéis "Beyond BackOffice", "Beyond Flow", "Beyond Cadastros"
  etc. Clicar em **"Beyond BackOffice"** expande um accordion com sub-itens em texto: Comercial,
  Crédito, Tesouraria, Jurídico, Gestora, Compliance, Formalização.
- Clicar em **"Comercial"** navega (via single-spa, sem `href` estático — roteamento só por JS)
  para o dashboard do módulo Comercial (cards "Operação Diária", "Operação Estruturada", "Operação
  Cessão", "Garantia"). O menu lateral (ícone `LoopIcon`) desse dashboard é o caminho para o
  Monitor Diário — ver "Descobertas estruturais da tela" acima.

### Bug conhecido do widget de menu (`mc-menu.js`) — corrigido

Ao clicar em "Beyond BackOffice", o componente de menu (`mc-menu.js`, carregado de
`beyond-hml.grupomultiplica.com.br`) por vezes lança uma exceção não tratada própria
(`Cannot read properties of undefined (reading 'content')`), que derruba qualquer teste Cypress
por padrão (exceção não capturada da aplicação). Não afeta a navegação visual real. Corrigido
adicionando um handler `Cypress.on('uncaught:exception', ...)` em `cypress/support/e2e.js` que
ignora especificamente essa mensagem — **já commitado** (`a83b438`) e enviado (push) na branch da
tarefa. Útil a qualquer módulo que navegue pelo mesmo menu.

### Histórico do bloqueio de login (`cy.origin`) — resolvido

Em ciclos anteriores (2026-09-11 e retomada em 2026-09-14), `cy.loginComoPerfil('master')` falhou
de forma recorrente com `CypressError: cy.origin() failed to create a spec bridge...` logo após o
redirect para `keycloak-new-2.grupomultiplica.com.br`. Duas dúvidas bloqueantes foram registradas
e respondidas pelo Thiago (ver `duvidas.md` para o texto completo; catálogo geral de sintomas de
instabilidade de login em `../geral/docs/documentacao.md`); causa raiz não confirmada (ambiente
instável vs. algo estrutural), mas neste ciclo (2026-09-14) o login funcionou normalmente de ponta
a ponta, permitindo concluir a investigação e a implementação.

## Tarefa 20260918104219-hand-off-criacao-operacao-servico-monitor-diario (BLOQUEADA de novo em 2026-09-18, por motivo NOVO)

Hand-off de uma investigação exploratória do `SupTestesFrontEnd` — virar teste automatizado
permanente do fluxo "criar operação de serviço no Beyond Banking → verificar Etapa 'Middle' no
Monitor Diário do Beyond BackOffice". Branch `feature/mop-criacao-operacao-servico-monitor-diario`.

### Resolução do 1º bloqueio (dúvida `20260918104219-...`, respondida pelo Thiago)

O bloqueio anterior (operação recém-criada não aparece na listagem "Operações" do Beyond Banking,
então nunca há linha pra clicar "Avançar") foi resolvido por decisão do Thiago: não é mais
necessário avançar a operação recém-criada via UI. Critério de aceite ajustado (duas verificações
independentes em `EtapaVerificarOperacaoMonitorDiario`):

1. A operação recém-criada aparece no Monitor Diário, em qualquer etapa (`MonitorDiarioPage.
   aguardarOperacaoAparecer()`, renomeado/simplificado de `aguardarOperacaoAlemDeInclusaoOpe` —
   não exige mais que a etapa seja diferente de "Inclusão OPE").
2. Existe alguma operação já em "Middle" no Monitor Diário (`MonitorDiarioPage.
   aguardarQualquerOperacaoNaEtapa('Middle')`, novo — só lê a listagem, não clica em nada),
   desacoplada da operação recém-criada — valida que o Monitor Diário/Page detectam a etapa
   corretamente, sem depender do bug de produto acima.
- `OperacaoInternoPage.criarOperacaoServicoBoleto()` não tenta mais clicar "Avançar" (bloco
  removido) — não era mais necessário dado o critério ajustado.
- `.feature`/step definitions atualizados para as duas asserções (`a operação recém-criada deve
  aparecer no Monitor Diário` + `deve existir alguma operação na etapa "Middle" no Monitor
  Diário`).

### 2º bloqueio, NOVO (autoteste, 2026-09-18): exceção não tratada ("null") ao logar no segundo app (Beyond BackOffice) na mesma spec

Depois do fix acima, o autoteste (`npx cypress run`) chega a completar toda a Etapa de criação no
Beyond Banking (login, wizard, "Operação criada com sucesso") mas falha ao criar a sessão do
SEGUNDO app (`cy.loginComoPerfil('master')`, app default `backoffice`, dentro de
`EtapaVerificarOperacaoMonitorDiario.logar()`): `cy.session('backoffice:master', ...)` falha
durante `cy.visit(appBaseUrl)` com `(uncaught exception) Error: null` — "This error was thrown by
a cross origin page. If you wish to suppress this error you will have to use the cy.origin
command...". Reproduzido de forma **idêntica e consistente em 2 tentativas seguidas** (mesmo texto
exato, mesmo ponto exato). Curl manual confirma `beyond-hml`/`beyondbanking-hml`/`keycloak-new-2`
respondendo normal (200/200/302, <0.5s) no momento — não é ambiente fora do ar.

Isso é NOVO: nunca tinha acontecido em tarefas anteriores porque nenhuma spec anterior deste
módulo logava em **dois apps/origens diferentes dentro do mesmo teste** (só esta tarefa introduziu
isso, via `cy.loginComoPerfil(perfil, { app })`). Hipótese (não confirmada): o handler global de
`Cypress.on('uncaught:exception', ...)` em `cypress/support/e2e.js` só é aplicado à origem
"primária" do teste (a primeira visitada) — ao trocar de app/origem no meio do teste, o Cypress
trata a exceção como vinda de uma "cross origin page" e exige um handler registrado via
`cy.origin(essaOrigem, () => cy.on('uncaught:exception', ...))` especificamente para ela (é
literalmente o que a própria mensagem de erro do Cypress sugere).

**Tentativa de fix, revertida**: registrar esse handler (mesmo padrão já usado para o bug do
`mc-menu.js`/ResizeObserver) escopado à origem do app, dentro do setup do `cy.session` em
`commands.js`, antes do `cy.visit(appBaseUrl)`. Resultado: `cy.origin()` rejeitou a chamada
("`cy.origin()` requires the first argument to be a different origin than top") já na criação da
PRIMEIRA sessão do teste (`beyondBanking:master`) — ou seja, no momento em que esse `cy.origin()`
roda, o Cypress já considera "top" como sendo a própria origem do primeiro app, antes mesmo de
qualquer `cy.visit` ter rodado no teste (comportamento interno do Cypress não totalmente
entendido). Ajustei para só registrar o handler quando a URL atual (`cy.url()`) já é diferente da
origem do app a visitar (evitando o registro na primeira visita) — com esse ajuste, a segunda
tentativa **travou por >25 minutos sem nenhum progresso** (nenhuma linha nova de log, processo
Electron/Cypress sem terminar) e precisou ser abortada manualmente; não confirmei se a causa foi o
meu ajuste ou uma instabilidade pontual do ambiente/rede naquele momento específico (curl re-testado
depois do abort respondeu normal). **Por segurança, revertido**: `cypress/support/commands.js`
está de volta ao estado original (sem esse handler extra) — não quis deixar uma mudança não
validada no comando de login compartilhado (`cy.loginComoPerfil`), usado por todos os módulos, só
pra corrigir um problema específico desta tarefa.

Dúvida bloqueante registrada em `duvidas.md` (mesmo id da tarefa,
`20260918104219-hand-off-criacao-operacao-servico-monitor-diario`, nova pergunta). Tarefa movida
de volta para `tarefas/aguardando-resposta/`. Progresso (fix do 1º bloqueio + reversão do
commands.js) commitado na branch antes de bloquear.

### Implementação (passos 1-9 do roteiro funcionam de ponta a ponta)

- `cypress/support/pages/mop/SelecaoClientePage.js` — seleciona o cedente `kenerson` (trata os dois
  casos: tela "Seleção de cliente" aparecer ou já vir com cedente persistido da sessão).
- `cypress/support/pages/mop/OperacaoInternoPage.js` — `criarOperacaoServicoBoleto()`, função única
  autocontida (não chama outras Pages) porque roda inteira dentro de um único `cy.origin()` (o
  subdomínio de "Beyond Operação Interno" é uma origem distinta pro Cypress). Cobre: wizard de
  produto (Aquisição → Antecipação de Duplicata → Duplicata → Serviço → Boleto, sempre com regex de
  match exato — há textos superconjunto e um typo real do app, "DUPLICTA"), conta pré-selecionada,
  entrada "por digitação", Cad Pessoa (CPF de teste, busca automática preenche o resto), título
  (Documento aleatório por execução — documento duplicado causa 400 no "Avançar" —, Valor de
  teste), Salvar → Gerar Operação → Confirmar (toast "Operação criada com sucesso").
- `cypress/support/etapas/mop/EtapaCriarOperacaoServicoBeyondBanking.js` (perfil `master`, app
  `beyondBanking`) e `EtapaVerificarOperacaoMonitorDiario.js` (perfil `master`, app default
  `backoffice`) + `EsteiraCriacaoOperacaoServicoMonitorDiario.js` — orquestração padrão
  Etapa/Esteira. `EtapaVerificarOperacaoMonitorDiario` recebe a etapa de criação no construtor pra
  ler `numeroOperacao` (só disponível depois que a fila de comandos Cypress dela terminar — lido
  dentro de `cy.then()`, nunca direto).
- `cypress/e2e/features/mop/mop-criacao-operacao-servico.feature` +
  `step_definitions/mop/mopCriacaoOperacaoServico.js` — camada fina Cucumber.
- `MonitorDiarioPage.localizarOperacaoPorNumero()` + `aguardarOperacaoAparecer()` (polling com até
  6 tentativas, amplia janela pra 29 dias se a operação ainda não aparecer) + (novo, ver seção
  "Resolução do 1º bloqueio" acima) `localizarQualquerOperacaoNaEtapa()` /
  `aguardarQualquerOperacaoNaEtapa()`.
- Login multi-app: `cy.loginComoPerfil(perfil, { app })` (`commands.js`) + `getApp()`
  (`environments.js`) + variáveis novas `HML_BEYOND_BANKING_URL`/`HML_BEYOND_BANKING_OPERACAO_URL`
  (`.env.example`) — permite logar em Beyond Banking e Beyond BackOffice (hosts/realms diferentes
  do Keycloak) no mesmo teste, sem misturar sessão (`cy.session` chaveado por `app:perfil`).
- **Bug corrigido nesta tarefa**: `criarOperacaoServicoBoleto()` originalmente retornava
  `numeroOperacao` (valor síncrono) de dentro de um `.then()` que já tinha enfileirado comandos
  `cy.wrap()/cy.wait()` antes — Cypress rejeita isso (`cy.then() failed because you are mixing up
  async and sync code`). Corrigido encadeando tudo na mesma promise (`cy.wrap(...).then(() =>
  ...).then(() => numeroOperacao)`).

### BLOQUEIO original (operação nova não aparece na listagem "Operações") — RESOLVIDO, ver seção acima

Texto original movido para `docs/documentacao-historico.md` (arquivado — regra 11 do `AGENTE.md`).
Resumo: resolvido pela decisão do Thiago descrita em "Resolução do 1º bloqueio" acima (não é mais
necessário avançar a operação recém-criada via UI).
