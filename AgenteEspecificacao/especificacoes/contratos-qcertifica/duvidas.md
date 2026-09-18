# Dúvidas — contratos-qcertifica

## contratos-qcertifica-levantamento-inicial
Status: respondida
Pergunta: Entrevista inicial de levantamento — contexto de negócio, gatilho/fluxo, mecânica
técnica, ambiente, casos de erro, material de apoio adicional.
Resposta: Respondida em 2026-09-18 via conversa + documento
`material/fluxo-integrado-cadastro.docx` fornecido pelo Thiago. Conteúdo incorporado em
`especificacao.md`.

## contratos-qcertifica-acesso-sql
Status: respondida
Pergunta: A especificação inclui queries SQL de apoio (achar cedente/pessoa recém-criado em
produção, conferir dados propagados, montar lista de representantes de Consultoria/Gestora/
Administradora). O subAgent do módulo `contratos` (execução via Cypress/browser, sem acesso a
banco hoje) tem/deve ganhar acesso direto ao SQL Server para rodar essas queries sozinho, ou os
dados de entrada (cedente/pessoas a usar) devem ser sempre fornecidos previamente pelo Thiago/
Supervisor na tarefa (ex.: já resolvidos e citados no arquivo de tarefa)?
Resposta: O subAgent já tem acesso ao SQL Server — pode rodar as queries de apoio sozinho.

## contratos-qcertifica-sync-prod-hml
Status: respondida
Pergunta: O passo 1 do fluxo pressupõe um cedente "criado em produção nos últimos dias" que ainda
não existe em HML. O `SupAutomacaoUteis` já tem um módulo `cedente` cuja função é justamente
clonar/sincronizar cadastros PROD→HML (ver `CONHECIMENTO-SUPERVISORES.md`). O cadastro do cedente
em HML para este teste (passos 1-2 do fluxo) deve ser feito manualmente pelo subAgent na UI do
Beyond, ou depende primeiro de uma tarefa no módulo `cedente` do `SupAutomacaoUteis` sincronizar
esse cedente pra HML? Se depender, isso deveria virar uma dependência explícita entre módulos
(quem aciona quem, e quando).
Resposta: O CNPJ retornado pela query não é necessariamente um cedente já existente — é só uma
empresa matriz qualquer recém-cadastrada em produção. Não depende do módulo `cedente` do
`SupAutomacaoUteis`: o subAgent cadastra esse CNPJ como cedente do zero, diretamente na UI do
Beyond em HML (passos 1-2 do fluxo), usando os dados básicos (nome fantasia, razão social,
endereço) — a query só serve pra garantir um CNPJ "limpo" (sem cadastro/conflito prévio em HML).
