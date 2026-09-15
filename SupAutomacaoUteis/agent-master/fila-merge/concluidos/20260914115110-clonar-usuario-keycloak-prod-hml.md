---
id: 20260914115110-clonar-usuario-keycloak-prod-hml
modulo: keycloakUser
branch: keycloakUser/clonar-usuario-prod-hml
data: 2026-09-14
---

## Resumo

Novo recurso sob demanda: clonagem de usuário do Keycloak de PRODUÇÃO para HML (realm
`multiplicacapital`), com novo username/senha a cada execução (`cypress run --env
usuarioOrigem=...,novoUsername=...,novaSenha=...`), mantendo realm roles, client roles
(de todos os clients em que o usuário tiver role atribuída), grupos e atributos —
exceto username/senha.

## O que foi feito

- `cypress/support/commands/usuariosKeycloak.js` — comando `cy.clonarUsuarioKeycloak`.
- `cypress/support/shared/clonagemUsuarioKeycloak.js` — lógica pura (payload de
  criação, extração de realm/client roles e grupos), coberta por `node:test`.
- `cypress/utils/mapeamentoUsuarios.js` — mapeamento do domínio.
- `cypress/e2e/features/gerenciamentoDeUsuarios.feature` +
  `cypress/support/step_definitions/gerenciamentoDeUsuarios.js` — feature/steps
  `@keycloakUsuario`.
- `README.md`/`CLAUDE.md` do repo atualizados documentando o novo domínio.

## Autoteste já rodado pelo subAgent

- `npm run lint` — 0 erros (4 warnings pré-existentes, não relacionados a este PR).
- `npm run test:safety` — 27/27 (10 novas, cobrindo payload de criação + extração de
  realm role + client role + grupo do usuário de origem).

## Não rodado pelo subAgent (fica para a validação do Agent Master / teste manual)

Não rodei o cenário `@keycloakUsuario` fim a fim contra o Keycloak real de PROD/HML:
exigiria escolher um `usuarioOrigem` real de produção, e a regra do módulo é nunca
decidir sozinho qual usuário copiar. Sugiro ao Agent Master/Thiago escolherem um
usuário real de PROD (com pelo menos uma realm role, uma client role e um grupo, para
cobrir o critério de aceite) para o primeiro teste manual em HML.

## PR

https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/5 — aberto pelo Agent Master em 2026-09-14, aguardando aprovação manual do Thiago.
