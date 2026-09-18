# Conhecimento acumulado do módulo POC

> Histórico detalhado das retomadas de 2026-09-15/16 (mapeamento inicial da tela, descoberta dos 3
> campos obrigatórios, descoberta da listagem `/monitor`, sequência de tentativas de timeout
> 15s/30s) foi arquivado em `docs/documentacao-historico.md` (regra 11 do `AGENTE.md`) — nada foi
> descartado, só movido. Abaixo, só o resumo operacional ainda relevante.

## Estado atual da tarefa `20260915131339-criar-prospect-cedente-cnpj`

- **Branch:** `feature/poc-criar-prospect-cedente-cnpj` (repo limpo, último commit `9054e8b`).
- **Implementação de produção já feita** (commits `c36db44`, `b804d23`, `0138e86`, `9054e8b`):
  `NovoProspectPage`, `EtapaCriarProspectPorCnpj`, `EsteiraCriarProspectPorCnpj`,
  `MonitorProspectPage`, feature + step_definitions em `poc/`. Valores dos 3 campos obrigatórios
  confirmados pelo Thiago: `Tipo de Prospect` = `PROSPECT`, `Agente Comercial` = `GERENTE AUTOMAÇÃO`,
  `Tipo Empresa` = `Matriz`. Validação do gap (CNPJ não auto-preenche os 3 campos) implementada em
  `NovoProspectPage.validarCamposNaoPreenchidosAutomaticamentePeloCnpj()`, por pedido do Thiago.
  Sucesso validado apontando para `/monitor`, tabela "Prospecções", linha com
  `Agente Comercial = GERENTE AUTOMAÇÃO` (não há coluna de CNPJ na listagem).
- **Bloqueio ativo:** `aguardarCamposObrigatoriosHabilitados()` (espera "Tipo de Prospect" sair de
  `Mui-disabled` após o primeiro "Salvar") já testado com 15s e 30s de timeout — **nas duas
  execuções em que o login funcionou, o campo nunca saiu de `Mui-disabled`**, o que descarta flake
  de timing e aponta para possível regressão em hml (não confirmada).
- **Bloqueio recorrente, ainda mais frequente, impedindo até testar o bloqueio acima:** login via
  `cy.loginComoPerfil` falhando com `cy.origin() failed to create a spec bridge...` (mesmo sintoma
  catalogado em `../geral/docs/documentacao.md`) em quase toda tentativa recente (várias
  ocorrências entre 2026-09-15 e 2026-09-16, inclusive 2x seguidas numa mesma retomada). Thiago
  respondeu (2026-09-17) que era instabilidade do ambiente HML (mesmo motivo do `PAUSA-HML.flag`,
  já removido), confirmado OK, autorizando retry normal — mas condicionou: se o mesmo sintoma
  voltasse a se repetir com essa frequência mesmo com o ambiente já confirmado estável, deveria ser
  registrado como suspeita de causa raiz nova.
- **Retomada 2026-09-17 — critério de escalada do Thiago atingido, nova dúvida registrada com
  evidência comparativa (ainda `Status: pendente`):** VPN/ambiente confirmado ok via `curl`
  (`beyond-hml` respondeu `200` em ~0.4s). Rodei em sequência, no mesmo ciclo: (1) spec de
  diagnóstico `_scratch/diagnostico-campos-habilitam.feature` → falhou no login com `cy.origin()`;
  (2) `shared/login.feature` → **passou 2/2** sem erro; (3) spec de produção
  `poc/poc-criar-prospect-cedente-cnpj.feature` → **falhou de novo**, mesmo erro exato de
  `cy.origin()`, mesmo ponto (setup do `cy.session`/`cy.loginComoPerfil`, antes de qualquer
  interação com a tela). Ou seja, na mesma janela de minutos, `login.feature` funcionou enquanto os
  dois specs do `POC` (mesmo comando `cy.loginComoPerfil('master')`) falharam. Comparei o código
  até a chamada de login nos dois fluxos e não achei diferença de comando Cypress antes do login —
  não parece ser algo que o código do `POC` faça de diferente do `login.feature`. Não retentei uma
  4ª vez; registrada nova dúvida bloqueante com essa evidência comparativa completa, pedindo decisão
  do Thiago (investigar infra/Keycloak vs. mudar algo no teste vs. pausar). Nenhum código de
  produção alterado nesta retomada (branch `feature/poc-criar-prospect-cedente-cnpj` segue limpa em
  `9054e8b`). Esse achado (login.feature passa de forma confiável enquanto outro spec que usa o
  mesmo comando de login falha no mesmo ciclo) também foi registrado em
  `../geral/docs/documentacao.md` (catálogo de sintomas de instabilidade de login) por ser
  potencialmente relevante a qualquer módulo.
