# Status resumido — SupTestesFrontEnd

> Mantido por cada subAgent (nunca pela Gerente/Thiago) — cada um atualiza só a própria seção
> `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md` de cada um).
> Releia antes de escrever (edição concorrente). Sem Agent Master neste Supervisor (ver `CLAUDE.md`
> seção 1). Objetivo: a Gerente responde "status" ao Thiago lendo só este arquivo + os equivalentes
> dos outros 2 Supervisores, sem reler `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## mop
Aguardando aprovação do Thiago (`20260915123730-criacao-operacao-servico`) — cumprido parcialmente:
passos 1-12 do roteiro (criação e avanço da operação de serviço no Beyond Banking) seguem
concluídos e confirmados em banco (rodadas 74-93). Reaberta pelo Thiago só para os passos 13-14
(Monitor Diário do Beyond BackOffice); nesta retomada (rodadas 105-106) apareceram **dois achados
novos**, ambos reproduzidos 2/2: (1) a Home do Beyond Banking passou a mostrar uma tela de
"Franquia" sem opções para o usuário `automacao`, bloqueando o caminho de criação desde o início;
(2) o login do Beyond BackOffice (realm `multiplicacapital`) continua rejeitando a credencial com
"Usuário ou senha inválidos" mesmo após a correção do `.env` (espaço em branco) — mas agora só
nesse realm (o realm `beyondbanking-hml` aceitou a mesma credencial na mesma execução), sugerindo
bloqueio de conta isolado a esse realm, não mais problema geral de senha. Ambos parecem precisar de
ação de quem administra permissões/Keycloak, fora do escopo deste subAgent. Relatório em
`relatorios/20260915123730-criacao-operacao-servico.pdf`. Pendência secundária não bloqueante:
divergência UI×banco na operação 88677.

## contratos
Sem tarefa ativa. Módulo novo (criado em 2026-09-17): tarefa
`20260917115830-envio-contrato-mae-qcertifica` registrada em `tarefas/pendentes/`, aguardando
HML voltar (`PAUSA-HML.flag`) e a especificação de apoio (`AgenteEspecificacao/especificacoes/
contratos-qcertifica/`) ser completada com o Thiago.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent._
