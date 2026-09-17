# Status resumido — SupTestesFrontEnd

> Mantido por cada subAgent (nunca pela Gerente/Thiago) — cada um atualiza só a própria seção
> `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md` de cada um).
> Releia antes de escrever (edição concorrente). Sem Agent Master neste Supervisor (ver `CLAUDE.md`
> seção 1). Objetivo: a Gerente responde "status" ao Thiago lendo só este arquivo + os equivalentes
> dos outros 2 Supervisores, sem reler `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## mop
Aguardando aprovação do Thiago (`20260915123730-criacao-operacao-servico`) — cumprido parcialmente,
com progresso desde a última rodada: o Thiago corrigiu o `idFranquia` do usuário `automacao` no
Keycloak e isso **resolveu** o achado da tela "Franquia sem opções" (confirmado 2/2, fluxo de
criação volta a funcionar de ponta a ponta). Mas surgiu um achado novo no lugar: a operação
recém-criada não aparece na listagem "Operações" do Beyond Banking (confirmado em banco que ela É
criada de fato — pré-operações 88684/88685 existem com `situacao=VALIDADO` — só não aparece na UI),
o que impede o passo de avançá-la (a spec acaba clicando numa operação antiga já processada, cujo
botão "Avançar" está desabilitado). Reproduzido 2/2. Separadamente, o achado antigo do login do
Beyond BackOffice (realm `multiplicacapital`, "Usuário ou senha inválidos", isolado a esse realm)
**persiste sem correção**, reproduzido pela 4ª rodada seguida — segue bloqueando os passos 13-14
(Monitor Diário). Ambos os achados abertos parecem precisar de ação de quem administra
backend/Keycloak, fora do escopo deste subAgent. Relatório em
`relatorios/20260915123730-criacao-operacao-servico.pdf`. Pendência secundária não bloqueante:
divergência UI×banco na operação 88677 (rodada 89).

## contratos
Sem tarefa ativa. Módulo novo (criado em 2026-09-17): tarefa
`20260917115830-envio-contrato-mae-qcertifica` registrada em `tarefas/pendentes/`, aguardando
HML voltar (`PAUSA-HML.flag`) e a especificação de apoio (`AgenteEspecificacao/especificacoes/
contratos-qcertifica/`) ser completada com o Thiago.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent._
