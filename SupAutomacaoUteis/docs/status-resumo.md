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
escopo/negócio já resolvidas, resolvedores genéricos de dependência de catálogo E de INSERT
estrutural (não-catálogo) implementados e testados, e agora também o orquestrador que percorre a
ordem de dependência tabela por tabela buscando satélites em PROD e inserindo em HML
(`cy.clonarGrafoEstruturalCedente`, Ciclo 17) — catálogo já testado ponta a ponta contra HML real;
estrutural/orquestrador só com lógica pura por enquanto, decisão deliberada (ver
`docs/documentacao.md`). Falta: ligar o orquestrador a um cedente real (encadear com
`cy.resolverEstrategiaClonagemCedente`), resolver a execução da dependência `cascata` (cedente
vinculado) e implementar o DELETE (apaga-e-refaz) — trabalho ainda local na branch, não pushado.

## agent-master
Sem aviso pendente em `fila-merge/`. PR único `reviewAgents → master` mantido aberto; o item legado
`keycloakUser/clonar-usuario-prod-hml` já foi mergeado e está em `fila-merge/concluidos/`.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
