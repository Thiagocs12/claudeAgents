---
id: 20260911181703-login-keycloak-usuario-master
modulo: geral
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-11
---

## Descrição

Implementar a automação de UI do fluxo de **login** da aplicação Beyond, que autentica via
redirecionamento (SSO) para o Keycloak. Este é o item de fundação do módulo `geral`: outros
módulos (POC, MOP, etc.) vão depender do comando de login e da estrutura de usuários criados
aqui, então a implementação deve seguir à risca o padrão de arquitetura já documentado no
`README.md`/`CLAUDE.md` do repositório (camadas Pages / Etapas / Esteiras, Cucumber como camada
fina de legibilidade, `cy.session` para cache de sessão por perfil).

Cobrir dois cenários:
- **Login válido**: autenticar com o usuário informado abaixo e confirmar retorno autenticado à
  aplicação Beyond.
- **Login inválido**: usuário/senha incorretos, validando a mensagem de erro exibida pelo
  Keycloak e que o usuário não é autenticado.

Criar também a estrutura de **usuários de teste** (seguindo o padrão `environments.js` já
existente no repositório — mapa de usuários por perfil, por ambiente, carregado via variáveis de
ambiente/`.env`), registrando o usuário abaixo como o perfil **`master`**. Essa estrutura deve
ficar pronta para receber outros perfis/papéis no futuro (próximas tarefas vão adicionar novos
usuários, não redesenhar a estrutura).

### Reaproveitamento de código existente

O próprio `CLAUDE.md` do repositório indica que a lógica de login da antiga branch `fluxoLogin`
deve servir de base para o novo `LoginPage`/`cy.loginComoPerfil`. Essa branch **será apagada**
(histórico já teve seu conteúdo extraído e colado abaixo como referência — nenhum trabalho útil
se perde). Use como ponto de partida, adaptando à estrutura de Pages/commands do padrão atual
(não precisa manter os nomes de arquivo originais):

`cypress/support/commands.js` (branch `fluxoLogin`):
```js
import { getKeycloakConfig, getApiConfig } from './envHelper'

Cypress.Commands.add('loginKeycloak', (username, password) => {
  const keycloakConfig = getKeycloakConfig()
  const keycloakOrigin = new URL(keycloakConfig.loginUrl).origin

  cy.visit(keycloakConfig.loginUrl)

  cy.origin(
    keycloakOrigin,
    { args: { username, password } },
    ({ username, password }) => {
      cy.get('#username').should('be.visible').type(username, { log: false })
      cy.get('#password').should('be.visible').type(password, { log: false })
      cy.get('#kc-login').should('be.visible').click()
    }
  )

  const apiConfig = getApiConfig()
  cy.url({ timeout: 10000 }).should('include', apiConfig.baseUrl)
})
```

`cypress/support/envHelper.js` (branch `fluxoLogin`) — padrão de acesso à config de ambiente via
`Cypress.env('envConfig')`, pode servir de inspiração para como `environments.js` é consumido.

`cypress/e2e/features/fluxoLogin.feature` (branch `fluxoLogin`) — cenário Gherkin de referência
(o `Then` estava incompleto/sem assertiva real; corrigir isso faz parte desta tarefa):
```gherkin
#language: pt

Funcionalidade: Login na plataforma

  Esquema do Cenário: Validar login com diferentes credenciais
    Dado que o usuário acessa a página de login
    Quando ele preenche o email "<email>" e a senha "<senha>" e clica no botão de login
    Então ele deve ver a mensagem "<mensagem>"

    Exemplos:
      | email     | senha    | mensagem                 |
      | valido    | invalido | Bem-vindo ao dashboard   |
      | invalido  | valido   | Email ou senha inválidos |
      | valido    | valido   | Bem-vindo ao dashboard   |
```

## Critérios de aceite

- `cypress/support/pages/shared/LoginPage.js` criado (Page Object puro): seletores e ações de tela
  do Keycloak (`#username`, `#password`, `#kc-login`), sem regra de negócio.
- `cy.loginComoPerfil(perfil)` implementado em `cypress/support/commands.js`, usando `cy.session`
  para cachear a sessão por perfil e evitar relogin desnecessário; internamente usa o `LoginPage`
  e o `cy.origin()` para navegar até o Keycloak.
- `cypress/config/environments.js` estendido com um mapa `usuarios` por perfil para o ambiente
  `hml` (ou equivalente), contendo pelo menos o perfil `master`, carregado via variáveis de
  ambiente (não hardcoded no código).
- `.env.example` atualizado com as novas variáveis necessárias (URL da app, URL do Keycloak,
  usuário/senha do perfil `master`), seguindo a convenção de nomes já usada no arquivo.
- Cenário de **login válido**: usando o perfil `master`, autentica com sucesso e confirma retorno
  autenticado à aplicação Beyond (assertiva real, não `cy.pause()`).
- Cenário de **login inválido**: credenciais incorretas exibem mensagem de erro do Keycloak e o
  usuário permanece não autenticado (assertiva real).
- Ambos os cenários expressos via Cucumber (`.feature` + `step_definitions`), como camada fina que
  apenas invoca o comando/Page — sem lógica de negócio no step definition.
- `cypress-cucumber-preprocessor` (ou equivalente) configurado no projeto (ainda não instalado —
  é pré-requisito desta tarefa, conforme já observado no `CLAUDE.md` do repo).
- Segue o padrão de projeto do `README.md`/`CLAUDE.md` do repositório; atualizar esses arquivos se
  ficarem desatualizados após a implementação (ex.: marcar Cucumber como instalado, documentar a
  variável de ambiente nova).
- Autoteste (`npm test` ou spec específica) executado com sucesso antes de reportar conclusão.

## Material de apoio

- Repositório: https://github.com/Thiagocs12/automacaoUiMultiplica.git (branch base: `reviewAgents`,
  já sincronizada com a arquitetura documentada em `README.md`/`CLAUDE.md`)
- URL da aplicação (Beyond, ambiente HML): https://beyond-hml.grupomultiplica.com.br/
- URL do Keycloak (SSO): https://keycloak-new-2.grupomultiplica.com.br/
- Usuário de teste — perfil `master`:
  - usuário: `automacao`
  - senha: `Automacao@123` (A maiúsculo — corrigido após dúvida em `duvidas.md`, valor anterior `automacao@123` estava incorreto)
- Trecho de código de referência da branch `fluxoLogin` (já removida): ver seção "Reaproveitamento
  de código existente" acima.

## Observação

Ainda não há usuários de teste para outros perfis (`operador`, `aprovador` etc.) provisionados em
HML — isso é uma dependência externa conhecida (documentada no `CLAUDE.md` do repo) e será tratado
em tarefas futuras, à medida que novos usuários forem criados. Esta tarefa cobre apenas o perfil
`master`, deixando a estrutura pronta para receber os demais.
