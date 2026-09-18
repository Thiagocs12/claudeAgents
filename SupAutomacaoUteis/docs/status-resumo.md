# Status resumido — SupAutomacaoUteis

> Mantido por cada subAgent/Agent Master (nunca pela Gerente/Thiago) — cada um atualiza só a
> própria seção `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md`
> de cada um). Releia antes de escrever (edição concorrente). Objetivo: a Gerente responde
> "status" ao Thiago lendo só este arquivo + os equivalentes dos outros 2 Supervisores, sem reler
> `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## keycloakUser
Sem tarefa ativa (as 6 tarefas do módulo já estão em `concluidas/`).

## cedente
Sem tarefa ativa — `20260915130215-clonar-cedente-completo-prod-hml` **concluída e já integrada**
(2026-09-17): clonagem completa PROD→HML (prospect→POC→comitê→cedente) implementada fim a fim,
incluindo o DELETE apaga-e-refaz (Ciclo 20) e a execução da dependência `cascata` (cedente
vinculado, Ciclo 21). `npm run lint`/`test:safety` (126/126) passam; `npx cypress run` não roda
nesta máquina (binário não instala, problema de ambiente, não de código). Branch
`cedente/clonar-cedente-completo-prod-hml` pushada (commit `86eda12`) e já mergeada pelo Agent
Master na `reviewAgents` (commit `f3542ec`); aviso em `fila-merge/concluidos/`. `README.md`/
`CLAUDE.md` do repo atualizados. Detalhes em `subagents/cedente/docs/documentacao.md`.

## agent-master
Sem aviso pendente em `fila-merge/`. Ciclo de 2026-09-17: merge direto (sem conflito, sem
`.env.example` novo) da tarefa `20260915130215-clonar-cedente-completo-prod-hml` (módulo
`cedente`) na `reviewAgents`, push feito (commit `f3542ec`), aviso movido para
`fila-merge/concluidos/`. Pasta manual `C:\multiplica\cypress-uteis` sincronizada (fast-forward,
sem `npm install` necessário) e `.env` copiado por cima. **PR #7 (contínuo) tinha sido mergeado
manualmente pelo Thiago em 2026-09-15 e ninguém recriou até agora** — recriado neste ciclo como
**PR #8** (https://github.com/Thiagocs12/automacaoUteisMultiplica/pull/8), aberto, cobrindo todo o
módulo `cedente` pendente de revisão. Item legado `keycloakUser/clonar-usuario-prod-hml` segue em
`fila-merge/concluidos/`.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
