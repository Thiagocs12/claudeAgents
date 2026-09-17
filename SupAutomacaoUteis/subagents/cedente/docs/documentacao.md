# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **executando** (Ciclo 16) — o resolvedor genérico de
INSERT ESTRUTURAL (tabelas não-catálogo) foi implementado e testado (só lógica pura,
ainda sem exercício fim a fim contra HML real — ver Ciclo 16 abaixo). Branch
`cedente/clonar-cedente-completo-prod-hml` (a partir de `reviewAgents`, ainda não
pushada). Falta: a orquestração que percorre `ordenarTabelasPorDependenciaEstrutural`
tabela por tabela para um cedente real (buscando as linhas satélite em PROD por
tabela-pai, acumulando `idsHmlPorTabela`, chamando `cy.inserirLinhaEstruturalEmHml`
em ordem), a resolução da dependência `cascata` (`MC_CED_CEDENTE_VINCULADO`, ainda
não tratada) e o DELETE (apaga-e-refaz, `ordenarTabelasParaExclusaoEstrutural`).

### Resumo do que ficou decidido/implementado nos Ciclos 1-13 (arquivados)

Histórico ciclo a ciclo completo em `docs/documentacao-historico.md` (regra 12 do
`AGENTE.md` — nada foi descartado, só movido de lá pra cá). Ainda operacionalmente
relevante, sem repetir o `docs/documentacao-historico.md`/o `CLAUDE.md` do repo (seção
"Clonagem de Cedente", que documenta a arquitetura em detalhe):

- **Grafo de FK das 4 fases (prospect/POC/comitê/cedente) está completo** desde o
  Ciclo 11 — 122 tabelas em `MAPEAMENTO_CEDENTE_UNIFICADO`, sem nenhuma dúvida de
  classificação pendente.
- `classificarTabelaCedente`, `construirGrafoEstrutural`/`ordenarTabelasPorDependenciaEstrutural`/
  `ordenarTabelasParaExclusaoEstrutural`, `decidirEstrategiaClonagemCedente`,
  `aplicarValoresFixos` — todas em `clonagemCedente.js`, todas testadas via `node:test`.
- Tipos de dependência específicos deste domínio, além de `estrutural`/`catalogo`:
  `participante-fixo` (vota sempre como o Thiago, nunca copia o votante real de PROD)
  e `cascata` (`MC_CED_CEDENTE_VINCULADO` — clona o cedente vinculado recursivamente se
  ausente em HML, decidido pelo Thiago ciente do risco de efeito cascata).
- Exceção pontual à exclusão de documentação: `MC_CED_ATA`/`MC_CED_ATA_VOTACAO` entram
  no escopo só para viabilizar a votação da ata (conteúdo copiado inline, não é
  documento externo) — não abre precedente para as demais tabelas de documentação.
- `MC_CED_LOGIN` excluída inteira (dado sensível/credencial, nunca clonada).
- Todas as dúvidas dos Ciclos 1-13 (`duvidas.md`, Perguntas 1 a 8) já respondidas e
  implementadas — só a Pergunta-9 (colunas de auditoria) seguiu para o Ciclo 14/15
  abaixo.

### Ciclos 14-15 (2026-09-16) — resolvedor genérico de catálogo completo (resumo)

Histórico completo (bloqueio de auditoria, teste fim a fim contra HML real) em
`docs/documentacao-historico.md`. Resumo do que ficou pronto:

- **`cy.resolverIdCatalogoEmHml(tabela, idProducao)`** (`catalogoCedente.js`):
  busca a linha em PROD, procura em HML por chave natural
  (`METADADOS_CATALOGO_CEDENTE`), cria a cópia se não existir
  (`montarInsertCatalogo`). Tabela sem metadado lança erro explícito.
- **Resposta-9 implementada**: `montarInsertCatalogo` substitui as 4 colunas de
  auditoria (NOT NULL em praticamente todo o schema do domínio, já que o INSERT
  aqui é SQL direto, não API REST) por valores fixos (`gerarValoresAuditoriaCedente`
  — timestamp da inserção + `USUARIO_AUDITORIA_CEDENTE = 'sistema'`), em vez de só
  excluí-las. `id` sempre excluído (`OUTPUT INSERTED.id`).
- **Testado fim a fim contra PROD/HML reais** (caminho "já existe" e "criar"),
  via `npx cypress run --env tags=@cedente,catalogoTabela=...,catalogoIdProducao=...`.
  Um registro real ficou criado em HML (`MC_CAD_SITUACAO` id 50, "MAJORADO") —
  não é dado de teste descartável, é catálogo real que HML precisava ter.
