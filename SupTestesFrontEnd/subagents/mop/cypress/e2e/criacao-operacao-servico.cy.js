// Spec descartável desta tarefa (id 20260915123730-criacao-operacao-servico). Não é uma suíte
// persistente — ver AGENTE.md. Reescrita do zero em 2026-09-15 seguindo o roteiro de 14 passos
// (ver duvidas.md) — o app correto é o Beyond Banking (host diferente do Beyond BackOffice), a
// versão anterior desta spec explorava o app errado e foi descartada por decisão do Thiago.

const ambiente = {
  beyondBankingUrl: Cypress.env('HML_BEYOND_BANKING_URL'),
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

describe('Exploracao: criacao de operacao de servico no Beyond Banking', () => {
  it('acessa o Beyond Banking e mapeia a tela inicial / login', () => {
    const chamadasFalhas = []
    cy.intercept({ url: '**', middleware: true }, (req) => {
      req.on('response', (res) => {
        if (res.statusCode >= 400) {
          chamadasFalhas.push(`${res.statusCode} ${req.method} ${req.url}`)
        }
      })
    })

    cy.on('window:before:load', anexarCapturaDeErros)

    cy.visit(ambiente.beyondBankingUrl, { onBeforeLoad: anexarCapturaDeErros })
    cy.wait(3000)
    cy.location().then((loc) => {
      cy.writeFile('cypress/debug-output.txt', 'URL APOS VISIT: ' + loc.href + '\n')
    })

    // Se redirecionou pro Keycloak (mesmo mecanismo do Beyond BackOffice), loga por la.
    cy.url().then((url) => {
      const foiPraKeycloak = url.includes(new URL(ambiente.keycloakUrl).origin)
      cy.writeFile('cypress/debug-output.txt', '\nFOI PRA KEYCLOAK: ' + foiPraKeycloak + '\n', { flag: 'a+' })
      if (foiPraKeycloak) {
        cy.origin(
          new URL(ambiente.keycloakUrl).origin,
          { args: { username: ambiente.username, password: ambiente.password, selectors: KEYCLOAK_SELECTORS } },
          ({ username, password, selectors }) => {
            cy.get(selectors.username).should('be.visible').clear().type(username, { log: false })
            cy.get(selectors.password).should('be.visible').clear().type(password, { log: false })
            cy.get(selectors.submit).should('be.visible').click()
          }
        )
      }
    })

    cy.wait(4000)
    cy.screenshot('02-apos-tentativa-login')
    cy.location().then((loc) => {
      cy.writeFile('cypress/debug-output.txt', '\nURL APOS LOGIN: ' + loc.href + '\n', { flag: 'a+' })
    })
    cy.get('body').then(($body) => {
      const textos = [...$body.find('label, legend, h1, h2, h3, button, a, [role="button"], .MuiCard-root, input')]
        .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
        .filter((t) => t && t.length > 0 && t.length < 100)
      cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS NA TELA APOS LOGIN:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
    })
    cy.then(() => {
      cy.writeFile('cypress/debug-output.txt', '\n\nCHAMADAS COM ERRO:\n' + JSON.stringify(chamadasFalhas, null, 2), { flag: 'a+' })
    })
    cy.window().then((win) => {
      cy.writeFile('cypress/debug-output.txt', '\n\nERROS JS CAPTURADOS:\n' + JSON.stringify(win.__errosCapturados || [], null, 2), { flag: 'a+' })
    })

    // Passo 4 do roteiro: nenhum card se chama exatamente "Beyond Operação" -- "Beyond Operação
    // Interno" e a interpretacao mais provavel (ver docs/documentacao.md). Clicando para mapear.
    cy.contains('.MuiCard-root, [role="button"], a, button', 'Beyond Operação Interno').click()
    cy.wait(3000)
    cy.screenshot('03-apos-clicar-beyond-operacao-interno')
    cy.location().then((loc) => {
      cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR BEYOND OPERACAO INTERNO: ' + loc.href + '\n', { flag: 'a+' })
    })
    cy.get('body').then(($body) => {
      const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], .MuiCard-root, input, [role="menuitem"], li')]
        .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
        .filter((t) => t && t.length > 0 && t.length < 100)
      cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR BEYOND OPERACAO INTERNO:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
    })
    cy.then(() => {
      cy.writeFile('cypress/debug-output.txt', '\n\nCHAMADAS COM ERRO (apos card):\n' + JSON.stringify(chamadasFalhas, null, 2), { flag: 'a+' })
    })
    cy.window().then((win) => {
      cy.writeFile('cypress/debug-output.txt', '\n\nERROS JS CAPTURADOS (apos card):\n' + JSON.stringify(win.__errosCapturados || [], null, 2), { flag: 'a+' })
    })
  })
})
