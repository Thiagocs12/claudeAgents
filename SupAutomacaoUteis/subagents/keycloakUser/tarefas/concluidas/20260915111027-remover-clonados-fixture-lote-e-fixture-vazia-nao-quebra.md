---
id: 20260915111027-remover-clonados-fixture-lote-e-fixture-vazia-nao-quebra
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição
Ajustar a clonagem em lote (`cy.clonarUsuariosKeycloakEmLote`, cenário `@clonarUsuariosEmLote`,
fixture `cypress/fixtures/usuariosParaClonar.json`) em dois pontos:

1. **Ao final da execução, remover do arquivo de fixture os usuários que foram clonados com
   sucesso** — para não tentar clonar de novo o mesmo usuário numa próxima execução do cenário.
   Usuários que falharam (dúvida bloqueante: não encontrado em PROD, role/grupo sem correspondente
   em HML, etc.) **devem permanecer no arquivo** para permitir nova tentativa depois que o motivo
   for corrigido — só remove quem teve `ok: true`.
2. **Mudar o comportamento de fixture vazia**: hoje `executarClonagem`/o fluxo em lote lança erro
   ("Fixture de usuários para clonar em lote está vazia") quando o mapa está vazio — isso era um
   guard-rail intencional (documentado em `docs/documentacao.md`). Com a remoção automática do
   item 1, fixture vazia passa a ser um estado normal (nada mais pendente de clonar), não mais uma
   condição de erro: trocar o `throw` por um log informativo (ex. "Nenhum usuário pendente de
   clonagem na fixture — nada a fazer") e seguir sem quebrar o cenário/teste.

## Critérios de aceite
- Rodando o cenário `@clonarUsuariosEmLote` com 1+ usuários que clonam com sucesso, ao final da
  execução a fixture `usuariosParaClonar.json` não contém mais esses usuários (permanecem só os
  que falharam, se houver).
- Rodando o cenário com a fixture já vazia (`{}`), a execução loga a mensagem informativa e
  **não** falha/lança erro — cenário passa normalmente.
- Rodando o cenário com um mapa contendo só usuários que vão falhar (dúvida bloqueante), a fixture
  permanece inalterada ao final (nenhum removido).
- Comportamento do modo único (`cy.clonarUsuarioKeycloak`, cenário `@keycloakUsuario`) não é
  afetado — essa mudança é só do modo em lote e da fixture que ele usa.
- `npm run lint` e `npm run test:safety` continuam passando (com os novos casos cobrindo remoção
  parcial, remoção nenhuma por falha total, e fixture vazia não quebrando).
- `README.md`/`CLAUDE.md` do repo atualizados na seção de clonagem em lote refletindo o novo
  comportamento (fixture some sendo "consumida" a cada execução bem-sucedida; vazio deixa de ser
  erro).

## Material de apoio
- Decisões confirmadas pelo Thiago em 2026-09-15 (refinamento desta tarefa):
  - Remover da fixture **somente** os usuários clonados com sucesso — os que falharam continuam lá.
  - Fixture vazia deve virar log + segue, **não** mais lançar erro (muda o guard-rail anterior,
    documentado em `subagents/keycloakUser/docs/documentacao.md`, seção "Tarefa concluída:
    clonagem em lote").
- Contexto da implementação atual (referência para quem pegar a tarefa): lógica pura em
  `repo/cypress/support/shared/clonagemUsuarioKeycloak.js` (`clonarUsuariosEmLote`), orquestração
  em `repo/cypress/support/commands/usuariosKeycloak.js` (`executarClonagem`), fixture em
  `repo/cypress/fixtures/usuariosParaClonar.json` (template vazio versionado, nunca populado com
  usuário real por um agente).
