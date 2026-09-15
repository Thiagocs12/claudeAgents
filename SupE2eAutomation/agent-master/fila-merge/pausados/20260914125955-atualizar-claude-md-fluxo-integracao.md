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
