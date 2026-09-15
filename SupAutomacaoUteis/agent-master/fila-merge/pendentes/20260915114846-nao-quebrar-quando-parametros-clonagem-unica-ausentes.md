---
id: 20260915114846-nao-quebrar-quando-parametros-clonagem-unica-ausentes
modulo: keycloakUser
branch: keycloakUser/nao-quebrar-parametros-clonagem-unica-ausentes
data: 2026-09-15
---

## Resumo

Correção reportada pelo Thiago em teste manual na `reviewAgents`: rodar `npx cypress run` sem
`tags=@keycloakUsuario` (suíte completa) — caso em que `usuarioOrigem`/`novoUsername`/`novaSenha`
nunca são passados de propósito — lançava um `Error` bloqueante no cenário `@keycloakUsuario` e
interrompia a execução. Agora loga a mesma mensagem orientativa e segue sem clonar. Mesmo padrão de
design já aplicado na tarefa anterior (`20260915111027`, fixture vazia do modo em lote).

## O que foi feito

- `cypress/support/shared/clonagemUsuarioKeycloak.js` — novas funções puras
  `parametrosClonagemUnicaCompletos({ usuarioOrigem, novoUsername, novaSenha })` e a constante
  `MENSAGEM_PARAMETROS_CLONAGEM_UNICA_AUSENTES`.
- `cypress/support/step_definitions/gerenciamentoDeUsuarios.js` — o `When` do cenário
  `@keycloakUsuario` troca o `throw` por `cy.logExecucao(...)` e não executa a clonagem quando os
  parâmetros estão incompletos (nenhum ou só parte); o `Then` correspondente pula a asserção nesse
  caso (flag `clonagemUnicaPulada`) em vez de falhar.
- `README.md`/`CLAUDE.md` do repo atualizados (seção "Clonagem de Usuário (Keycloak)").
- Modo em lote (`@clonarUsuariosEmLote`) não foi tocado.

## Autoteste já rodado pelo subAgent

- `npm run lint` — 0 erros (mesmos 4 warnings pré-existentes, não relacionados).
- `npm run test:safety` — 45/45 (3 novos: nenhum parâmetro, só parte, os 3 completos).
- Cenário `@keycloakUsuario` fim a fim contra o Keycloak real, 3 casos:
  1. Suíte completa sem `tags` — passou, log confirmado, nenhum erro.
  2. Só `usuarioOrigem` informado (usuário fictício inexistente em PROD, mesmo padrão de
     autotestes anteriores deste módulo) — passou, mesmo log, sem clonagem parcial.
  3. Os 3 parâmetros completos com o mesmo usuário fictício — falhou como esperado
     (`Usuário de origem "..." não encontrado em produção`), confirmando que o modo único com
     parâmetros completos não mudou.
- Revalidado `@clonarUsuariosEmLote` com a fixture vazia (`{}`, estado commitado) — inalterado.

## Não rodado pelo subAgent

Nada pendente — todos os critérios de aceite da tarefa foram cobertos pelo autoteste acima (não
envolve nenhuma decisão sobre usuário real de PROD desta vez, já que o caminho de sucesso da
clonagem em si não foi alterado por esta tarefa).
