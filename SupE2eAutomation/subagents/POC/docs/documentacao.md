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
  catalogado em `../../docs/conhecimento-geral.md`) em quase toda tentativa recente (várias
  ocorrências entre 2026-09-15 e 2026-09-16, inclusive 2x seguidas numa mesma retomada). Dúvida
  bloqueante mais recente (`duvidas.md`, ainda `Status: pendente`) pergunta ao Thiago se deve
  continuar só retentando ou se a frequência crescente justifica investigar causa raiz.
- **Próxima retomada, assim que a dúvida pendente for respondida:** conforme a orientação já dada
  antes de ser respondida, (1) rodar o spec de diagnóstico descartável (`_scratch/diagnostico-campos-habilitam.feature`,
  gitignored, já no working tree local, captura spinners e requisições em voo) para coletar
  evidência real do que acontece depois do primeiro "Salvar"; (2) implementar a espera revisada com
  base nessa evidência (não `cy.wait` cego); (3) aumentar `aguardarCamposObrigatoriosHabilitados`
  para 60s como já pedido; (4) rodar o autoteste do spec de produção. Se o campo continuar preso
  mesmo assim, parar e deixar vídeo/screenshot prontos (já orientado pelo Thiago).

## Bug conhecido na sincronização mecânica da fila (`Test-DuvidaRespondida`)

- Ver detalhe completo em `../../docs/conhecimento-geral.md` (seção "Bug em `Test-DuvidaRespondida`").
  Resumo: como esta tarefa já teve várias rodadas de dúvida sob o mesmo id, a checagem mecânica em
  `run-cycle.ps1` (que olha só o **primeiro** bloco `## <id>` que bate, não o mais recente) considera
  o id "respondido para sempre" assim que a 1ª pergunta é respondida — mesmo que rodadas
  posteriores sigam pendentes.
- **Recorrência (2026-09-16, esta retomada):** o mesmo bug moveu a tarefa de `aguardando-resposta/`
  para `executando/` de novo, com a pergunta mais recente (sobre insistir em retry de login vs.
  investigar causa raiz) ainda `Status: pendente`. Segui o mesmo protocolo da recorrência anterior:
  não toquei em `repo/`, não rodei Cypress, não respondi a dúvida sozinha (regra 9 do `AGENTE.md`) —
  apenas movi o arquivo de volta para `tarefas/aguardando-resposta/`. Nenhum código de produção
  alterado (branch segue limpa em `9054e8b`).
- Confirma que a correção sugerida (iterar os blocos de `duvidas.md` em ordem reversa / usar o
  último match, não o primeiro) ainda não foi aplicada — segue sob responsabilidade do Supervisor
  coordenar, já que o script é compartilhado entre todos os subAgents/Agent Master/Status Watcher.