- `PAUSA-HML.flag` (criado pelo Thiago em 2026-09-16, HML fora do ar) já foi
  removido (commit `5ee158a`, fora desta sessão) — HML confirmado OK, sem
  restrição de infraestrutura pendente no momento deste ciclo.

### Ciclo 16 (2026-09-17) — resolvedor genérico de INSERT ESTRUTURAL (não-catálogo)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `05b80fd`,
working tree limpa), sem dúvida pendente. Ataca o próximo passo pendente do
Ciclo 15: os comandos de INSERT das tabelas estruturais.

Commit `c85c25b`: `cypress/support/shared/clonagemCedente.js`
(`resolverDependenciasEstruturais`, `montarInsertEstrutural` — funções puras
novas, reaproveitam `aplicarValoresFixos`/`montarInsertCatalogo` já existentes)
+ `cypress/support/commands/estruturaCedente.js` (novo —
`cy.resolverIdParticipanteFixoEmHml`, `cy.resolverValoresDependenciasLinhaEstrutural`,
`cy.inserirLinhaEstruturalEmHml`) + `commands/index.js` (registra o módulo) + 6
testes novos em `__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros,
mesmos 4 warnings pré-existentes) e `npm run test:safety` (107/107) passam.

- **`resolverDependenciasEstruturais(tabela, linhaOrigem, mapeamento,
  valoresResolvidos)`**: sobrescreve, sobre a linha de PROD, só as colunas de
  `dependeDe` já resolvidas em HML (mapa `{campo: valorHml}` calculado pelo
  chamador) e aplica `aplicarValoresFixos` por último — uma coluna sem entrada
  em `valoresResolvidos` (nullable sem valor de origem, ou dependência ainda
  sem resolução automática, ex. `cascata`) mantém o valor original.
- **`montarInsertEstrutural`**: combina `resolverDependenciasEstruturais` +
  `montarInsertCatalogo` (mesmo tratamento de `id`/auditoria já usado no
  catálogo — não é um tratamento novo, é reaproveitado tal qual).
- **`cy.resolverIdParticipanteFixoEmHml()`**: resolve o participante fixo
  (Resposta-4) por chave natural em `MC_CAD_ANALISTA`, reaproveitando
  `cy.buscarRegistroCatalogoPorChaveNaturalEmHml` já existente — lança erro se
  não encontrar (pré-condição já confirmada pelo Thiago, não decidir um
  substituto sozinho).
- **`cy.resolverValoresDependenciasLinhaEstrutural(tabela, linhaOrigem,
  mapeamento, idsHmlPorTabela)`**: percorre `dependeDe` da tabela e resolve
  cada dependência `catalogo` (via `cy.resolverIdCatalogoEmHml`), `participante-fixo`
  (via o comando acima) e `estrutural` (via `idsHmlPorTabela[tabela].get(idProd)`,
  mapa acumulado pelo orquestrador ainda não implementado, tabela-pai precisa já
  ter sido inserida). Encadeado via `reduce` sobre `cy.wrap({})` (nunca Promise
  nativa misturada com `cy.` — mesma armadilha já documentada em
  `conhecimento-geral.md`). `cascata` fica sem resolução aqui de propósito.
- **`cy.inserirLinhaEstruturalEmHml(tabela, linhaOrigem, mapeamento,
  idsHmlPorTabela)`**: resolve + monta o INSERT + executa contra HML, devolve o
  novo id.
- **Só testado com lógica pura desta vez** (`node:test`) — decisão deliberada
  de não exercitar um INSERT estrutural real contra HML neste ciclo: diferente
  do catálogo (onde criar um valor real como "MAJORADO" é dado de referência
  que HML precisa ter de qualquer forma), inserir uma linha estrutural de teste
  (ex. um prospect fictício) criaria dado de negócio "de mentira" em HML sem
  necessidade — melhor adiar o teste fim a fim para quando a orquestração
  completa rodar com um documento de cedente real combinado com o Thiago.
- **Próximo passo pendente**: a orquestração que percorre
  `ordenarTabelasPorDependenciaEstrutural(construirGrafoEstrutural(MAPEAMENTO_CEDENTE_UNIFICADO))`
  tabela por tabela — para cada tabela, buscar em PROD as linhas satélite da
  tabela-pai já processada (ex. `SELECT * FROM tabela WHERE campoFk = idProdPai`),
  chamar `cy.inserirLinhaEstruturalEmHml` para cada uma, acumulando o novo id em
  `idsHmlPorTabela[tabela]`. Depois: resolver `cascata`
  (`MC_CED_CEDENTE_VINCULADO`) e implementar o DELETE (apaga-e-refaz,
  `ordenarTabelasParaExclusaoEstrutural`).
- Nenhum arquivo temporário ficou para trás (`git status` confirmou working
  tree limpa após o commit).

