// Spec descartável desta tarefa (id 20260915123730-criacao-operacao-servico). Não é uma suíte
// persistente — ver AGENTE.md.

const ambiente = {
  appBaseUrl: Cypress.env('HML_APP_BASE_URL'),
  keycloakUrl: Cypress.env('HML_KEYCLOAK_URL'),
  username: Cypress.env('HML_MASTER_USERNAME'),
  password: Cypress.env('HML_MASTER_PASSWORD'),
}

const KEYCLOAK_SELECTORS = {
  username: '#username',
  password: '#password',
  submit: '#kc-login',
}

function anexarCapturaDeErros(win) {
  win.__errosCapturados = win.__errosCapturados || []
  win.addEventListener('error', (e) => {
    win.__errosCapturados.push('error: ' + (e.error?.stack || e.message))
  })
  win.addEventListener('unhandledrejection', (e) => {
    win.__errosCapturados.push('unhandledrejection: ' + (e.reason?.stack || e.reason))
  })
}

function login() {
  cy.visit(ambiente.appBaseUrl, { onBeforeLoad: anexarCapturaDeErros })
  cy.origin(
    new URL(ambiente.keycloakUrl).origin,
    { args: { username: ambiente.username, password: ambiente.password, selectors: KEYCLOAK_SELECTORS } },
    ({ username, password, selectors }) => {
      cy.get(selectors.username).should('be.visible').clear().type(username, { log: false })
      cy.get(selectors.password).should('be.visible').clear().type(password, { log: false })
      cy.get(selectors.submit).should('be.visible').click()
    }
  )
  cy.url({ timeout: 15000 }).should('include', ambiente.appBaseUrl)
}

function navegarAteComercial() {
  cy.contains('Beyond BackOffice').click()
  cy.wait(2000)
  cy.contains('Comercial').click()
  cy.wait(2000)
}

