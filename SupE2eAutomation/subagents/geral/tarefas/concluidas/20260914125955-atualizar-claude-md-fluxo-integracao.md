---
id: 20260914125955-atualizar-claude-md-fluxo-integracao
modulo: geral
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-14
---

## Descrição
O `CLAUDE.md` do repositório (`repo/CLAUDE.md`, seção "## Collaboration workflow") descreve o
modelo antigo de integração — PR por tarefa (`feature/xxx → reviewAgents`), aprovado manualmente
pelo Thiago um a um, com a frase explícita "The Agent Master never merges or pushes directly to
`reviewAgents` or `main`".

Esse modelo mudou em 2026-09-14 (pedido explícito do Thiago): o Agent Master agora faz merge
direto (com push) na `reviewAgents` de cada tarefa aprovada nos testes, sem PR nem aprovação
humana por tarefa. O único ponto de revisão manual do Thiago passou a ser um PR único e contínuo
`reviewAgents → main`, que o Agent Master garante que existe e nunca recria. Ver seção 3.3 do
`CLAUDE.md` deste Supervisor (`SupE2eAutomation/CLAUDE.md`) para a descrição completa e atualizada
do fluxo novo.

Atualize a seção "## Collaboration workflow" do `repo/CLAUDE.md` pra refletir o fluxo novo, e
confira se o `README.md` do repositório tem alguma descrição equivalente/duplicada que também
precise ser corrigida (regra 2 do `AGENTE.md`: se perceber o README desatualizado em relação ao
padrão real, atualize como parte da tarefa). Não é urgente/bloqueante — pode ser feita como tarefa
normal, sem prioridade especial sobre outras já na fila.

## Critérios de aceite
- A seção "## Collaboration workflow" (ou equivalente) do `repo/CLAUDE.md` descreve o fluxo atual:
  merge direto (push) na `reviewAgents` por tarefa validada nos testes, sem PR/aprovação humana
  por tarefa; PR único e contínuo `reviewAgents → main` como único ponto de revisão manual.
- Nenhuma frase remanescente afirmando que "o Agent Master nunca mergeia/dá push direto na
  `reviewAgents`" ou que existe aprovação de PR por tarefa.
- Se o `README.md` do repositório tiver descrição equivalente do fluxo de colaboração, também foi
  corrigida.
- Commit da correção segue o fluxo normal (branch a partir de `reviewAgents`, autoteste — nesse
  caso, como é só documentação, "autoteste" pode ser uma revisão de que o texto está consistente
  com o `CLAUDE.md` deste Supervisor).

## Material de apoio
- `SupE2eAutomation/CLAUDE.md`, seção 3.3 (descrição completa do fluxo novo, incluindo o histórico
  do porquê da mudança).
- `SupE2eAutomation/agent-master/AGENTE.md`, regra 2 (mesma mudança, versão operacional).
- `CONHECIMENTO-SUPERVISORES.md` (`C:\Multiplica\claudeAgents\`), seção "Padrão estrutural de um
  Supervisor" (mudança documentada como padrão geral, não só deste Supervisor).
- PR #10 (`reviewAgents → main`, criado em 2026-09-14) é o exemplo real do novo PR único em
  funcionamento: https://github.com/Thiagocs12/automacaoUiMultiplica/pull/10
