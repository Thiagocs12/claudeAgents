# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **executando** (Ciclo 15) — a Resposta-9 (valores fixos
de auditoria) foi implementada e testada fim a fim; o resolvedor genérico de
dependência de catálogo cobre agora os dois caminhos ("já existe" e "criar") de
ponta a ponta. Branch `cedente/clonar-cedente-completo-prod-hml` (a partir de
`reviewAgents`, ainda não pushada). Falta: os comandos de INSERT estrutural
(tabelas não-catálogo, usando `MAPEAMENTO_CEDENTE_UNIFICADO`/
`ordenarTabelasPorDependenciaEstrutural`, reaproveitando `gerarValoresAuditoriaCedente`
para as mesmas 4 colunas de auditoria) e DELETE (apaga-e-refaz,
`ordenarTabelasParaExclusaoEstrutural`).

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

### Ciclo 14 (2026-09-16) — resolvedor genérico de catálogo implementado e testado; caminho "criar" bloqueado (colunas de auditoria NOT NULL)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `13a6ac1`,
working tree limpa), teste de conectividade não foi repetido antes de começar (mesmo
critério do Ciclo 12 — o primeiro `SELECT` já serve de teste). Sem dúvida pendente
(`duvidas.md` com `Status: respondida`). Ataca o próximo passo pendente do Ciclo 13
("o resolvedor genérico de dependência de catálogo... testado fim a fim contra um
catálogo real de PROD/HML").

Commit `e41cdf5`: `cypress/support/shared/clonagemCedente.js`
(`COLUNAS_AUDITORIA_CEDENTE`, `formatarValorSql`, `montarInsertCatalogo` — funções
puras) + `cypress/support/commands/catalogoCedente.js` (novo — `cy.resolverIdCatalogoEmHml`
e os 3 comandos que ele orquestra) + `commands/index.js` (registra o módulo) +
`cypress/e2e/features/gerenciamentoDoCedente.feature`/`step_definitions/gerenciamentoDoCedente.js`
(novo cenário `@cedente`, parametrizado via `--env catalogoTabela=...,catalogoIdProducao=...`)
+ 4 testes novos em `__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, os
mesmos 4 warnings pré-existentes) e `npm run test:safety` (100/100) passam.

- **`cy.resolverIdCatalogoEmHml(tabela, idProducao)`**: busca a linha de origem em
  PROD (`buscarRegistroCatalogoPorIdEmProd`), procura em HML um registro com a mesma
  chave natural (`buscarRegistroCatalogoPorChaveNaturalEmHml`, usando
  `METADADOS_CATALOGO_CEDENTE[tabela].campoChaveNatural`, comparação `LTRIM(RTRIM(...))`
  tolerante a espaço nas pontas) e, se não encontrar, cria a cópia
  (`criarRegistroCatalogoEmHml` → `montarInsertCatalogo`, exclui
  `COLUNAS_AUDITORIA_CEDENTE`, usa `OUTPUT INSERTED.id` para devolver o novo id na
  mesma instrução). Uma tabela sem entrada em `METADADOS_CATALOGO_CEDENTE` lança erro
  explícito (nunca decide sozinho tratar uma tabela de catálogo nova/não mapeada).
- **Testado fim a fim contra PROD/HML reais, caminho "já existe"**: `MC_CAD_SITUACAO`
  id 1 (PROD, `descricao = "ATIVA"`) resolvido para id 1 (já existente em HML, mesma
  `descricao`) — confirma que a busca por chave natural funciona mesmo quando o id
  numérico coincide por acaso (não é o que garante o match, só a `descricao`).
  Reforçado por uma segunda checagem manual (fora do autoteste, script `.cjs`
  temporário removido antes do commit): `MC_CAD_SITUACAO` id 8 em PROD
  (`descricao = "EM DIGITACAO"`) tem id **9** em HML para a mesma `descricao` — os
  ids numéricos dessa tabela já divergem de fato entre PROD/HML hoje, exatamente o
  cenário que a busca por chave natural (em vez de por id) existe para resolver.
- **Caminho "criar" bloqueado — descoberta real, não presumida**: tentar criar em HML
  um valor de catálogo ausente lá (`MC_CAD_SITUACAO` id 43 PROD, `descricao =
  "MAJORADO"`) falhou com erro real do SQL Server: `Cannot insert the value NULL into
  column 'usuarioUltimaAlteracao'... column does not allow nulls`. Investigação
  (`INFORMATION_SCHEMA.COLUMNS` contra HML, script `.cjs` temporário removido antes do
  commit) confirmou que isso não é peculiaridade de uma tabela: as 4 colunas de
  auditoria (`dataCadastro`, `dataUltimaAlteracao`, `usuarioCadastro`,
  `usuarioUltimaAlteracao`) são **NOT NULL em 38 das 38 tabelas de catálogo
  verificadas** (praticamente universal no schema do domínio cedente).
  `usuarioCadastro`/`usuarioUltimaAlteracao` são `varchar`, guardam username de quem
  criou/alterou (amostra real de `MC_CAD_SITUACAO`: `"henrique"`, `"tiago.roque"`,
  e também o valor literal `"sistema"` numa linha, aparentando já ser usado hoje para
  registros gerados automaticamente). **Causa raiz**: todos os outros domínios do
  repo (Produtos/Esteiras/Vínculos/Grupos e Permissões) criam em HML via API REST
  (`mc-cadastro-ms`, `criarItensInexistentesPorNivel`), que preenche essas colunas no
  servidor — o domínio `cedente` usa SQL direto (`dbClient.cjs`) por não haver
  endpoint REST mapeado para as ~122 tabelas do grafo, então nada preenche essas
  colunas automaticamente; **todo** INSERT que este domínio fizer (catálogo agora, e
  as tabelas estruturais quando essa etapa for implementada) vai precisar declarar
  valores explícitos para elas. Não decidido sozinho (regra 8 do `AGENTE.md` — "qual
  padrão do projeto seguir", decisão que se propaga para o resto da tarefa, não é uma
  peculiaridade isolada desta tabela) — dúvida bloqueante registrada em `duvidas.md`
  (`colunas-auditoria-not-null-insert-direto-sql-catalogo-20260916`, mesmo bloco
  `## <id>` já existente, `Pergunta-9`), com as opções de valor fixo levantadas
  (`'sistema'`, uma string mais identificável, ou o nome/login do próprio Thiago).
  Nenhuma linha ficou de fato criada em HML pela tentativa que falhou (o `INSERT`
  inteiro não foi efetivado pelo SQL Server ao dar erro de `NOT NULL`) — o caminho
  "já existe" (achar por chave natural) não é afetado e continua funcionando.
- **Por que a resposta anterior a este tipo de bloqueio (mesmo padrão de
  `aplicarValoresFixos`/`valoresFixos`) não se aplica direto aqui**: `valoresFixos`
  sobrescreve colunas de **negócio** já presentes na linha de PROD com um valor
  confirmado pelo Thiago (ex. "votado e aprovado") — aqui as colunas nem têm valor
  de origem utilizável (são preenchidas pelo servidor da API noutros domínios, não
  fazem parte do "dado de negócio" da linha em si), e a decisão é sobre um valor de
  **infraestrutura de auditoria**, não sobre replicar/alterar um dado do cedente.
  Tratamento (campo `valoresFixos` vs. constante de auditoria dedicada) só será
  definido depois da resposta chegar.
- Tarefa movida para `tarefas/aguardando-resposta/`. Branch não pushada (regra 8 do
  `AGENTE.md` — só push ao concluir com sucesso, regra 7).
- Nenhum arquivo temporário de investigação ficou para trás (`investigar-catalogo-teste.cjs`
  e as saídas de lint/test/cypress removidas antes do commit; `git status` confirmou
  working tree limpa).

### Ciclo 15 (2026-09-16) — Resposta-9 implementada; resolvedor de catálogo completo (caminho "criar" testado fim a fim contra HML real)

Ao retomar (dúvida `colunas-auditoria-not-null-insert-direto-sql-catalogo-20260916`
já com `Status: respondida` — Thiago confirmou a opção (1), ver Resposta-9 em
`duvidas.md`), teste de conectividade TCP puro repetido contra
`PROD_DB_HOST:PROD_DB_PORT`/`HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois**
(126ms/136ms). Branch já estava limpa (`e41cdf5`, nada não commitado de um
ciclo anterior desta vez).

Commit (branch da tarefa, ainda não pushado): `cypress/support/shared/clonagemCedente.js`
(`USUARIO_AUDITORIA_CEDENTE`, `gerarValoresAuditoriaCedente` — funções/constante
puras novas; `montarInsertCatalogo` alterada) + `__tests__/clonagemCedente.test.js`
(2 testes novos, 1 teste existente reescrito para o novo comportamento).
`npm run lint` (0 erros, os mesmos 4 warnings pré-existentes fora do escopo) e
`npm run test:safety` (102/102) passam.

- **Implementação da Resposta-9**: `montarInsertCatalogo` deixou de simplesmente
  *excluir* as 4 colunas de auditoria do INSERT (comportamento do Ciclo 14, que
  quebrava contra colunas NOT NULL) — agora **substitui** o valor de origem
  (vindo de PROD) por um valor fixo gerado no momento da inserção
  (`gerarValoresAuditoriaCedente`): `dataCadastro`/`dataUltimaAlteracao` = o
  mesmo timestamp (não haveria uma distinção sensata entre os dois para um
  registro recém-criado), `usuarioCadastro`/`usuarioUltimaAlteracao` =
  `USUARIO_AUDITORIA_CEDENTE` (`'sistema'`). Só as colunas de auditoria que de
  fato existem na linha de origem são incluídas (`coluna in linha`) — evita
  forçar essas 4 colunas numa tabela hipotética do domínio que não as tenha.
  `id` continua inteiramente excluído (gerado por HML via `OUTPUT INSERTED.id`,
  nunca reaparece no corpo do INSERT).
- **Por que não reaproveitar `valoresFixos`/`aplicarValoresFixos`** (o mecanismo
  já existente desde o Ciclo 8 para "votado e aprovado"): aquele mecanismo
  sobrescreve colunas de **negócio** com um valor confirmado pelo Thiago sobre
  dado que já tem uma origem de PROD (ex. marcar como aprovado); aqui o valor
  não é um dado de negócio nem tem equivalente útil em PROD (a coluna
  "usuário" de PROD é sempre uma pessoa real, `usuarioCadastro: 'henrique'`
  etc., que não faz sentido copiar para um registro criado por automação) — é
  puramente infraestrutura de auditoria do INSERT em si, calculada no momento
  da execução (timestamp), não declarável estaticamente em
  `mapeamentoCedente.js`. Mesmo raciocínio já registrado no Ciclo 14 ao
  levantar a dúvida, agora confirmado como a distinção correta ao implementar.
- **Testado fim a fim contra PROD/HML reais, caminho "criar" (antes bloqueado)**:
  repetido exatamente o caso que falhou no Ciclo 14 (`MC_CAD_SITUACAO` id 43
  PROD, `descricao = "MAJORADO"`, confirmado ainda ausente em HML antes do
  teste) via `npx cypress run --env
  tags=@cedente,catalogoTabela=MC_CAD_SITUACAO,catalogoIdProducao=43` — passou,
  criou o registro em HML com **id 50**. Conferido por leitura direta
  (`SELECT`, script `.cjs` temporário em `repo/`, removido antes do commit):
  `dataCadastro`/`dataUltimaAlteracao` = timestamp real da inserção (idênticos
  entre si), `usuarioCadastro`/`usuarioUltimaAlteracao` = `"sistema"`, exatamente
  como desenhado. **Esse registro fica de fato em HML** (não é dado de teste
  descartável — é um valor de catálogo real que HML precisava ter mesmo antes
  desta tarefa terminar, para qualquer POC futura que referencie a situação
  "MAJORADO"). O caminho "já existe" (testado no Ciclo 14) não foi reexercitado
  neste ciclo por não ter sido alterado — só o caminho "criar" mudou.
- **Sem dúvida pendente ao final deste ciclo** — o grafo de FK das 4 fases
  (Ciclo 11) e agora o resolvedor de catálogo (Ciclo 13/14/15) estão completos.
  Tarefa **não** movida para `aguardando-resposta/`, permanece em `executando/`
  para o próximo ciclo continuar direto.
- **Próximo passo pendente** (não iniciado): os comandos de INSERT das tabelas
  estruturais (não-catálogo) — usar `MAPEAMENTO_CEDENTE_UNIFICADO`/
  `ordenarTabelasPorDependenciaEstrutural` para calcular a ordem, resolver
  dinamicamente as colunas de negócio de cada tabela via
  `INFORMATION_SCHEMA.COLUMNS` (menos as colunas de auditoria, que devem seguir
  o mesmo tratamento de valor fixo agora implementado para catálogo — não
  reinventar), e then o DELETE (`ordenarTabelasParaExclusaoEstrutural`) para o
  caso "apaga e refaz". Boa forma de começar: escolher a tabela estrutural mais
  simples do grafo (menos dependências) para um primeiro comando fim a fim,
  mesmo padrão incremental já usado para o catálogo.
- Nenhum arquivo temporário ficou para trás (`_tcp_test.cjs`/`_check_situacao.cjs`/
  `_verify.cjs`, além das saídas de lint/test/cypress, removidos antes do commit;
  `git status` confirmou working tree limpa após o commit).

