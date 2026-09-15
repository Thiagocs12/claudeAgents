---
id: 20260915123730-criacao-operacao-servico
modulo: mop
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-15
---

## Objetivo

Criar uma **operação de serviço** no Beyond Banking, do início ao fim do fluxo de criação, e
verificar se ela avança corretamente para a próxima etapa do processo. Este é o teste piloto do
Sup TestesFrontEnd — território novo (a tela de criação em si ainda não foi mapeada por ninguém,
ver `docs/documentacao.md`).

## Critérios de aceite

- A operação de serviço é criada com sucesso (sem erro bloqueante durante o preenchimento/submissão).
- Após a criação, a operação aparece avançada para a próxima etapa esperada do processo no Beyond
  (não basta ter sido criada — precisa confirmar visualmente/via tela que o avanço de fato
  aconteceu).
- Toda tentativa (inclusive as que não deram certo de primeira) é narrada passo a passo na seção
  `## Execução` deste arquivo.

## Ambiente / perfil de login

HML, perfil `master` (mesmo perfil já usado pelo `SupE2eAutomation` neste módulo).

## Material de apoio

- `docs/documentacao.md` deste módulo — ponto de partida (login, navegação até o dashboard
  Comercial) já mapeado pelo `SupE2eAutomation`.
- Dashboard Comercial tem cards "Operação Diária", "Operação Estruturada", "Operação Cessão",
  "Garantia" — nenhum confirmado ainda como o ponto de entrada para "operação de serviço"; parte
  da exploração desta tarefa é descobrir isso.
