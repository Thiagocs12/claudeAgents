---
id: 20260911181703-login-keycloak-usuario-master
modulo: geral
branch: feature/login-keycloak-usuario-master
---

## Resumo

Fundação de login via Keycloak (SSO) para o módulo `geral`: `LoginPage`, `cy.loginComoPerfil`
(com `cy.session`), estrutura de usuários por perfil (`environments.js`/`.env.example`, perfil
`master` em `hml`), cenários de login válido/inválido via Cucumber
(`cypress-cucumber-preprocessor` instalado e configurado). `README.md`/`CLAUDE.md` do repo
atualizados para refletir o estado atual.

Autoteste (`npx cypress run --spec "cypress/e2e/features/shared/login.feature"`): 2/2 passando.

Branch partiu de `reviewAgents` em `0492943` (sem divergência adicional até o push).
