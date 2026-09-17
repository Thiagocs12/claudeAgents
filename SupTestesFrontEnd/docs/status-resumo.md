# Status resumido — SupTestesFrontEnd

> Mantido por cada subAgent (nunca pela Gerente/Thiago) — cada um atualiza só a própria seção
> `## <modulo>`, sempre que mudar de estado (ver regra correspondente no `AGENTE.md` de cada um).
> Releia antes de escrever (edição concorrente). Sem Agent Master neste Supervisor (ver `CLAUDE.md`
> seção 1). Objetivo: a Gerente responde "status" ao Thiago lendo só este arquivo + os equivalentes
> dos outros 2 Supervisores, sem reler `duvidas.md`/`tarefas/` cru de cada módulo a cada consulta.

## mop
Bloqueado (`duvidas.md`: `20260915123730-criacao-operacao-servico (2)`) — login (Keycloak) passou a
falhar intermitentemente com "Usuário ou senha inválidos" nos dois realms (Beyond Banking e Beyond
BackOffice) nas rodadas 96-97 (2026-09-17), depois de funcionar normalmente até a rodada 94; preciso
que o Thiago confirme se é rotação de senha, bloqueio de conta por força bruta, ou instabilidade
pontual, antes de tentar login de novo. Passos 1-12 do roteiro seguem provados/reproduzíveis
(confirmados em banco); só falta 13-14 (Monitor Diário). Pendência secundária não bloqueante:
divergência UI×banco na operação 88677.

## contratos
Sem tarefa ativa. Módulo novo (criado em 2026-09-17): tarefa
`20260917115830-envio-contrato-mae-qcertifica` registrada em `tarefas/pendentes/`, aguardando
HML voltar (`PAUSA-HML.flag`) e a especificação de apoio (`AgenteEspecificacao/especificacoes/
contratos-qcertifica/`) ser completada com o Thiago.

_Bootstrap inicial gerado pela Gerente em 2026-09-17 a partir do levantamento manual do "status" —
a partir de agora, cada seção é mantida pelo próprio subAgent._
