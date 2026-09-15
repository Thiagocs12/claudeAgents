---
id: 20260914125955-atualizar-claude-md-fluxo-integracao
modulo: geral
branch: feature/atualizar-claude-md-fluxo-integracao
---

## Resumo
Atualizado `repo/CLAUDE.md` (seção "## Project overview" + "## Collaboration workflow") e
`repo/README.md` (seção "## Fluxo de trabalho") para refletir o fluxo de integração vigente desde
2026-09-14: Agent Master faz merge direto (com push) na `reviewAgents` por tarefa validada, sem PR
nem aprovação humana por tarefa; único ponto de revisão manual é o PR único e contínuo
`reviewAgents → main`. Texto antigo (PR por tarefa, "Agent Master never merges or pushes directly")
removido de ambos os arquivos.

Só documentação — sem mudança de código/comportamento de teste.

## Autoteste
Revisão do texto final contra `SupE2eAutomation/CLAUDE.md` (seção 3.3) e
`SupE2eAutomation/docs/conhecimento-geral.md` — consistente com o fluxo descrito lá. Confirmado que
não restou nenhuma menção ao modelo antigo em `repo/CLAUDE.md`/`repo/README.md` (grep por "never
merges or pushes directly", "human-approved Pull Request", "aprovação manual" não retornou nada).

## Encerramento (2026-09-15) — DESCARTADO SEM MERGE, decisão do Thiago
Três tentativas de merge de teste falharam por três sintomas diferentes de
`mop/mop-monitor-diario.feature` (`cy.origin() failed to create a spec bridge`, `ResizeObserver
loop...`, `cy.click() failed because this element is disabled`), mesmo a branch tocando só
documentação. Thiago decidiu abandonar esta tentativa de merge de vez: "reverta tudo, a
`reviewAgents` já funciona, não tem por que mergear nada". Nenhum merge foi finalizado — a
`reviewAgents` permanece sem essa mudança. A branch remota `feature/atualizar-claude-md-fluxo-integracao`
continua existindo, sem uso previsto. Efeito colateral aceito: `repo/CLAUDE.md`/`repo/README.md`
seguem desatualizados quanto ao fluxo de integração vigente — retomar isso exigiria decisão nova do
Thiago. Ver `agent-master/duvidas.md` (`20260914125955-atualizar-claude-md-fluxo-integracao`,
retomada 2) para o registro completo.
