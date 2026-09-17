// Spec descartável desta tarefa (id 20260915123730-criacao-operacao-servico). Não é uma suíte
// persistente — ver AGENTE.md. Reescrita do zero em 2026-09-15 seguindo o roteiro de 14 passos
// (ver duvidas.md) — o app correto é o Beyond Banking (host diferente do Beyond BackOffice), a
// versão anterior desta spec explorava o app errado e foi descartada por decisão do Thiago.

const ambiente = {
  appBaseUrl: Cypress.env('HML_APP_BASE_URL'),
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
    const todasAsChamadas = []
    cy.intercept({ url: '**', middleware: true }, (req) => {
      req.on('response', (res) => {
        if (res.statusCode >= 400) {
          chamadasFalhas.push(`${res.statusCode} ${req.method} ${req.url}`)
        }
        todasAsChamadas.push(`${res.statusCode} ${req.method} ${req.url}`)
        // Correcao do Thiago (2026-09-16): capturar o corpo da resposta do endpoint que retorna
        // 400 ao "Avancar", pra tentar ver a mensagem de erro real sem precisar de acesso a banco.
        if (/pre-operacoes\/.*\/gerar/.test(req.url)) {
          cy.writeFile(
            'cypress/debug-output.txt',
            `\nRESPOSTA DO ENDPOINT /gerar (status ${res.statusCode}):\nURL: ${req.url}\nBODY REQUEST: ${JSON.stringify(req.body)}\nBODY RESPONSE: ${JSON.stringify(res.body)}\n`,
            { flag: 'a+' }
          )
        }
      })
    })

    cy.on('window:before:load', anexarCapturaDeErros)
    // Correcao do Thiago (2026-09-16): nas rodadas 71/73 o 400 do endpoint /gerar virava uma
    // unhandled promise rejection que derrubava o teste antes de conseguirmos capturar o corpo da
    // resposta / continuar observando a tela. Ignorando so essa rejeicao especifica (escopo local
    // deste teste, nao no support/e2e.js compartilhado) pra deixar o teste seguir e coletar mais
    // evidencia apos o erro.
    cy.on('uncaught:exception', (err) => {
      if (err.message.includes('Request failed with status code 400')) {
        return false
      }
      return true
    })

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

    // CORRIGIDO (rodada 96): um `cy.wait(4000)` fixo aqui nao era suficiente em toda rodada - numa
    // execucao mais lenta o proximo comando (`cy.get('body')`, fora do cy.origin) rodou antes do
    // redirect de volta pro Beyond Banking terminar, e falhou com "expected to run against origin
    // beyondbanking-hml but the application is at origin keycloak-new-2" (mesma classe de problema
    // ja corrigido no teste 2, ver linha ~627). Trocado por um `cy.url()` com retry/timeout maior
    // que so segue quando a URL sair de fato do Keycloak.
    cy.url({ timeout: 20000 }).should((url) => {
      expect(url, 'nao deveria mais estar numa tela de login do Keycloak').to.not.match(/\/auth\/realms\//)
    })
    // CORRIGIDO (rodada 95): este screenshot ('02-apos-tentativa-login'), tirado logo apos o login
    // com so um cy.wait fixo, e a mesma armadilha ja documentada em docs/documentacao.md
    // ("cy.screenshot() logo apos cy.visit() quebra o runner") - a tela de login do Beyond Banking
    // tem fundo animado e o screenshot pode cair no meio de uma transicao, derrubando o teste com
    // `TypeError: Cannot destructure property 'duration' of 'props' as it is undefined`. Aconteceu
    // nesta rodada (funcionava por coincidencia em rodadas anteriores). Removido - o dump de texto
    // bruto logo abaixo (sem risco) ja documenta essa tela, e a screenshot
    // '04-apos-selecionar-kenerson-avancar' mais adiante cobre o estado visual apos a pagina
    // assentar.
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
    // NOVO ACHADO (rodadas 34-35): cy.contains(selector, texto) com QUALQUER seletor gera um
    // fallback interno `[type='submit'][value~='TEXTO']` (pra cobrir <input type=submit>), e essa
    // combinacao de ~= com um valor de multiplas palavras quebra o parser do Sizzle/jQuery
    // ("Syntax error, unrecognized expression"). Solução: cy.contains(texto) sem seletor evita
    // esse fallback.
    cy.contains('Beyond Operação Interno').click()
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

      // NOVO ACHADO (rodada 36): "Nova Operacao" e um wizard conversacional ("Beyond, assistente
      // virtual"), nao um formulario tradicional. Passo 6 do roteiro (navegar ate o servico)
      // provavelmente acontece clicando em respostas/botoes do chat. Mapeando a proxima etapa.
      cy.contains('button', 'Olá').click()
      cy.wait(2500)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR OLA NO CHAT:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('07-apos-clicar-ola-no-chat')

      // NOVO ACHADO (rodada 37): assistente pergunta se mantem o produto da ultima operacao
      // (texto mostra "PRODUTO" ao inves do nome real - possivel bug de template) ou troca.
      // Roteiro pede explicitamente AQUISICAO -> ANTECIPACAO DE DUPLICATA -> DUPLICATA -> SERVICO
      // -> BOLETO (passo 6), entao clicando "Trocar" pra escolher explicitamente em vez de confiar
      // no "Manter" ambiguo.
      cy.contains('button', 'Trocar').click()
      cy.wait(2500)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR TROCAR:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('08-apos-clicar-trocar')

      // NOVO ACHADO (rodada 38): "Trocar" abre uma lista de botoes de produto (COBRANCA SIMPLES,
      // AQUISICAO, AQUISICAO ANCORA, ...). Passo 6 do roteiro pede especificamente "AQUISICAO"
      // (o produto base, nao uma variante como "AQUISICAO ANCORA"/"AQUISICAO FIDUCIARIA" etc) -
      // usando regex de match exato pra nao cair numa variante por substring.
      cy.contains('button', /^AQUISICAO$/).click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR AQUISICAO:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('09-apos-clicar-aquisicao')

      // NOVO ACHADO (rodada 39): apos AQUISICAO, chat pergunta o tipo de produto do negocio.
      // Passo 6 do roteiro continua com "ANTECIPACAO DE DUPLICATA".
      cy.contains('button', /^ANTECIPACAO DE DUPLICATA$/).click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR ANTECIPACAO DE DUPLICATA:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('10-apos-clicar-antecipacao-de-duplicata')

      // NOVO ACHADO (rodada 40): sub-categorias oferecidas: DUPLICATA, DUPLICATA INTERCOMPANY,
      // DUPLICTA INTERCOMPANY (nota: ha um typo real no app, "DUPLICTA" sem o "A" - documentado
      // em docs/documentacao.md como achado, nao e erro da nossa spec). Passo 6 do roteiro pede
      // "DUPLICATA" (a base, nao intercompany).
      cy.contains('button', /^DUPLICATA$/).click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR DUPLICATA:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('11-apos-clicar-duplicata')

      // NOVO ACHADO (rodada 41): opcoes finais oferecidas sao "PRODUTO" e "SERVICO" - bate com o
      // passo 6 do roteiro (...DUPLICATA -> SERVICO -> BOLETO). Clicando SERVICO.
      cy.contains('button', /^SERVICO$/).click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR SERVICO:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('12-apos-clicar-servico')

      // NOVO ACHADO (rodada 42): opcoes finais BOLETO, ESCROW SEM/COM TRAVA, PRE-IMPRESSO,
      // COMISSARIA, BOLETO ESPECIAL - bate com o ultimo elo do passo 6 do roteiro (...SERVICO ->
      // BOLETO). Clicando BOLETO (base, nao "BOLETO ESPECIAL").
      cy.contains('button', /^BOLETO$/).click()
      cy.wait(2000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR BOLETO:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('13-apos-clicar-boleto')

      // NOVO ACHADO (rodada 43): apos escolher BOLETO, o chat oferece "Voltar"/"Continuar" -
      // conclui a escolha do produto (passo 6 completo: AQUISICAO -> ANTECIPACAO DE DUPLICATA ->
      // DUPLICATA -> SERVICO -> BOLETO). Clicando Continuar pra seguir pro passo 7 (selecionar
      // conta).
      // INVESTIGACAO (rodada 45): rodada 44 mostrou que apos "Continuar" a lista de elementos
      // textuais ficou identica a de antes do clique (sem elemento novo), e o screenshot mostrou o
      // painel "Nova Operacao" duplicado verticalmente. Instrumentando com screenshot fullPage e
      // log de rede (registrado no intercept top-level, fora do cy.origin - cy.intercept() nao e
      // suportado dentro do callback do cy.origin) pra confirmar se o clique sequer disparou uma
      // chamada ao backend.
      cy.contains('button', /^Continuar$/).click()
      cy.wait(5000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], input, [role="menuitem"], li, [role="option"]')]
          .map((el) => (el.tagName === 'INPUT' ? `INPUT[name=${el.getAttribute('name')},placeholder=${el.getAttribute('placeholder')}]` : el.textContent.trim()))
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR CONTINUAR:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('14-apos-clicar-continuar', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR CONTINUAR: ' + loc.href + '\n', { flag: 'a+' })
      })

      // INVESTIGACAO (retomada apos correcao do Thiago): a captura anterior so olhava tags
      // especificas (button/label/li/etc) - se a conta pre-selecionada estiver renderizada num
      // div/span/Card sem estar dentro dessas tags, o scraper anterior nao pegaria. Dump do
      // ultimo bloco de mensagem do chat (o mais recente, nao os duplicados anteriores) em texto
      // bruto pra achar qualquer coisa relacionada a conta bancaria.
      cy.get('body').then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO COMPLETO DO BODY APOS CONTINUAR:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      // Tambem lista qualquer elemento clicavel (cursor pointer) que nao seja button/a, e
      // qualquer coisa com classe/atributo que sugira "conta"/"banc"/"agencia".
      cy.get('body').then(($body) => {
        const candidatos = [...$body.find('*')]
          .filter((el) => {
            const cls = (el.className && typeof el.className === 'string') ? el.className.toLowerCase() : ''
            const txt = el.textContent || ''
            return (cls.includes('card') || cls.includes('conta') || cls.includes('account') || cls.includes('banc'))
              && txt.trim().length > 0 && txt.trim().length < 300
          })
          .map((el) => `<${el.tagName.toLowerCase()} class="${el.className}"> ${el.textContent.trim().slice(0, 200)}`)
        cy.writeFile('cypress/debug-output.txt', '\nCANDIDATOS A ELEMENTO DE CONTA (por classe):\n' + JSON.stringify([...new Set(candidatos)], null, 2), { flag: 'a+' })
      })

      // ACHADO (retomada apos correcao do Thiago, rodada 48): o dump de texto bruto do body
      // revelou que o chat ja tinha avancado, apos o clique anterior em "Continuar", para uma nova
      // mensagem: "Sua conta de recebimento e: ITAU - Agencia: 6200 - Conta: 01013-7. Deseja
      // continuar?" com seu proprio par Voltar/Continuar. O scraper por tag nao capturava esse
      // texto puro, e o dedup via Set escondia que havia um SEGUNDO par Voltar/Continuar mais
      // recente (o do produto e o da conta tem o mesmo texto). O "painel duplicado" nao e bug -
      // e o historico normal do chat acumulando mensagens. Passo 7 do roteiro (selecionar
      // qualquer conta) fica satisfeito pela conta pre-selecionada (ITAU) - clicando no
      // "Continuar" MAIS RECENTE (.last()) para confirmar a conta e avancar ao passo 8.
      cy.get('body').should(($body) => {
        expect($body.text()).to.include('Sua conta de recebimento')
      })
      // ACHADO (rodadas 49-50): `cy.contains('button', regex)` sempre retorna so o PRIMEIRO
      // elemento que bate no DOM (mesmo encadeando .filter/.last depois, o subject ja chegou com
      // 1 unico elemento) - com o painel duplicado no DOM, esse primeiro "Continuar" e o de uma
      // copia oculta (`display:none`), entao nem `.last()` nem `.filter(':visible')` sozinhos
      // resolvem. Corrigido: `cy.get('button')` pega TODOS os botoes primeiro, filtra os
      // visiveis, e so DEPOIS localiza pelo texto - assim considera todas as copias antes de
      // filtrar.
      cy.get('button').filter(':visible').contains(/^Continuar$/).click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO COMPLETO DO BODY APOS CONFIRMAR CONTA:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('15-apos-confirmar-conta', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS CONFIRMAR CONTA: ' + loc.href + '\n', { flag: 'a+' })
      })

      // Passo 8 do roteiro: incluir "por digitacao" (nao por upload de arquivo). Achado (rodada
      // 51): apos confirmar a conta, o chat pergunta "Certo. Qual o tipo de entrada voce vai
      // utilizar nesta operacao?" com botoes Voltar / Upload de arquivo / Digitacao. Usando o
      // mesmo padrao get+filter(:visible)+contains para pegar o botao certo entre as copias.
      cy.get('body').should(($body) => {
        expect($body.text()).to.include('Qual o tipo de entrada')
      })
      cy.get('button').filter(':visible').contains(/^Digitação$/).click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO COMPLETO DO BODY APOS CLICAR DIGITACAO:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('16-apos-clicar-digitacao', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR DIGITACAO: ' + loc.href + '\n', { flag: 'a+' })
      })

      // NOVO ACHADO (rodada 52): a partir daqui e um formulario tradicional ("Adicionar Titulos"),
      // nao mais o wizard de chat. Passo 9 do roteiro (Cad Pessoa via CPF). O placeholder
      // "CNPJ/CPF" visto na tela nao bate com input[placeholder=...] (rodada 53 nao achou) -
      // provavelmente e um label flutuante do MUI, nao o atributo placeholder nativo. Dump de
      // todos os inputs (name/placeholder/aria-label/id) da area "Adicionar Titulos" pra achar o
      // seletor certo sem arriscar outro clique as cegas.
      cy.get('body').then(($body) => {
        const inputs = [...$body.find('input')].map((el) => ({
          name: el.getAttribute('name'),
          placeholder: el.getAttribute('placeholder'),
          ariaLabel: el.getAttribute('aria-label'),
          id: el.id,
          type: el.getAttribute('type'),
        }))
        cy.writeFile('cypress/debug-output.txt', '\nINPUTS NA TELA ADICIONAR TITULOS:\n' + JSON.stringify(inputs, null, 2), { flag: 'a+' })
      })

      // ACHADO (rodada 54): nenhum input tem name/placeholder/aria-label - os rotulos vistos na
      // tela sao <label> flutuantes do MUI (com atributo `for` apontando pro id do input, tipo
      // "mui-XX"). Localizando o input do CNPJ/CPF pelo label associado em vez de placeholder.
      cy.contains('label', 'CNPJ/CPF').invoke('attr', 'for').then((inputId) => {
        cy.writeFile('cypress/debug-output.txt', '\nID DO INPUT CNPJ/CPF: ' + inputId + '\n', { flag: 'a+' })
        cy.get('#' + inputId).type('11144477735')
      })
      cy.screenshot('17-apos-digitar-cpf')
      // ACHADO (rodada 55): input identificado por label->for (id "mui-17"), mascara aplicou
      // "111.444.777-35" automaticamente. O botao de busca e um MuiIconButton com svg
      // data-testid="SearchIcon", dentro de um MuiInputAdornment irmao do input (mesmo
      // MuiInputBase-root pai). Clicando nele (Cad Pessoa, passo 9 do roteiro) pra consultar o
      // CPF de teste digitado.
      cy.get('svg[data-testid="SearchIcon"]').closest('button').click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS CLICAR BUSCAR CPF:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('18-apos-buscar-cpf', { capture: 'fullPage' })
      // ACHADO (rodada 56): a busca preencheu automaticamente Nome, Email, CEP, Logradouro,
      // Bairro, Cidade, UF a partir do CPF de teste (111.444.777-35) - a screenshot confirma
      // (Telefone continuou vazio, o cadastro nao tinha telefone). $body.text() nao capturou os
      // valores preenchidos porque textContent de <input> nao inclui o atributo `value` - por
      // isso o dump de texto bruto ficou "vazio" mesmo com os campos preenchidos (nao e bug, e
      // limitacao da tecnica de dump). Passo 9 do roteiro concluido (Cad Pessoa/sacado).
      // Passo 10: preencher os demais campos do titulo (Documento, Valor, Vencimento). Mapeando
      // todos os labels->for da tela pra montar os seletores certos antes de digitar.
      cy.get('body').then(($body) => {
        const labels = [...$body.find('label[for]')].map((el) => ({ texto: el.textContent.trim(), for: el.getAttribute('for') }))
        cy.writeFile('cypress/debug-output.txt', '\nLABELS->FOR NA TELA ADICIONAR TITULOS:\n' + JSON.stringify(labels, null, 2), { flag: 'a+' })
      })

      // ACHADO (rodada 57): so existe 1 conjunto de labels Documento/Chave NF-e/Valor/
      // Vencimento/Desconto/Data Limite Desconto - a "segunda fileira" vista na screenshot 16/18
      // e a mesma armadilha ja conhecida de painel duplicado (copia oculta/fantasma), nao 2
      // titulos reais. Preenchendo passo 10 do roteiro: Documento e Valor e Vencimento (campos com
      // orientacao clara do roteiro); Chave NF-e/Desconto/Data Limite Desconto ficam em branco
      // (opcionais, sem orientacao especifica).
      // ACHADO/CORRECAO (rodada 66): os ids `mui-NN` sao gerados sequencialmente pelo React
      // (`useId`) e MUDAM de execucao pra execucao dependendo de quantos outros componentes com id
      // auto-gerado ja montaram antes na mesma sessao - hardcoded `#mui-29` etc (rodadas 57-65)
      // funcionou por coincidencia em algumas rodadas e quebrou nesta (`#mui-32` nunca encontrado,
      // porque desta vez Documento saiu como mui-34). Corrigido pra sempre resolver o id certo a
      // partir do texto do label (mesmo padrao ja usado pro campo CNPJ/CPF), nunca hardcoded.
      // ACHADO (rodada 75): funcoes definidas no escopo top-level do arquivo (fora do cy.origin())
      // nao sao acessiveis de dentro do callback - mesma restricao ja documentada pra variaveis
      // (contexto serializado/isolado). Gerando o valor inline em vez de chamar
      // gerarDocumentoAleatorio() (que so serve de referencia/comentario aqui).
      const documentoGerado = Math.random().toString(36).slice(2, 12)
      cy.writeFile('cypress/debug-output.txt', '\nDOCUMENTO GERADO PARA ESTA EXECUCAO (hash aleatoria, correcao do Thiago): ' + documentoGerado + '\n', { flag: 'a+' })
      cy.contains('label', 'Documento').invoke('attr', 'for').then((id) => cy.get('#' + id).type(documentoGerado))
      // Correcao do Thiago (2026-09-16): valor de teste alterado de R$ 1.000,00 para R$ 100.000,00.
      cy.contains('label', /^Valor$/).invoke('attr', 'for').then((id) => cy.get('#' + id).type('100000,00'))
      cy.contains('label', 'Vencimento').invoke('attr', 'for').then((id) => cy.get('#' + id).type('2026-12-31', { force: true }))
      cy.screenshot('19-apos-preencher-titulo', { capture: 'fullPage' })
      cy.get('body').then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS PREENCHER TITULO:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })

      // ACHADO (rodada 59): preencher os campos (Documento/Valor/Vencimento) atualizou as DUAS
      // copias visuais do painel ao mesmo tempo (mesmo valor "12345"/"1.000,00"/"31/12/2026" nos
      // dois blocos da screenshot) - confirma que a "duplicacao" e so um artefato visual de
      // renderizacao (2 montagens do mesmo componente compartilhando o mesmo estado por baixo),
      // nao 2 titulos de fato distintos nem um travamento. Clicando "Salvar" pra confirmar o
      // titulo (ultimo pedaco do passo 10) antes de tentar "Gerar Operacao" (passo 11).
      cy.get('button').filter(':visible').contains(/^Salvar$/).click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS CLICAR SALVAR:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('20-apos-clicar-salvar', { capture: 'fullPage' })

      // ACHADO (rodada 61): "Salvar" adicionou UM titulo (nao 2) numa tabela real (CNPJ/CPF,
      // Documento, Valor, Vencimento, Desconto, Data Limite Desconto, Chave NF-e, Acoes) -
      // confirma de vez que a "duplicacao" era so renderizacao, nao dado duplicado. O botao
      // "Gerar Operacao" (antes desabilitado/cinza) ficou habilitado. Passo 10 do roteiro
      // concluido. Clicando "Gerar Operacao" (passo 11).
      cy.get('button').filter(':visible').contains(/^Gerar Operação$/).click()
      cy.wait(4000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS CLICAR GERAR OPERACAO:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('21-apos-gerar-operacao', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS GERAR OPERACAO: ' + loc.href + '\n', { flag: 'a+' })
      })

      // ACHADO (rodada 61->novo ciclo): "Gerar Operacao" abriu um modal de confirmacao ("Confirma
      // a geracao da operacao para os titulos digitados? Cancelar / Confirmar"), sem a
      // duplicacao visual de antes. Passo 11 do roteiro ainda nao concluido - falta confirmar.
      cy.get('button').filter(':visible').contains(/^Confirmar$/).click()
      cy.wait(5000)
      cy.get('body', { timeout: 20000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS CLICAR CONFIRMAR:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('22-apos-clicar-confirmar', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR CONFIRMAR: ' + loc.href + '\n', { flag: 'a+' })
      })

      // ACHADO (rodada 65): "Confirmar" fechou o modal, voltou pro dashboard "Operacoes" e
      // mostrou o toast "Operacao criada com sucesso!" com uma nova linha na tabela (Operacao
      // no 88672, Situacao "enviado"). Passo 11 do roteiro CONCLUIDO. Passo 12: localizar a
      // coluna "Acoes" dessa linha (tabela cortada na screenshot anterior, viewport padrao) -
      // aumentando o viewport e tirando fullPage screenshot antes de tentar clicar as cegas.
      cy.viewport(1920, 1080)
      // CORRIGIDO (rodada 76): a asserção original tinha o número de operação "88672" hardcoded
      // (residuo de uma rodada de exploração antiga) — quebra em qualquer execução que gere um
      // número diferente (esperado, já que cada rodada cria uma operação nova). Verificando de
      // forma genérica que a tabela de operações tem ao menos 1 linha, em vez de um número fixo.
      cy.get('table tbody tr', { timeout: 15000 }).should('have.length.at.least', 1)
      cy.screenshot('23-tabela-operacoes-viewport-largo', { capture: 'fullPage' })
      // A tabela lista todas as operacoes ja criadas nesta exploracao (88672, 88673, 88674, ...),
      // mais recente primeiro. Em vez de fixar um numero, opera-se sempre sobre a PRIMEIRA linha
      // (a operacao que este proprio teste acabou de criar), pra passo 12 sempre avancar a
      // operacao certa mesmo em rodadas futuras que criem numeros novos.
      cy.get('table tbody tr').first().then(($tr) => {
        const numeroOperacao = $tr.find('td').first().text().trim()
        const acoes = [...$tr.find('button, a, svg, [role="button"]')].map((el) => ({
          tag: el.tagName.toLowerCase(),
          testid: el.getAttribute('data-testid'),
          title: el.getAttribute('title'),
          ariaLabel: el.getAttribute('aria-label'),
          texto: el.textContent.trim(),
        }))
        cy.writeFile('cypress/debug-output.txt', '\nNUMERO DA OPERACAO RECEM-CRIADA (1a linha da tabela): ' + numeroOperacao + '\n', { flag: 'a+' })
        // Persistido em arquivo separado (nao so no debug-output.txt) para o 2o teste desta spec
        // (verificacao no Monitor Diario do Beyond BackOffice, passos 13-14 do roteiro) ler qual
        // numero de operacao procurar - cada rodada cria um numero novo.
        cy.writeFile('cypress/ultima-operacao.json', JSON.stringify({ numeroOperacao }))
        cy.writeFile('cypress/debug-output.txt', '\nACOES NA LINHA DA OPERACAO RECEM-CRIADA:\n' + JSON.stringify(acoes, null, 2), { flag: 'a+' })
        // ACHADO (validado nesta rodada): a coluna Acoes tem 5 icones - "Documentos",
        // "Arquivo Aceite" (aparece desabilitado, classe Mui-disabled), "Avancar"
        // (data-testid NextPlanIcon, habilitado), "Editar" (aria-label direto no botao), e
        // "Excluir" - cada um dentro de um <div aria-label="..."> que envolve o <button>. O
        // "Avancar" do passo 12 do roteiro e esse icone com aria-label="Avancar" no div pai.
        const ultimaTd = $tr.find('td').last()
        cy.writeFile('cypress/debug-output.txt', '\nHTML DA COLUNA ACOES (operacao recem-criada):\n' + ultimaTd.prop('outerHTML'), { flag: 'a+' })
      })

      // Passo 12 do roteiro: avancar a operacao recem-criada a partir do dashboard de Operacoes,
      // clicando no icone "Avancar" (div[aria-label="Avançar"] > button, com data-testid
      // NextPlanIcon). Confirma antes que o botao nao esta desabilitado (o icone "Arquivo Aceite"
      // vizinho aparece desabilitado por padrao - nao confundir os dois).
      cy.get('table tbody tr').first().find('div[aria-label="Avançar"]').should('not.have.class', 'Mui-disabled')
      cy.get('table tbody tr').first().find('div[aria-label="Avançar"] button').filter(':visible').click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS CLICAR AVANCAR:\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
      })
      cy.screenshot('24-apos-clicar-avancar', { capture: 'fullPage' })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS CLICAR AVANCAR: ' + loc.href + '\n', { flag: 'a+' })
      })
    })

    cy.then(() => {
      cy.writeFile('cypress/debug-output.txt', '\nTODAS AS CHAMADAS DE REDE DO TESTE (ate aqui):\n' + JSON.stringify(todasAsChamadas, null, 2), { flag: 'a+' })
    })
  })

  // Passos 13-14 do roteiro: verificar no Beyond BackOffice (app diferente, ver
  // docs/documentacao.md) que a operacao avancada aparece no Monitor Diario com a etapa
  // "Inclusao OPE" concluida. Le o numero da operacao gravado pelo teste anterior (cada rodada
  // cria uma operacao nova). Reaproveita a navegacao ja mapeada pelo SupE2eAutomation
  // (Home -> "Beyond BackOffice" -> "Comercial" -> Monitor Diario), mas essa tela em si (Monitor
  // Diario, busca, tabela) ainda precisa ser mapeada aqui de fato - a extensao abaixo e a primeira
  // tentativa.
  it('verifica a operacao avancada no Monitor Diario do Beyond BackOffice', () => {
    cy.readFile('cypress/ultima-operacao.json').then(({ numeroOperacao }) => {
      cy.writeFile('cypress/debug-output.txt', '\n\n=== TESTE 2: MONITOR DIARIO === NUMERO DE OPERACAO A PROCURAR: ' + numeroOperacao + '\n', { flag: 'a+' })

      // INVESTIGACAO (rodada 83): rodadas 82-83 pararam com a pagina em branco em beyond-hml
      // (sem erro Cypress, so timeout esperando "Beyond BackOffice"). Capturando rede + erros JS
      // (mesmo padrao ja usado no teste 1) pra distinguir SPA lenta de verdade travada/erro.
      const chamadasTeste2 = []
      cy.intercept({ url: '**', middleware: true }, (req) => {
        req.on('response', (res) => {
          chamadasTeste2.push(`${res.statusCode} ${req.method} ${req.url}`)
        })
      })
      cy.on('window:before:load', anexarCapturaDeErros)

      cy.visit(ambiente.appBaseUrl, { onBeforeLoad: anexarCapturaDeErros })
      cy.wait(3000)
      // ACHADO (rodada 89): a deteccao antiga comparava a URL contra o host fixo de
      // ambiente.keycloakUrl (keycloak-new-2...) - nesta rodada o realm "multiplicacapital" (Beyond
      // BackOffice) foi servido por um host DIFERENTE (`lgni.grupomultiplica.com.br`, mesmo padrao
      // de URL Keycloak `/auth/realms/.../protocol/openid-connect/auth`), entao `foiPraKeycloak`
      // avaliou false, o bloco de login foi pulado inteiro, e o teste seguiu tentando comandos
      // contra o app como se ja estivesse logado - resultando em
      // "expected to run against origin beyond-hml but the application is at origin lgni...".
      // Corrigido: detectar Keycloak de forma generica pelo padrao de PATH (`/auth/realms/`), nao
      // por um hostname fixo - e usar a origin de fato observada na URL para o cy.origin(), em vez
      // de sempre usar ambiente.keycloakUrl.
      cy.url().then((url) => {
        const urlObj = new URL(url)
        const foiPraKeycloak = urlObj.pathname.includes('/auth/realms/')
        cy.writeFile('cypress/debug-output.txt', '\nHOST DE LOGIN DETECTADO (Beyond BackOffice): ' + urlObj.origin + ' | foiPraKeycloak: ' + foiPraKeycloak + '\n', { flag: 'a+' })
        if (foiPraKeycloak) {
          cy.origin(
            urlObj.origin,
            { args: { username: ambiente.username, password: ambiente.password, selectors: KEYCLOAK_SELECTORS } },
            ({ username, password, selectors }) => {
              cy.get(selectors.username).should('be.visible').clear().type(username, { log: false })
              cy.get(selectors.password).should('be.visible').clear().type(password, { log: false })
              cy.get(selectors.submit).should('be.visible').click()
              // INVESTIGACAO (rodada 81): rodada 80 travou nesta mesma tela (URL nunca saiu do
              // keycloak-new-2 mesmo apos 20s) - capturando o que aparece na tela apos o clique
              // (texto bruto) pra entender se e erro de credencial, tela extra (consentimento/2FA),
              // ou apenas lentidao.
              // CORRIGIDO (rodada 94): o screenshot fullPage logo apos o clique (`cy.wait(3000)` +
              // `cy.screenshot(...)`) quebrava o runner com a mesma armadilha ja documentada em
              // docs/documentacao.md ("cy.screenshot() logo apos cy.visit() quebra o runner") -
              // desta vez no redirect pos-login pra beyond-hml (fundo com padrao de pontos, mesma
              // familia de tela animada). O login em si funcionava (a screenshot de FALHA do
              // Cypress, tirada automaticamente, mostrava a Home do Beyond ja carregada) - so o
              // screenshot manual diagnostico e que derrubava o teste. Removido; o texto bruto
              // abaixo (sem risco) e as screenshots mais adiante (apos <main> estabilizar) ja
              // documentam esse trecho o suficiente.
              cy.wait(3000)
              cy.get('body').then(($body) => {
                cy.writeFile('cypress/debug-output.txt', '\nTEXTO BRUTO APOS SUBMETER LOGIN (Beyond BackOffice, dentro do cy.origin):\n' + $body.text().replace(/\s+/g, ' '), { flag: 'a+' })
              })
            }
          )
        }
      })
      // ACHADO (rodada 80): o realm do Keycloak usado pelo Beyond BackOffice ("multiplicacapital")
      // e diferente do realm do Beyond Banking ("beyondbanking-hml", ja mapeado). Com um cy.wait
      // fixo de 4000ms o redirect de volta pro app ainda nao tinha acontecido (comando seguinte
      // falhou com "expected to run against origin beyond-hml but the application is at origin
      // keycloak-new-2"). Trocando por um cy.url() com retry/timeout maior, que so segue quando o
      // redirect de fato sair do dominio do Keycloak.
      // CORRIGIDO (rodada 89): "not.include('keycloak-new-2')" nao cobre o host alternativo
      // "lgni" visto nesta rodada - trocando pra checagem generica pelo padrao de path.
      cy.url({ timeout: 20000 }).should((url) => {
        expect(url, 'nao deveria mais estar numa tela de login do Keycloak').to.not.match(/\/auth\/realms\//)
      })
      cy.location().then((loc) => {
        cy.writeFile('cypress/debug-output.txt', '\nURL APOS LOGIN (Beyond BackOffice): ' + loc.href + '\n', { flag: 'a+' })
      })

      // ACHADO (rodada 82): a screenshot de falha mostrou a pagina totalmente BRANCA em
      // beyond-hml.grupomultiplica.com.br logo apos o login - a SPA ainda nao tinha montado (nao e
      // erro, so lentidao de boot). cy.contains('Beyond BackOffice') com timeout default (4s)
      // nao era suficiente. Aumentando o timeout explicitamente em vez de um cy.wait fixo.
      // ACHADO (rodada 85): mesmo com timeout de 20s, o body continuou com innerHTML de so 163
      // chars: `<main></main><script>System.import("@mc/container");</script>...` - a aplicacao e
      // uma arquitetura de micro-frontend (SystemJS/import-map-overrides) que carrega o container
      // principal dinamicamente, e o <main> nunca chegou a ganhar filhos dentro da janela de espera
      // usada ate aqui. CHAMADAS DE REDE ficou vazio nas ultimas tentativas (possivel cache de
      // disco nao visivel ao cy.intercept, ja que o Electron reaproveita o profile entre rodadas
      // desta mesma sessao de exploracao) - nao da pra concluir por rede se e boot lento real ou
      // travamento. Proximo passo: esperar o <main> ganhar conteudo real (em vez de tempo fixo)
      // antes de procurar o texto, com um timeout bem maior para acomodar o boot do container.
      cy.get('main', { timeout: 45000 }).should(($main) => {
        expect($main.children().length, 'main deveria ganhar filhos apos o boot do container').to.be.greaterThan(0)
      })
      cy.window().then((win) => {
        cy.writeFile('cypress/debug-output.txt', '\nTITLE: ' + win.document.title + ' | BODY innerHTML length: ' + win.document.body.innerHTML.length, { flag: 'a+' })
        cy.writeFile('cypress/debug-output.txt', '\nERROS JS CAPTURADOS (teste 2): ' + JSON.stringify(win.__errosCapturados || []), { flag: 'a+' })
      })
      cy.writeFile('cypress/debug-output.txt', '\nCHAMADAS DE REDE (teste 2, apos <main> ganhar filhos):\n' + JSON.stringify(chamadasTeste2, null, 2), { flag: 'a+' })
      cy.screenshot('27b-antes-de-procurar-beyond-backoffice', { capture: 'fullPage' })
      cy.contains('Beyond BackOffice', { timeout: 30000 }).click()
      cy.wait(2000)
      cy.contains('Comercial').click()
      cy.wait(3000)
      cy.get('body', { timeout: 15000 }).then(($body) => {
        const textos = [...$body.find('label, legend, h1, h2, h3, h4, button, a, [role="button"], [role="menuitem"], li')]
          .map((el) => el.textContent.trim())
          .filter((t) => t && t.length > 0 && t.length < 150)
        cy.writeFile('cypress/debug-output.txt', '\nELEMENTOS APOS CLICAR COMERCIAL:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('25-dashboard-comercial', { capture: 'fullPage' })

      // Drawer lateral so mostra icones - o icone LoopIcon expande revelando o texto dos itens
      // (achado documentado pelo SupE2eAutomation, docs/documentacao.md deste modulo aponta pra
      // la). Tentando o mesmo seletor aqui.
      cy.get('[data-testid="LoopIcon"]').closest('.menu-MuiListItem-root, li, div[role="button"]').click()
      cy.wait(1500)
      cy.get('body').then(($body) => {
        const textos = [...$body.find('*')]
          .map((el) => el.textContent && el.textContent.trim())
          .filter((t) => t && t.length > 0 && t.length < 60 && t.toLowerCase().includes('monitor'))
        cy.writeFile('cypress/debug-output.txt', '\nCANDIDATOS "MONITOR" APOS EXPANDIR DRAWER:\n' + JSON.stringify([...new Set(textos)], null, 2), { flag: 'a+' })
      })
      cy.screenshot('26-apos-expandir-drawer', { capture: 'fullPage' })
    })
  })
})
