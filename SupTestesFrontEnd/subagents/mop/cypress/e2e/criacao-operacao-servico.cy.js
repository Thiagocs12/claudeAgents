// Spec descartável desta tarefa (id 20260915123730-criacao-operacao-servico). Não é uma suíte
// persistente — ver AGENTE.md. Reescrita do zero em 2026-09-15 seguindo o roteiro de 14 passos
// (ver duvidas.md) — o app correto é o Beyond Banking (host diferente do Beyond BackOffice), a
// versão anterior desta spec explorava o app errado e foi descartada por decisão do Thiago.

const ambiente = {
  beyondBankingUrl: Cypress.env('HML_BEYOND_BANKING_URL'),
  // Descoberto nesta exploracao: "Beyond Operação Interno" navega pra um subdominio separado
  // (origem distinta pro Cypress) - registrado em .env e em docs/documentacao.md.
  beyondBankingOperacaoUrl: Cypress.env('HML_BEYOND_BANKING_OPERACAO_URL'),
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

    // NOVO ACHADO (2026-09-15, rodada 24): apos o login, a aplicacao redirecionou direto pra
    // `/clients` -- tela "Selecao de cliente" ("Automacao, Qual cliente deseja acessar?") com um
    // dropdown "Selecione aqui" e botao "Avancar". Isso resolve os passos 2-3 do roteiro
    // diretamente (nao precisa navegar por "Beyond Operacao Interno" -> icone de casa como as
    // rodadas anteriores tentaram).
    // NOVO ACHADO (2026-09-15, rodada 33): em rodadas onde o perfil do browser do Cypress ja
    // tinha uma selecao anterior de "kenerson" persistida (cookie/sessao do servidor), a tela de
    // selecao e pulada e a app cai direto na Home ja com o cedente selecionado. Tratando os dois
    // casos aqui em vez de assumir sempre a tela de selecao.
    cy.get('body', { timeout: 15000 }).then(($body) => {
      if ($body.text().includes('Seleção de cliente')) {
        cy.writeFile('cypress/debug-output.txt', '\nCENARIO: tela de selecao de cliente apareceu\n', { flag: 'a+' })
        cy.contains('label', 'Selecione aqui').parent().click()
        // Achado: o dropdown e um autocomplete que carrega as opcoes de forma assincrona
        // ("Loading..." visivel logo apos abrir) - digitar o termo de busca antes de checar as
        // opcoes, em vez de so abrir e olhar a lista completa.
        cy.focused().type('kenerson', { delay: 100 })
        cy.wait(2000)
        cy.get('body').then(($body2) => {
          const textos = [...$body2.find('[role="option"], li, .MuiAutocomplete-option, .MuiMenuItem-root')]
            .map((el) => el.textContent.trim())
            .filter((t) => t && t.length > 0 && t.length < 150)
          cy.writeFile('cypress/debug-output.txt', '\nOPCOES NO DROPDOWN APOS DIGITAR "kenerson":\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
        })
        cy.screenshot('03-dropdown-apos-digitar-kenerson')

        // Achado: so apareceu 1 opcao (o cedente "kenerson" em si, CNPJ 07.019.231/0001-96) - nao
        // ha uma escolha de "cadastro master" visivel aqui ainda. Selecionando essa opcao e
        // avancando para ver se o cadastro master aparece na proxima tela (passo 3 do roteiro).
        cy.contains('[role="option"], li, .MuiAutocomplete-option, .MuiMenuItem-root', 'KENERSON').click()
        cy.contains('button', 'Avançar').click()
        cy.wait(3000)
      } else {
        cy.writeFile('cypress/debug-output.txt', '\nCENARIO: sessao ja tinha kenerson selecionado, Home direto\n', { flag: 'a+' })
      }
    })
    cy.location().then((loc) => {
      cy.writeFile('cypress/debug-output.txt', '\nURL APOS SELECIONAR KENERSON E AVANCAR: ' + loc.href + '\n', { flag: 'a+' })
    })
    cy.get('body', { timeout: 15000 }).should('contain.text', 'KENERSON')
    cy.get('body', { timeout: 15000 }).then(($body) => {
      const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], .MuiCard-root, input, [role="menuitem"], li')]
        .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
        .filter((t) => t && t.length > 0 && t.length < 150)
      cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS SELECIONAR KENERSON:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
    })
    cy.screenshot('04-apos-selecionar-kenerson-avancar')

    // Passo 4-5 do roteiro: card mais proximo de "Beyond Operacao" e "Beyond Operacao Interno".
    // Navega pra um subdominio diferente (origem distinta pro Cypress) - precisa de cy.origin
    // a partir daqui (ja mapeado em ciclo anterior, ver docs/documentacao.md).
    cy.contains('.MuiCard-root, [class*="card" i], div', 'Beyond Operação Interno').click()
    cy.wait(3000)
    cy.location().then((loc) => {
      cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR BEYOND OPERACAO INTERNO: ' + loc.href + '\n', { flag: 'a+' })
    })
    cy.origin(ambiente.beyondBankingOperacaoUrl, () => {
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], .MuiCard-root, input, [role="menuitem"], li')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS NA TELA DE OPERACOES:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('05-tela-operacoes')

      // Passo 5: clicar em "Criar Operacao".
      cy.contains('button, a, [role="button"]', 'Criar Operação').click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], .MuiCard-root, input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR CRIAR OPERACAO:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('06-apos-clicar-criar-operacao')
    })
  })
})