- **Retomada 2026-09-17 (pós-limpeza de cache do Cypress, 13ª dúvida registrada — novo sintoma,
  ainda `Status: pendente`):** VPN/ambiente ok (`curl` `beyond-hml` → `200`, ~0.4s). Rodei primeiro
  o spec de diagnóstico descartável (`_scratch/diagnostico-campos-habilitam.feature`) para coletar
  evidência antes de mexer em código de produção — **falhou de novo, mas com sintoma diferente** do
  `cy.origin() failed to create a spec bridge` catalogado até aqui: desta vez travou no
  `cy.session`/login com timeout de 15s esperando a URL sair do Keycloak (`login-actions/
  authenticate`) e voltar pra `beyond-hml`. Comparei com `shared/login.feature` (protocolo padrão)
  → **também falhou**, mesmo cenário ("Login com credenciais válidas"), mesmo sintoma. O screenshot
  da falha mostrou o motivo real: o próprio formulário do Keycloak, campo usuário preenchido
  (`automacao`), com a mensagem de validação **"usuário ou senha inválidos"** em vermelho — ou seja,
  rejeição ativa da credencial pelo Keycloak, não timeout de rede/redirect. Confirmei que
  `HML_MASTER_PASSWORD` neste `.env` bate exatamente com o valor documentado em
  `../geral/docs/documentacao.md` (`Automacao@123`). Confirmação extra: no mesmo run, o cenário
  "Login com credenciais inválidas" (senha propositalmente errada) passou normalmente, confirmando
  que a mensagem é resposta real do Keycloak. Registrei dúvida bloqueante nova (não é mais
  variação do mesmo sintoma de sempre — é potencialmente a credencial `automacao` ter sido
  rotacionada/expirado/bloqueada, o que afetaria todos os módulos, não só POC) e também atualizei
  `../geral/docs/documentacao.md` (catálogo de instabilidade de login, sintoma 4). Nenhum código de
  produção alterado (branch `feature/poc-criar-prospect-cedente-cnpj` segue limpa em `9054e8b`),
  nenhuma tentativa adicional de retry.
- **Próxima retomada, assim que a dúvida pendente (13ª rodada) for respondida:** se a credencial
  foi corrigida/confirmada e a causa era mesmo essa (não mais bloqueio de login), retomar o plano já
  traçado: (1) rodar o spec de diagnóstico descartável para coletar evidência real do que acontece
  depois do primeiro "Salvar" (spinners/requisições em voo); (2) implementar a espera revisada com
  base nessa evidência (não `cy.wait` cego); (3) aumentar `aguardarCamposObrigatoriosHabilitados`
  para 60s como já pedido; (4) rodar o autoteste do spec de produção. Se o campo continuar preso
  mesmo assim, parar e deixar vídeo/screenshot prontos (já orientado pelo Thiago).

- **Retomada 2026-09-18 03:30 (ciclo sem ação):** confirmado manualmente que `tarefas/executando/`
  e `tarefas/pendentes/` estão vazias e a tarefa segue em `tarefas/aguardando-resposta/`, com a
  dúvida da 13ª rodada ainda `Status: pendente`/`Resposta:` vazia em `duvidas.md` — ao contrário das
  recorrências anteriores do bug abaixo, desta vez a sincronização mecânica **não** moveu o arquivo
  para `executando/` incorretamente (o arquivo já estava no lugar certo). Como não há nada em
  `executando/` para retomar nem em `pendentes/` para iniciar, e a dúvida segue sem resposta do
  Thiago, nenhuma ação foi tomada: `repo/` não foi tocado (branch `feature/poc-criar-prospect-
  cedente-cnpj` segue limpa em `9054e8b`), nenhum Cypress rodado, dúvida não respondida por mim.
  Ciclo encerrado sem alteração de estado.
- **Retomada seguinte (mesmo dia, ciclo sem ação):** o prompt de disparo deste ciclo presumia uma
  tarefa em `tarefas/executando/` para retomar, mas a checagem manual confirmou de novo que
  `executando/` e `pendentes/` estão vazias e a tarefa segue corretamente em
  `tarefas/aguardando-resposta/` — a 13ª pergunta em `duvidas.md` continua `Status: pendente`/
  `Resposta:` vazia (nenhuma resposta nova do Thiago desde a retomada anterior). Como não há nada
  para retomar/iniciar e a dúvida bloqueante (suspeita de credencial `automacao` rotacionada/
  expirada no Keycloak) segue sem decisão, nenhuma ação foi tomada: `repo/` não foi tocado (branch
  `feature/poc-criar-prospect-cedente-cnpj` segue limpa em `9054e8b`), nenhum Cypress rodado, dúvida
  não respondida por mim (regra 9 do `AGENTE.md`). Ciclo encerrado sem alteração de estado.
