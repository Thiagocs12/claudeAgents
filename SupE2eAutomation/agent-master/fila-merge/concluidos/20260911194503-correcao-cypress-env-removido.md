---
tarefa: 20260911194503-correcao-cypress-env-removido
modulo: geral
branch: fix/pin-cypress-versao-15.20.1
data: 2026-09-11
---

## Resumo

Correção sobre a tarefa `20260911181703-login-keycloak-usuario-master`: erro
"Cypress.env() was removed in Cypress version 16.0.0" reportado no teste manual de
`C:\multiplica\cypress-e2e`.

Causa raiz identificada (não é bug de código): o range `^15.14.2` do `package.json` permitiu que
uma instalação concorrente/acidental do Cypress 16.x no cache global do Windows
(`%LOCALAPPDATA%\Cypress\Cache`, compartilhado entre projetos) fosse resolvida no lugar da 15.x
num `npx cypress open` manual. `environments.js` está correto — `Cypress.env()` só está
`@deprecated` na 15.x, não removida.

Alteração: pin exato `"cypress": "15.20.1"` em `package.json` + `package-lock.json`
regenerado (`npm install --package-lock-only`), para impedir esse tipo de resolução acidental em
`npm ci`/`npm install` futuros.

## Autoteste realizado

- `npx cypress version`: package e binary em 15.20.1, consistentes.
- `npx cypress run --spec cypress/e2e/features/shared/login.feature`: 2/2 passando (rodado 2x
  seguidas para confirmar estabilidade; uma primeira tentativa teve falha transiente de rede no
  `cy.origin()` ao abrir o Keycloak, não relacionada à mudança).
- `npx cypress open` (modo interativo, alvo do bug original): não reproduz mais o erro
  "Cypress.env() was removed" — apenas o aviso de depreciação padrão da 15.x
  (`allowCypressEnv`/`Cypress.env() será removido em versão futura`), que é esperado e não bloqueia
  a execução.

## Nenhuma variável de `.env` nova

Nenhuma variável nova em `.env.example` nesta tarefa.
