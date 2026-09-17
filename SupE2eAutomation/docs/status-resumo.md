# Status resumido — SupE2eAutomation

> Mantido por cada subAgent/Agent Master (nunca pela Gerente/Thiago) — cada um atualiza só a
> própria seção `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md`
> de cada um). Releia antes de escrever (edição concorrente). Objetivo: a Gerente responde
> "status" ao Thiago lendo só este arquivo + os equivalentes dos outros 2 Supervisores, sem reler
> `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## geral
Sem tarefa ativa.

## mop
Sem tarefa ativa.

## POC
Bloqueado (`duvidas.md`: `20260915131339-criar-prospect-cedente-cnpj`) — mesmo com ambiente
confirmado estável (Thiago autorizou retry, critério dele de "causa raiz nova" atingido), login via
`cy.origin()` voltou a falhar nos 2 specs do módulo, enquanto `shared/login.feature` passou 2/2 no
mesmo ciclo (evidência comparativa registrada, também em `../docs/conhecimento-geral.md`).
Aguardando decisão do Thiago: investigar infra/Keycloak vs. mudar teste vs. pausar. Código de
produção já implementado e pushado (branch `feature/poc-criar-prospect-cedente-cnpj`, `9054e8b`),
timeout do campo "Tipo de Prospect" já em 30s (60s pendente de aplicar) — falta rodar o autoteste
final assim que o login for destravado. Tarefa em `tarefas/aguardando-resposta/` (bug conhecido do
`Test-DuvidaRespondida` moveu de volta pra `executando/` sozinho de novo — 3ª recorrência; conferido
manualmente que a pergunta mais recente segue `Status: pendente`, nada tocado em `repo/`).

## agent-master
Sem aviso pendente em `fila-merge/`. PR único `reviewAgents → main` mantido aberto; o PR legado
`feature/atualizar-claude-md-fluxo-integracao` foi abandonado por decisão do Thiago (não conta como
pendência).

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
