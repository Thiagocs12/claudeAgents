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

## Tarefa 20260918104219-hand-off-criacao-operacao-servico-monitor-diario (BLOQUEADA em 2026-09-18)

Hand-off de uma investigação exploratória do `SupTestesFrontEnd` — virar teste automatizado
permanente do fluxo "criar operação de serviço no Beyond Banking → verificar Etapa 'Middle' no
Monitor Diário do Beyond BackOffice". Branch `feature/mop-criacao-operacao-servico-monitor-diario`,
progresso commitado (`d9843bc`), **ainda não pushado** (tarefa bloqueada, não concluída).

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
- `MonitorDiarioPage.localizarOperacaoPorNumero()` + `aguardarOperacaoAlemDeInclusaoOpe()` (polling
  com até 6 tentativas, amplia janela pra 29 dias se a operação nem aparecer em "Inclusão OPE").
- Login multi-app: `cy.loginComoPerfil(perfil, { app })` (`commands.js`) + `getApp()`
  (`environments.js`) + variáveis novas `HML_BEYOND_BANKING_URL`/`HML_BEYOND_BANKING_OPERACAO_URL`
  (`.env.example`) — permite logar em Beyond Banking e Beyond BackOffice (hosts/realms diferentes
  do Keycloak) no mesmo teste, sem misturar sessão (`cy.session` chaveado por `app:perfil`).
- **Bug corrigido nesta tarefa**: `criarOperacaoServicoBoleto()` originalmente retornava
  `numeroOperacao` (valor síncrono) de dentro de um `.then()` que já tinha enfileirado comandos
  `cy.wrap()/cy.wait()` antes — Cypress rejeita isso (`cy.then() failed because you are mixing up
  async and sync code`). Corrigido encadeando tudo na mesma promise (`cy.wrap(...).then(() =>
  ...).then(() => numeroOperacao)`).

### BLOQUEIO (achado reproduzido ao vivo, 2026-09-18): operação nova não aparece na listagem "Operações" do Beyond Banking

Depois de "Operação criada com sucesso", o passo seguinte do roteiro (clicar "Avançar" na linha da
operação recém-criada — necessário pra ela deixar de ser pré-operação e progredir além de "Inclusão
OPE" no Monitor Diário) não consegue achar a linha: a tabela "Operações" continuou mostrando só as
mesmas 7 linhas antigas de 16/09/2026 (sobras da investigação exploratória anterior, `88677-88683`),
mesmo depois de `cy.wait(10000)` + `cy.reload()`. O código pegava a primeira linha (assumindo "mais
recente primeiro"), que na prática é uma operação antiga já "Em Análise" com o botão "Avançar" já
desabilitado — `cy.click() failed because this element is disabled`.

Isso é a reprodução ao vivo, hoje, de um achado já documentado pelo `SupTestesFrontEnd`
(`SupTestesFrontEnd/subagents/mop/docs/documentacao.md`, "Armadilha/achado: operação recém-criada
não aparece na listagem 'Operações' do Beyond Banking, apesar de existir no banco e aparecendo
normalmente no Monitor Diário"). Lá esse achado foi tratado como "não bloqueia" porque a validação
final usou uma operação antiga já convertida em banco (`88683`) em vez de recriar uma nova — mas um
teste automatizado permanente (Documento aleatório a cada execução, por design) não tem esse atalho:
precisa de uma operação nova a cada run, e não consegue avançá-la se ela não aparece na listagem.

Dúvida registrada em `duvidas.md` (`20260918104219-...`), tarefa movida para
`tarefas/aguardando-resposta/`. Não commitei nenhum workaround pro bug em si (banco, API direta
etc.) — só o fix legítimo do bug de async/sync acima, que é independente deste bloqueio.
