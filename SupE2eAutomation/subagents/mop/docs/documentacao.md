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
tarefa. Registrado também em `conhecimento-geral.md` por ser útil a qualquer módulo que navegue
pelo mesmo menu.

### Histórico do bloqueio de login (`cy.origin`) — resolvido

Em ciclos anteriores (2026-09-11 e retomada em 2026-09-14), `cy.loginComoPerfil('master')` falhou
de forma recorrente com `CypressError: cy.origin() failed to create a spec bridge...` logo após o
redirect para `keycloak-new-2.grupomultiplica.com.br`. Duas dúvidas bloqueantes foram registradas
e respondidas pelo Thiago (ver `duvidas.md` e `conhecimento-geral.md` para o texto completo);
causa raiz não confirmada (ambiente instável vs. algo estrutural), mas neste ciclo (2026-09-14) o
login funcionou normalmente de ponta a ponta, permitindo concluir a investigação e a
implementação.