- **Retomada seguinte (mesmo dia, mais um ciclo sem ação):** de novo o prompt de disparo presumia
  tarefa em `tarefas/executando/`, mas a checagem manual confirmou o mesmo estado das duas
  retomadas anteriores: `executando/`/`pendentes/` vazias, tarefa corretamente em
  `tarefas/aguardando-resposta/`, 13ª pergunta ainda `Status: pendente`/`Resposta:` vazia em
  `duvidas.md` (sem resposta nova do Thiago). Nada tocado em `repo/` (branch
  `feature/poc-criar-prospect-cedente-cnpj` segue limpa em `9054e8b`), nenhum Cypress rodado, dúvida
  não respondida por mim. Ciclo encerrado sem alteração de estado.
- **Retomada seguinte (2026-09-18, mais um ciclo sem ação):** mesma checagem manual, mesmo
  resultado: `executando/`/`pendentes/` vazias, tarefa corretamente em
  `tarefas/aguardando-resposta/`, 13ª pergunta ainda `Status: pendente`/`Resposta:` vazia (sem
  resposta nova do Thiago). Nada tocado em `repo/` (branch segue limpa em `9054e8b`), nenhum
  Cypress rodado, dúvida não respondida por mim. **Corroboração cruzada notada** (só leitura, sem
  ação): `../../docs/status-resumo.md`, seção `## agent-master`, registra que o merge de teste da
  branch `feature/migrar-video-para-relatorio-pdf` (módulo `geral`) também falhou 2/2 specs com
  `shared/login.feature` quebrando — mesma família de sintoma de rejeição/instabilidade do
  Keycloak suspeitada aqui na 13ª rodada, agora observada também fora do módulo POC no mesmo
  período. Reforça (não confirma) a hipótese de causa raiz cross-módulo já registrada em
  `../geral/docs/documentacao.md`; decisão continua exclusivamente com o Thiago via Supervisor.
  Ciclo encerrado sem alteração de estado.

## Bug conhecido na sincronização mecânica da fila (`Test-DuvidaRespondida`)

- Ver detalhe completo em `CONHECIMENTO-SUPERVISORES.md` (raiz de `claudeAgents`), seção "Bugs
  conhecidos no padrão compartilhado de `run-cycle.ps1`". Resumo: como esta tarefa já teve várias
  rodadas de dúvida sob o mesmo id, a checagem mecânica em
  `run-cycle.ps1` (que olha só o **primeiro** bloco `## <id>` que bate, não o mais recente) considera
  o id "respondido para sempre" assim que a 1ª pergunta é respondida — mesmo que rodadas
  posteriores sigam pendentes.
- **Nova recorrência (2026-09-17, retomada seguinte à 11ª pergunta registrada — evidência
  comparativa `cy.origin`/`login.feature`):** a mesma falha mecânica moveu a tarefa de
  `aguardando-resposta/` para `executando/` de novo, com a pergunta mais recente (11ª rodada,
  pedindo decisão do Thiago entre investigar infra/Keycloak, mudar o teste, ou pausar) ainda
  `Status: pendente` em `duvidas.md`. Confirmado manualmente (releitura de `duvidas.md` inteiro)
  antes de agir. Mesmo protocolo de sempre: nada tocado em `repo/`, nenhum Cypress rodado, dúvida
  não respondida por mim — arquivo movido de volta para `tarefas/aguardando-resposta/`. Branch
  segue limpa em `9054e8b`. Já são 3 recorrências consecutivas deste mesmo bug nesta tarefa.
- **Nova recorrência (2026-09-17, retomada seguinte à 12ª pergunta registrada — evidência
  comparativa `cy.origin`/`login.feature`, ainda sem resposta do Thiago):** a mesma falha mecânica
  moveu a tarefa de `aguardando-resposta/` para `executando/` de novo, com a pergunta mais recente
  (12ª rodada, pedindo decisão entre investigar infra/Keycloak, mudar o teste, ou pausar) ainda
  `Status: pendente` em `duvidas.md` (a 11ª pergunta, essa sim, já está `respondida`). Confirmado
  manualmente (releitura de `duvidas.md` inteiro) antes de agir. Mesmo protocolo de sempre: nada
  tocado em `repo/` (branch segue limpa em `9054e8b`), nenhum Cypress rodado, dúvida não respondida
  por mim — arquivo movido de volta para `tarefas/aguardando-resposta/`. Já são 4 recorrências
  consecutivas deste mesmo bug nesta tarefa.
