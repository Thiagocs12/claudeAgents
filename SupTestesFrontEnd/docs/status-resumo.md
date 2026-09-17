# Status resumido — SupTestesFrontEnd

> Mantido por cada subAgent (nunca pela Gerente/Thiago) — cada um atualiza só a própria seção
> `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md` de cada um).
> Releia antes de escrever (edição concorrente). Sem Agent Master neste Supervisor (ver `CLAUDE.md`
> seção 1). Objetivo: a Gerente responde "status" ao Thiago lendo só este arquivo + os equivalentes
> dos outros 2 Supervisores, sem reler `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## mop
Aguardando aprovação do Thiago (`20260915123730-criacao-operacao-servico`) — cumprido parcialmente:
passos 1-12 do roteiro (criação e avanço da operação de serviço no Beyond Banking) concluídos e
confirmados em banco; passos 13-14 (Monitor Diário do Beyond BackOffice) bloqueados por falha de
login persistente ("Usuário ou senha inválidos" em ambos os realms, reproduzida de novo mesmo após
o Thiago autorizar retry na rodada 104) — parece precisar de ação de quem administra a
credencial/Keycloak (rotação de senha ou desbloqueio de conta), fora do escopo deste subAgent.
Relatório em `relatorios/20260915123730-criacao-operacao-servico.pdf`. Pendência secundária não
bloqueante: divergência UI×banco na operação 88677.

## contratos
Sem tarefa ativa. Módulo novo (criado em 2026-09-17): tarefa
`20260917115830-envio-contrato-mae-qcertifica` registrada em `tarefas/pendentes/`, aguardando
HML voltar (`PAUSA-HML.flag`) e a especificação de apoio (`AgenteEspecificacao/especificacoes/
contratos-qcertifica/`) ser completada com o Thiago.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent._
