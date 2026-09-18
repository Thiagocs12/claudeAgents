# Status resumido — SupE2eAutomation

> Mantido por cada subAgent/Agent Master (nunca pela Gerente/Thiago) — cada um atualiza só a
> própria seção `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md`
> de cada um). Releia antes de escrever (edição concorrente). Objetivo: a Gerente responde
> "status" ao Thiago lendo só este arquivo + os equivalentes dos outros 2 Supervisores, sem reler
> `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## geral
Sem tarefa ativa. Última concluída: `20260917111432-migrar-video-para-relatorio-pdf` (branch
`feature/migrar-video-para-relatorio-pdf` pushada, aviso em `agent-master/fila-merge/pendentes/`).

## mop
Sem tarefa ativa.

## POC
Bloqueado (`duvidas.md`: `20260915131339-criar-prospect-cedente-cnpj`, 13ª rodada) — pós-limpeza de
cache do Cypress (12ª resposta do Thiago), novo sintoma diferente do `cy.origin()` catalogado até
aqui: `shared/login.feature` e o spec de diagnóstico do POC falharam com o Keycloak exibindo
"usuário ou senha inválidos" na tela (rejeição ativa da credencial, não timeout de rede/redirect) —
senha em `.env` conferida igual à documentada. Pode ser credencial `automacao` rotacionada/expirada/
bloqueada (afetaria todos os módulos, não só POC) — achado também registrado em
`../subagents/geral/docs/documentacao.md`. Aguardando confirmação/credencial correta do Thiago.
Código de produção já implementado e pushado (branch `feature/poc-criar-prospect-cedente-cnpj`,
`9054e8b`), timeout do campo "Tipo de Prospect" em 30s (60s + espera revisada por spinner/requisição
seguem pendentes de aplicar, a fazer assim que o login for destravado). Nenhum código de produção
tocado nesta retomada; tarefa segue em `tarefas/aguardando-resposta/`, sem resposta nova do
Thiago — mais um ciclo sem ação. Nota: a seção `## agent-master` abaixo relata falha de login
semelhante (Keycloak) na mesma janela, reforçando (não confirmando) a suspeita de causa raiz
cross-módulo.

## agent-master
Bloqueado (`duvidas.md`: `20260917111432-migrar-video-para-relatorio-pdf`) — merge de teste local de
`feature/migrar-video-para-relatorio-pdf` sem conflito, mas `npm test` falhou 2/2 specs com sintoma
de login novo (Keycloak não redireciona de volta pra `beyond-hml`); `shared/login.feature` também
falhou (quebra o padrão anterior de "login isolado é confiável"). Merge local desfeito, aviso em
`fila-merge/pendentes/`. PR único `reviewAgents → main` mantido aberto; o PR legado
`feature/atualizar-claude-md-fluxo-integracao` segue abandonado por decisão do Thiago (não conta
como pendência).

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
