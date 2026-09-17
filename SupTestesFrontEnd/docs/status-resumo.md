# Status resumido — SupTestesFrontEnd

> Mantido por cada subAgent (nunca pela Gerente/Thiago) — cada um atualiza só a própria seção
> `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md` de cada um).
> Releia antes de escrever (edição concorrente). Sem Agent Master neste Supervisor (ver `CLAUDE.md`
> seção 1). Objetivo: a Gerente responde "status" ao Thiago lendo só este arquivo + os equivalentes
> dos outros 2 Supervisores, sem reler `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## mop
Em execução (`20260915123730-criacao-operacao-servico`) — passos 1-11 do roteiro provados e
reproduzíveis, passo 12 confirmado em banco como concluído com sucesso (o 400 anterior era
documento duplicado entre operações de teste, não bug real). Falta passos 13-14 (confirmar no
Monitor Diário do Beyond BackOffice) — travado por flakiness intermitente do `cy.origin()` (spec
bridge) em 3 tentativas, mais um erro pontual de "redirect_uri inválido" ainda não confirmado como
reproduzível. Pendência secundária não bloqueante: divergência UI×banco na operação 88677.
**Nota:** HML está fora do ar (`PAUSA-HML.flag` desde 2026-09-16) — ciclos automáticos deste módulo
estão pausados de propósito, não travados por bug.

## contratos
Sem tarefa ativa. Módulo novo (criado em 2026-09-17): tarefa
`20260917115830-envio-contrato-mae-qcertifica` registrada em `tarefas/pendentes/`, aguardando
HML voltar (`PAUSA-HML.flag`) e a especificação de apoio (`AgenteEspecificacao/especificacoes/
contratos-qcertifica/`) ser completada com o Thiago.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent._
