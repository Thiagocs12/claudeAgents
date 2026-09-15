---
id: 20260914115110-clonar-usuario-keycloak-prod-hml
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-14
---

## Descrição

Criar um recurso reutilizável (comando Cypress + feature/cenário Cucumber, seguindo o padrão do
repositório) para **clonar um usuário do Keycloak de PRODUÇÃO para HML**, no realm
`multiplicacapital`, com um **novo username e nova senha definidos pelo solicitante a cada
execução** — mantendo todo o resto do usuário igual ao original.

Isso é usado para reproduzir em HML o comportamento exato de um usuário real de produção (mesmas
permissões/atributos), sem usar o username/senha reais dele.

O recurso deve ser **parametrizável a cada execução** (não uma lista fixa nem um script de uso
único) — ex. via `cypress --env` (`usuarioOrigem`, `novoUsername`, `novaSenha`), seguindo o
padrão de parametrização já usado no projeto (`Cypress.env(...)`).

### O que deve ser copiado do usuário de origem (PROD) para o novo usuário (HML)

Tudo, **exceto** username e senha:
- Realm roles.
- Client roles — de **todos** os clients em que o usuário tiver role atribuída, não só o client
  configurado em `KEYCLOAK_CLIENT_ID` (usado hoje só pela sincronização de Grupos e Permissões).
  Verificar se a API de administração do Keycloak expõe um endpoint de role-mappings do próprio
  usuário (`GET /users/{id}/role-mappings`) que já devolva isso de forma direta, em vez de precisar
  iterar client por client.
- Grupos (membership) — localizar o grupo correspondente em HML por nome exato, reaproveitando
  `encontrarPorNomeExato` (mesma lógica já usada para grupos em
  `cypress/support/commands/gruposPermissoes.js`).
- Atributos customizados (`attributes`), email, `firstName`/`lastName`, `enabled`,
  `emailVerified`, `requiredActions`.

### Casos que NÃO devem ser decididos sozinhos (registrar dúvida)

- Usuário de origem não encontrado em PROD.
- Uma role/grupo do usuário de origem não tem correspondente em HML (não criar a role/grupo
  faltante — só perguntar).
- O novo username ou o email do usuário original já existe em HML (conflito de criação).
- Qualquer ambiguidade sobre em qual realm os usuários de aplicação realmente vivem — o código
  hoje assume `multiplicacapital` para tudo (automação e aplicação), mas isso deve ser confirmado
  como correto para usuários de aplicação também antes de implementar, se não estiver 100% claro
  pela leitura do `README.md`/`CLAUDE.md` do repo.

### Leitura em PROD é sempre somente-leitura

Buscar o usuário de origem **apenas via GET** no ambiente `keycloakProd` (nunca-escreva nele —
já bloqueado em código, mas reforçando a regra de negócio). A criação do novo usuário e toda
associação de roles/grupos acontece só no ambiente `keycloak` (HML).

## Critérios de aceite

- Rodar o recurso informando um usuário real de PROD + um novo username/senha cria, em HML, um
  usuário funcional com login válido (novo username/senha) e exatamente as mesmas roles
  (realm + todos os clients), grupos e atributos do usuário original — exceto username/senha.
- Rodar de novo para o mesmo `novoUsername` que já existe em HML não deve duplicar nem quebrar
  silenciosamente — deve virar dúvida bloqueante (ver casos acima).
- Autoteste cobre pelo menos: um usuário com role de realm + role de client + grupo, e a
  verificação de que o usuário criado em HML tem tudo isso replicado.
- `README.md`/`CLAUDE.md` do repositório atualizados documentando o novo recurso, seguindo o
  mesmo padrão de documentação das automações existentes (Produtos/Esteiras/Vínculos/Grupos e
  Permissões).

## Material de apoio

- Padrão de autenticação/ambiente já implementado: `cypress/support/commands/ambiente.js`
  (ambientes `keycloak`/`keycloakProd`), `cypress/support/utils.js` (`cy.obterToken`).
- Domínio já existente mais próximo (grupos/roles, não usuários): `cypress/utils/mapeamentoGruposPermissoes.js`
  + `cypress/support/commands/gruposPermissoes.js` + `cypress/support/shared/keycloakHelpers.js`
  (`encontrarPorNomeExato`, `calcularNomesFaltantes`) — reaproveitar o que fizer sentido, mas este
  é um recurso novo (clonagem de usuário), não uma extensão do pipeline de sincronização
  genérico (`sincronizacaoNivel.js`).
- Endpoints de admin do Keycloak já usados no projeto seguem o padrão
  `auth/admin/realms/multiplicacapital/<recurso>` (ver `mapeamentoGruposPermissoes.js`) — o
  equivalente para usuários deve ser `auth/admin/realms/multiplicacapital/users`.