describe('Exploracao: criacao de operacao de servico', () => {
  it('loga e explora o dashboard Comercial em busca do ponto de entrada de "operacao de servico"', () => {
    const chamadasFalhas = []
    cy.intercept({ url: '**', middleware: true }, (req) => {
      req.on('response', (res) => {
        if (res.statusCode >= 400) {
          chamadasFalhas.push(`${res.statusCode} ${req.method} ${req.url}`)
        }
      })
    })

    cy.on('window:before:load', anexarCapturaDeErros)

    login()
    navegarAteComercial()

    cy.wait(2000)
    cy.screenshot('dashboard-comercial')

    // Lista todo texto visivel de cards/botoes na tela para mapear os pontos de entrada
    // disponiveis (ainda nao sabemos qual leva a "operacao de servico").
    cy.get('body').then(($body) => {
      const textos = [...$body.find('button, a, [role="button"], .MuiCard-root')]
        .map((el) => el.textContent.trim())
        .filter((t) => t.length > 0 && t.length < 80)
      cy.log('Elementos clicaveis/cards encontrados: ' + JSON.stringify([...new Set(textos)]))
    })

    // Expande o menu lateral (mesmo padrao ja mapeado pelo SupE2eAutomation: icone LoopIcon
    // funciona como toggle e revela o texto dos itens) para ver se "Operacao de Servico" e um
    // item de menu, nao um card do dashboard.
    cy.get('.menu-MuiDrawer-paper .menu-MuiListItem-root:has([data-testid="LoopIcon"])').click()
    cy.wait(1500)
    cy.screenshot('menu-lateral-expandido')
    cy.get('.menu-MuiDrawer-paper').then(($drawer) => {
      const itens = [...$drawer.find('*')]
        .map((el) => el.textContent.trim())
        .filter((t) => t.length > 0 && t.length < 60)
      cy.log('Itens do menu lateral: ' + JSON.stringify([...new Set(itens)]))
    })

    // Screenshot revelou item "Nova Operacao" sob a secao "Operacao" do menu lateral (junto com
    // Monitor Diario/Estruturada/Cessao Fundo/XML/Inclusao, Operacao Ativo, Planilha Operacional,
    // Simular Operacao). Candidato mais provavel ao ponto de entrada de criacao.
    cy.contains(`.menu-MuiDrawer-paper *`, 'Nova Operação', { timeout: 10000 })
      .should('be.visible')
      .click({ force: true })
    // A tela carrega dados assincronos (mesmo padrao da tela de analise do Monitor Diario, ja
    // mapeada pelo SupE2eAutomation): aguardar o corpo ter mais conteudo que so o spinner.
    cy.wait(5000)
    cy.screenshot('tela-nova-operacao')
    cy.location('pathname').then((p) => cy.writeFile('cypress/debug-output.txt', 'PATHNAME: ' + p + '\n'))
    cy.wait(8000)
    cy.screenshot('tela-nova-operacao-apos-mais-espera')
    cy.get('body').then(($body) => {
      cy.writeFile('cypress/debug-output.txt', 'HTML:\n' + $body.html().slice(0, 5000), { flag: 'a+' })
    })
    cy.then(() => {
      cy.writeFile('cypress/debug-output.txt', '\n\nCHAMADAS COM ERRO:\n' + JSON.stringify(chamadasFalhas, null, 2), { flag: 'a+' })
    })
    cy.window().then((win) => {
      cy.writeFile('cypress/debug-output.txt', '\n\nERROS JS CAPTURADOS:\n' + JSON.stringify(win.__errosCapturados || [], null, 2), { flag: 'a+' })
    })

    // Tela "Nova Operacao" pede para selecionar um Cedente antes de prosseguir. Abre o dropdown
    // MUI e lista as opcoes disponiveis.
    cy.contains('Selecione o cedente', { timeout: 15000 }).should('be.visible')
    cy.get('[role="combobox"], .MuiSelect-select, [aria-haspopup="listbox"]').first().click()
    cy.wait(1500)
    cy.screenshot('dropdown-cedente-aberto')
    cy.get('body').then(($body) => {
      const opcoes = [...$body.find('[role="option"], li.MuiMenuItem-root')]
        .map((el) => el.textContent.trim())
        .filter((t) => t.length > 0)
      cy.writeFile('cypress/debug-output.txt', '\n\nOPCOES DE CEDENTE:\n' + JSON.stringify(opcoes, null, 2), { flag: 'a+' })
    })

    // "Cliente Teste Automacao" bloqueou em tentativa anterior por falta de conta bancaria
    // cadastrada (ver ## Execucao da tarefa). Tentando agora com um cedente real de HML para
    // diferenciar "limitacao so desse cedente de teste" de "bloqueio geral do fluxo".
    cy.contains('[role="option"], li.MuiMenuItem-root', 'AGROFOODS BRASIL ALIMENTO S/A').first().click()
    cy.wait(2000)
    cy.screenshot('apos-selecionar-cedente')
    cy.get('body').then(($body) => {
      const textos = [...$body.find('label, legend, h1, h2, h3, button, [role="option"], li.MuiMenuItem-root')]
        .map((el) => el.textContent.trim())
        .filter((t) => t.length > 0 && t.length < 80)
      cy.writeFile('cypress/debug-output.txt', '\n\nAPOS SELECIONAR CEDENTE:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
    })

    // Fluxo de criacao e um assistente virtual conversacional ("Beyond"). Clica em "Ola" para
    // iniciar e narra cada passo seguinte.
    cy.contains('button', 'Olá').click()
    cy.wait(2000)
    cy.screenshot('chat-apos-ola')
    cy.get('body').then(($body) => {
      const textoChat = $body.text()
      cy.writeFile('cypress/debug-output.txt', '\n\nTEXTO DA TELA APOS OLA:\n' + textoChat.slice(-2000), { flag: 'a+' })
    })
    cy.get('body').then(($body) => {
      const textos = [...$body.find('label, legend, h1, h2, h3, option, [role="option"], button')]
        .map((el) => el.textContent.trim())
        .filter((t) => t.length > 0 && t.length < 80)
      cy.log('Campos/opcoes da tela Nova Operacao: ' + JSON.stringify([...new Set(textos)]))
    })

    // Bot perguntou se mantem o produto da ultima operacao deste cedente (que ja inclui "SERVICO"
    // na composicao: AQUISICAO - ANTECIPACAO DE DUPLICATA - DUPLICATA - SERVICO - BOLETO) ou troca.
    // Clica em "Trocar" para ver o catalogo completo de opcoes de produto/tipo, buscando uma opcao
    // explicita de "Servico" em vez de depender do produto herdado da ultima operacao.
    cy.contains('button', 'Trocar').click()
    cy.wait(2000)
    cy.screenshot('chat-apos-trocar')
    cy.get('body').then(($body) => {
      const textoChat = $body.text()
      cy.writeFile('cypress/debug-output.txt', '\n\nTEXTO DA TELA APOS TROCAR:\n' + textoChat.slice(-3000), { flag: 'a+' })
    })
  })
})