- **Nova recorrência (2026-09-17, retomada seguinte — mesma 12ª pergunta, ainda sem resposta do
  Thiago):** de novo o mesmo bug moveu a tarefa para `executando/`, com a 12ª rodada (evidência
  comparativa `cy.origin`/`login.feature`) seguindo `Status: pendente`/`Resposta:` vazia em
  `duvidas.md` — nenhuma resposta nova foi registrada desde a recorrência anterior. Confirmado
  manualmente antes de agir; `repo/` segue limpo em `9054e8b`, nenhum Cypress rodado, dúvida não
  respondida por mim — arquivo movido de volta para `tarefas/aguardando-resposta/`. Já são 5
  recorrências consecutivas deste mesmo bug nesta tarefa, todas para a mesma pergunta de 12ª rodada
  ainda sem decisão do Thiago.
- **Recorrência (2026-09-16, esta retomada):** o mesmo bug moveu a tarefa de `aguardando-resposta/`
  para `executando/` de novo, com a pergunta mais recente (sobre insistir em retry de login vs.
  investigar causa raiz) ainda `Status: pendente`. Segui o mesmo protocolo da recorrência anterior:
  não toquei em `repo/`, não rodei Cypress, não respondi a dúvida sozinha (regra 9 do `AGENTE.md`) —
  apenas movi o arquivo de volta para `tarefas/aguardando-resposta/`. Nenhum código de produção
  alterado (branch segue limpa em `9054e8b`).
- Confirma que a correção sugerida (iterar os blocos de `duvidas.md` em ordem reversa / usar o
  último match, não o primeiro) ainda não foi aplicada — segue sob responsabilidade do Supervisor
  coordenar, já que o script é compartilhado entre todos os subAgents/Agent Master/Status Watcher.
- **Retomada 2026-09-18 (mais um ciclo sem ação, bug não recorreu desta vez):** checagem manual
  confirmou de novo `executando/`/`pendentes/` vazias e a tarefa corretamente em
  `tarefas/aguardando-resposta/`, 13ª pergunta ainda `Status: pendente`/`Resposta:` vazia (sem
  resposta nova do Thiago). Nada tocado em `repo/` (branch `feature/poc-criar-prospect-cedente-cnpj`
  segue limpa em `9054e8b`), nenhum Cypress rodado, dúvida não respondida por mim. `status-resumo.md`
  já refletia esse estado corretamente, sem necessidade de atualização. Ciclo encerrado sem
  alteração de estado.
- **Nova recorrência (2026-09-16, retomada seguinte à anterior):** o mesmo bug moveu a tarefa de
  `aguardando-resposta/` para `executando/` mais uma vez, com a 10ª rodada de dúvida (pergunta sobre
  insistir em retry de login vs. investigar causa raiz do `cy.origin`) ainda `Status: pendente`.
  Confirma que o problema não é pontual — já são duas recorrências consecutivas do falso positivo
  nesta mesma tarefa. Mesmo protocolo seguido de novo: nada tocado em `repo/`, nenhum Cypress
  rodado, dúvida não respondida por mim, arquivo movido de volta para `aguardando-resposta/`. Branch
  segue limpa em `9054e8b`.
- **Retomada 2026-09-18 (mais um ciclo sem ação; prompt de disparo presumia tarefa em
  `executando/`, checagem manual mostrou o contrário):** `tarefas/executando/` e
  `tarefas/pendentes/` confirmadas vazias; a tarefa segue corretamente em
  `tarefas/aguardando-resposta/`. `duvidas.md` conferido inteiro: a 13ª pergunta (suspeita de
  credencial `automacao` rotacionada/expirada/bloqueada no Keycloak) continua `Status: pendente`/
  `Resposta:` vazia — sem resposta nova do Thiago. Como não havia nada para retomar em `executando/`
  nem para iniciar em `pendentes/`, nenhuma ação foi tomada: `repo/` conferido limpo na branch
  `feature/poc-criar-prospect-cedente-cnpj`, no commit `9054e8b` (nenhum código de produção tocado),
  nenhum Cypress rodado, dúvida não respondida por mim (regra 9 do `AGENTE.md`). `status-resumo.md`
  já refletia esse estado corretamente, sem necessidade de atualização. Ciclo encerrado sem
  alteração de estado.
- **Retomada 2026-09-18 (mais um ciclo sem ação):** prompt de disparo novamente presumia tarefa em
  `tarefas/executando/`, mas checagem manual confirmou o mesmo estado de todos os ciclos recentes:
  `executando/`/`pendentes/` vazias, tarefa corretamente em `tarefas/aguardando-resposta/`, 13ª
  pergunta ainda `Status: pendente`/`Resposta:` vazia em `duvidas.md` (sem resposta nova do
  Thiago). `repo/` conferido limpo na branch `feature/poc-criar-prospect-cedente-cnpj`, commit
  `9054e8b` (nenhum código de produção tocado), nenhum Cypress rodado, dúvida não respondida por
  mim. `status-resumo.md` já refletia esse estado corretamente. Ciclo encerrado sem alteração de
  estado.
