# Status resumido — SupAutomacaoUteis

> Mantido por cada subAgent/Agent Master (nunca pela Gerente/Thiago) — cada um atualiza só a
> própria seção `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md`
> de cada um). Releia antes de escrever (edição concorrente). Objetivo: a Gerente responde
> "status" ao Thiago lendo só este arquivo + os equivalentes dos outros 2 Supervisores, sem reler
> `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## keycloakUser
Sem tarefa ativa (as 6 tarefas do módulo já estão em `concluidas/`).

## cedente
Em execução (`20260915130215-clonar-cedente-completo-prod-hml`) — clonagem completa PROD→HML
(prospect→POC→comitê→cedente). Grafo de FK das 4 fases mapeado por inteiro, 9 dúvidas de
escopo/negócio já resolvidas, orquestrador completo (`cy.clonarCedenteCompleto`, Ciclo 18) já liga
leitura+INSERT estrutural. Ciclo 19 corrigiu um problema de correção achado ao revisar o
orquestrador (não uma dúvida — a busca de satélite nunca alcançava POC/comitê partindo só do
prospect; agora descobre múltiplas raízes via `MC_POC_PROSPECT`/`idComite`, ver
`docs/documentacao.md`). Só o caminho de skip (sem `documentoOrigem`) foi testado fim a fim até
agora, decisão deliberada. Falta: implementar o DELETE (apaga-e-refaz, mesmo problema de
"múltiplas raízes" ainda não resolvido do lado HML) e a execução da dependência `cascata` (cedente
vinculado) — trabalho ainda local na branch, não pushado.

## agent-master
Sem aviso pendente em `fila-merge/`. PR único `reviewAgents → master` mantido aberto; o item legado
`keycloakUser/clonar-usuario-prod-hml` já foi mergeado e está em `fila-merge/concluidos/`.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
