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
Bloqueado (`duvidas.md`: `20260915131339-criar-prospect-cedente-cnpj`) — login via
`cy.origin()`/Keycloak falhou 3x seguidas (erro de spec bridge); aguardando decisão do Thiago
sobre retry vs. investigar causa raiz no ambiente HML/Keycloak. Em execução: fluxo de criação de
Prospect por CNPJ com código já implementado e pushado, timeout do campo "Tipo de Prospect"
escalado 15s→30s→60s — falta rodar o autoteste final assim que o login for destravado.

## agent-master
Sem aviso pendente em `fila-merge/`. PR único `reviewAgents → main` mantido aberto; o PR legado
`feature/atualizar-claude-md-fluxo-integracao` foi abandonado por decisão do Thiago (não conta como
pendência).

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
