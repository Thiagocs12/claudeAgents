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

- **Ciclos sem ação (2026-09-18, 7 retomadas consecutivas até agora, detalhe completo das 6
  primeiras arquivado em `docs/documentacao-historico.md`):** em todas, `tarefas/executando/`/
  `pendentes/` confirmadas vazias, tarefa corretamente em `tarefas/aguardando-resposta/`, 13ª
  pergunta seguindo `Status: pendente`/`Resposta:` vazia em `duvidas.md` (sem resposta nova do
  Thiago). Nenhuma ação tomada em nenhuma delas: `repo/` sempre conferido limpo na branch
  `feature/poc-criar-prospect-cedente-cnpj`, commit `9054e8b`, nenhum Cypress rodado, dúvida nunca
  respondida por mim. Uma delas notou corroboração cruzada (só leitura): `status-resumo.md` mostrou
  o módulo `geral`/Agent Master também com falha de login (Keycloak) na mesma janela, reforçando
  (não confirmando) a hipótese de causa raiz cross-módulo já registrada em
  `../geral/docs/documentacao.md`. Na 7ª (esta retomada), único ponto novo: confirmado por `grep`
  em `duvidas.md` que existe só um bloco `## 20260915131339-criar-prospect-cedente-cnpj` no
  arquivo (não há rodada mais recente escondida) — reforça que a 13ª pergunta é mesmo a mais atual
  e continua sem resposta.

## Bug conhecido na sincronização mecânica da fila (`Test-DuvidaRespondida`)

- Ver detalhe completo em `CONHECIMENTO-SUPERVISORES.md` (raiz de `claudeAgents`), seção "Bugs
  conhecidos no padrão compartilhado de `run-cycle.ps1`". Resumo: como esta tarefa já teve várias
  rodadas de dúvida sob o mesmo id, a checagem mecânica em
  `run-cycle.ps1` (que olha só o **primeiro** bloco `## <id>` que bate, não o mais recente) considera
  o id "respondido para sempre" assim que a 1ª pergunta é respondida — mesmo que rodadas
  posteriores sigam pendentes.
- **Recorrências do bug (2026-09-16/17, 6 ocorrências, detalhe completo — inclusive rodada exata de
  dúvida afetada em cada uma — arquivado em `docs/documentacao-historico.md`):** o mesmo falso
  positivo moveu a tarefa de `aguardando-resposta/` para `executando/` repetidas vezes (10ª à 12ª
  rodada de dúvida, todas ainda `Status: pendente` no momento). Protocolo idêntico em todas: nada
  tocado em `repo/`, nenhum Cypress rodado, dúvida nunca respondida por mim — arquivo sempre movido
  de volta para `tarefas/aguardando-resposta/`. Branch sempre conferida limpa em `9054e8b`.
- Confirma que a correção sugerida (iterar os blocos de `duvidas.md` em ordem reversa / usar o
  último match, não o primeiro) ainda não foi aplicada — segue sob responsabilidade do Supervisor
  coordenar, já que o script é compartilhado entre todos os subAgents/Agent Master/Status Watcher.
- **Ciclos sem ação, bug não recorreu (2026-09-18, 4 retomadas, detalhe completo arquivado em
  `docs/documentacao-historico.md`):** checagem manual sempre confirmou `executando/`/`pendentes/`
  vazias e a tarefa corretamente em `tarefas/aguardando-resposta/`, 13ª pergunta ainda
  `Status: pendente`/`Resposta:` vazia (sem resposta nova do Thiago). Nada tocado em `repo/` (branch
  sempre limpa em `9054e8b`), nenhum Cypress rodado, dúvida não respondida por mim,
  `status-resumo.md` já refletindo o estado corretamente em todas.
