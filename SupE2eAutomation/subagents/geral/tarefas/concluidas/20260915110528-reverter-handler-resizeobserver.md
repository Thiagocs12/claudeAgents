---
id: 20260915110528-reverter-handler-resizeobserver
modulo: geral
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição
Reverter (correção) o handler de `uncaught:exception` em `cypress/support/e2e.js` que hoje ignora
especificamente `ResizeObserver loop completed with undelivered notifications` (estendido em
2026-09-14 pelo Agent Master, commit `a2f2d88`, na branch `feature/resolucao-viewport-e-video-execucao`
— já mergeado em `reviewAgents`). Segundo o Thiago, esse erro de ResizeObserver está fazendo a
automação quebrar "sem mais nem menos" — não deve continuar sendo mascarado como ruído inofensivo
de browser.

Remover só a checagem dessa mensagem específica no handler — manter intacto o restante do handler,
que também trata o erro conhecido do widget de menu do Beyond
(`Cannot read properties of undefined (reading 'content')`); esse outro tratamento não deve ser
tocado.

## Critérios de aceite
- O handler de `uncaught:exception` em `cypress/support/e2e.js` não ignora mais
  `ResizeObserver loop completed with undelivered notifications` — se esse erro ocorrer de novo, o
  Cypress deve voltar a falhar o teste normalmente (comportamento padrão, sem mascarar).
- O tratamento do erro do widget de menu do Beyond continua funcionando sem alteração.
- Autoteste ao final: rodar `mop/mop-monitor-diario.feature` (o teste que historicamente reproduziu
  o ResizeObserver). O Thiago não espera que volte a falhar — mas se falhar (ResizeObserver ou
  qualquer outro sintoma), registrar como dúvida bloqueante normalmente, sem decidir sozinho
  re-adicionar o handler nem mascarar o erro de novo.

## Material de apoio
- `../../docs/conhecimento-geral.md`, seção "HML/login — mais sintomas de instabilidade além do já
  catalogado `cy.origin`" — histórico completo de quando/por que o handler foi estendido e os
  sintomas já catalogados no MOP.
- Commit que introduziu a exceção a ser revertida: `a2f2d88` (branch
  `feature/resolucao-viewport-e-video-execucao`, já integrado em `reviewAgents`).
