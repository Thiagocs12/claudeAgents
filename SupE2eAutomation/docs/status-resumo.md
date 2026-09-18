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
Bloqueado (`duvidas.md`: `20260918104219-hand-off-criacao-operacao-servico-monitor-diario`, 2ª
pergunta) — 1º bloqueio (operação nova não avançava via UI) já resolvido pelo Thiago e
implementado: critério agora só exige a operação aparecer no Monitor Diário + existir alguma
operação em "Middle" (não necessariamente a recém-criada). Bloqueio NOVO ao rodar o autoteste
completo: ao logar no 2º app/origem da mesma spec (Beyond BackOffice, depois de já ter logado no
Beyond Banking), `cy.session` lança uma exceção não tratada ("null") — reproduzido 2x igual;
ambiente confirmado no ar via `curl`. Tentativa de fix em `commands.js` (handler de exceção
escopado via `cy.origin()`) travou o autoteste por >25min e foi revertida — `commands.js` está de
volta ao original. Progresso commitado em `feature/mop-criacao-operacao-servico-monitor-diario`
(`9689008`). Aguardando decisão do Thiago (envolve o comando de login compartilhado por todos os
módulos, não decidi sozinho).

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
Sem aviso pendente. Última ação: `20260917111432-migrar-video-para-relatorio-pdf` mergeada direto
em `reviewAgents` (push `9f38a75 → a81b2de`, sem conflito, sem teste rodado — regra 5 do
`AGENTE.md`, dúvida já respondida pelo Thiago) e movida para `fila-merge/concluidos/`.
`C:\multiplica\cypress-e2e` sincronizado (`npm ci`, `.env` idêntico por hash); sem PDF novo pra
copiar (`repo/relatorios/` ainda não existe). PR único `reviewAgents → main` mantido aberto; o PR
legado `feature/atualizar-claude-md-fluxo-integracao` segue abandonado por decisão do Thiago (não
conta como pendência).

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent/Agent Master._
