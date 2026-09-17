# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **executando** (Ciclo 19) — o comando/feature que
encadeia `cy.resolverEstrategiaClonagemCedente` -> `cy.clonarGrafoEstruturalCedente`
(`cy.clonarCedenteCompleto`) já existe e agora sabe descobrir múltiplas raízes
(prospect+proposta+comitê, ver Ciclo 19 abaixo). Branch
`cedente/clonar-cedente-completo-prod-hml` (a partir de `reviewAgents`, ainda não
pushada). Falta: a resolução da dependência `cascata` (`MC_CED_CEDENTE_VINCULADO`,
ainda não tratada) e o DELETE (apaga-e-refaz, `ordenarTabelasParaExclusaoEstrutural`,
única coisa que falta para a estratégia "apagar-e-recriar" deixar de ser
"pendente"/só-log em `cy.clonarCedenteCompleto`) — o DELETE tem o mesmo problema de
"múltiplas raízes" que o Ciclo 19 resolveu para o INSERT (ver nota no fim do Ciclo 19),
ainda não resolvido para o lado da exclusão.

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

### Ciclo 17 (2026-09-17) — orquestrador de INSERT estrutural (percorre o grafo)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `c85c25b`,
working tree limpa, sem dúvida pendente — as 9 dúvidas registradas até aqui já
estavam todas `respondida`), ataca o "próximo passo pendente" deixado pelo Ciclo 16:
a orquestração que percorre a ordem de dependência estrutural tabela por tabela.

Commit `675bc69`: 2 funções puras novas em `clonagemCedente.js` +
`cy.clonarGrafoEstruturalCedente`/`cy.buscarLinhasSatelitesEmProd` em
`estruturaCedente.js` + 6 testes novos em `__tests__/clonagemCedente.test.js`.
`npm run lint` (0 erros, mesmos 4 warnings pré-existentes) e `npm run test:safety`
(113/113) passam.

- **`dependenciasEstruturaisResolviveis(tabela, mapeamento, tabelasJaProcessadas)`**:
  filtra, de `dependeDe`, só as `estrutural` cuja tabela-pai já está em
  `tabelasJaProcessadas` (um `Set`, alimentado pelo orquestrador conforme avança na
  ordem topológica) — uma tabela sem nenhuma dependência estrutural resolvível assim
  (ex.: `MC_CAD_MODELO_ATA_COMITE`, só catálogo) não é satélite de nada já
  processado.
- **`montarCondicaoBuscaSatelite(tabela, mapeamento, tabelasJaProcessadas,
  idsProdPorTabela)`**: monta o `WHERE` (`campo IN (ids...)` por dependência,
  unidas por `AND`) que localiza em PROD as linhas satélite de uma tabela para as
  tabelas-pai já processadas. **Decisão de implementação (não de escopo/negócio,
  não registrada como dúvida)**: unir por `AND` em vez de considerar só um pai —
  necessário para tabelas de junção com mais de um pai estrutural já processado
  (ex.: `MC_CAD_COMITE_PROPOSTA`, depende de `MC_CAD_COMITE` **e**
  `MC_POC_PROPOSTA`); filtrar só por um dos dois traria linhas de outros
  comitês/propostas não relacionados ao cedente sendo clonado. Devolve `null`
  quando a tabela não é satélite de nada já processado (orquestrador pula, não
  insere às cegas) e `'1 = 0'` para a parte de um pai já processado mas sem
  nenhuma linha (nada a buscar, evita gerar um `IN ()` inválido).
- **`cy.buscarLinhasSatelitesEmProd(tabela, condicaoWhere)`**: `SELECT *` simples
  com a condição já pronta — nenhuma lógica adicional aqui, a decisão já foi tomada
  antes de chamar.
- **`cy.clonarGrafoEstruturalCedente(ordemTabelas, tabelaRaiz, linhaRaiz,
  mapeamento)`**: insere a linha-raiz (a tabela-âncora, ex. o prospect de origem já
  resolvido por `cy.resolverEstrategiaClonagemCedente`), inicia
  `idsHmlPorTabela`/`idsProdPorTabela` com ela, e então percorre as tabelas
  restantes de `ordemTabelas` (pulando tabelas de catálogo, resolvidas à parte por
  `cy.resolverIdCatalogoEmHml`): para cada uma, monta a condição de busca satélite,
  busca em PROD, insere cada linha encontrada via `cy.inserirLinhaEstruturalEmHml`
  já existente (reaproveitado, não duplicado) e acumula os ids. Encadeado
  inteiramente via `reduce` sobre `cy.wrap(...)` — tanto para percorrer as tabelas
  em ordem quanto, dentro de cada tabela, para suas várias linhas satélite (mesma
  armadilha de Promise nativa vs. `cy.` já documentada em `conhecimento-geral.md`).
- **Só testado com lógica pura desta vez** (`node:test`), mesma decisão deliberada
  do Ciclo 16: o comando orquestrador em si (`cy.clonarGrafoEstruturalCedente`)
  ainda não foi exercitado contra PROD/HML reais — faria sentido rodar isso já
  criando dados de negócio reais em HML (um cedente inteiro), o que só deve
  acontecer quando o Thiago confirmar qual cedente real usar para o teste fim a
  fim completo (mesmo raciocínio já registrado no Ciclo 16).
- **Próximo passo pendente**: (1) um comando/feature que encadeie
  `cy.resolverEstrategiaClonagemCedente` (já existe) →
  `cy.clonarGrafoEstruturalCedente` (novo) usando
  `ordenarTabelasPorDependenciaEstrutural(construirGrafoEstrutural(MAPEAMENTO_CEDENTE_UNIFICADO))`
  como `ordemTabelas`; (2) resolver a execução real da dependência `cascata`
  (`MC_CED_CEDENTE_VINCULADO` — buscar o cedente vinculado em HML por CNPJ/CPF,
  disparar a clonagem recursiva se ausente, detectar ciclo A-vinculado-a-B-
  vinculado-a-A, conforme Resposta-7/item 2); (3) o DELETE (apaga-e-refaz,
  `ordenarTabelasParaExclusaoEstrutural`, um cedente por execução, regra 12 do
  `AGENTE.md`). Nenhum arquivo temporário ficou para trás (`git status` confirmou
  working tree limpa após o commit).

### Ciclo 18 (2026-09-17) — orquestrador completo (`cy.clonarCedenteCompleto`)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `675bc69`,
working tree limpa, sem dúvida pendente — todas as 9 já `respondida`), ataca o
item (1) do "próximo passo pendente" do Ciclo 17: um comando/feature que
encadeie `cy.resolverEstrategiaClonagemCedente` (já existia) com
`cy.clonarGrafoEstruturalCedente` (Ciclo 17).

Commit `6cfd36d`: `cy.clonarCedenteCompleto(documento)` em
`commands/cedente.js` + função pura nova `decidirAcaoOrquestracaoCedente`
(`shared/clonagemCedente.js`, 4 testes novos) + cenário/steps novos em
`gerenciamentoDoCedente.feature`/`step_definitions`. `npm run lint` (0 erros,
mesmos 4 warnings pré-existentes) e `npm run test:safety` (117/117) passam.

- **`decidirAcaoOrquestracaoCedente(estrategia)`**: traduz a estratégia já
  resolvida (`ESTRATEGIA_BLOQUEADO_SEM_ORIGEM`/`ESTRATEGIA_CRIAR`/
  `ESTRATEGIA_APAGAR_E_RECRIAR`) em uma de 3 ações
  (`ACAO_CLONAGEM_BLOQUEADO`/`ACAO_CLONAGEM_INSERIR`/
  `ACAO_CLONAGEM_APAGAR_E_RECRIAR_PENDENTE`) — função pura separada só para
  cobrir a decisão com `node:test` sem depender do Cypress, mesmo padrão já
  usado no resto do arquivo.
- **`cy.clonarCedenteCompleto(documento)`**: resolve a estratégia e ramifica
  pela ação. `bloqueado` só loga o motivo (nenhuma escrita). `inserir` monta
  `ordemTabelas` via `ordenarTabelasPorDependenciaEstrutural(
  construirGrafoEstrutural(MAPEAMENTO_CEDENTE_UNIFICADO))` e chama
  `cy.clonarGrafoEstruturalCedente` com a tabela-âncora do prospect
  (`TABELA_ANCORA_POR_FASE[FASE_PROSPECT]`) e a linha já resolvida
  (`prospectOrigem`). **`apagar-e-recriar-pendente`** (cedente já existe em
  HML): **decisão de implementação, não de escopo** — como o DELETE
  (apaga-e-refaz) ainda não existe, este caminho só loga a situação e nunca
  chama o orquestrador de INSERT, para nunca duplicar/quebrar por violação de
  chave um cedente que já existe em HML. Isso não contorna nem decide a
  lógica de negócio "apaga e refaz" (já confirmada pelo Thiago) — só reflete
  que essa metade ainda não foi escrita; passa a inserir de verdade assim que
  o DELETE for implementado, sem precisar de nova decisão.
- **Cenário/feature novo** (`@cedente`, `gerenciamentoDoCedente.feature`):
  parametrizado por `--env documentoOrigem=...` (mesmo parâmetro já usado pelo
  cenário de estratégia), mesmo padrão de "parâmetro ausente não quebra o
  cenário, só loga e pula" já usado nos demais steps deste arquivo.
- **Só o caminho de skip foi exercitado de verdade** (`npx cypress run --env
  tags=@cedente`, sem `documentoOrigem` — 3/3 cenários de `@cedente` passam,
  nenhuma escrita em HML): mesma decisão deliberada dos Ciclos 16/17 de adiar
  o teste fim a fim (que criaria dado de negócio real em HML) para quando o
  Thiago confirmar qual cedente usar.
- **Branch ainda não pushada** (só commit local) — a tarefa continua
  incompleta (cascata + DELETE faltando), mesmo padrão dos ciclos anteriores.
- **Próximo passo pendente**: (1) resolver a execução real da dependência
  `cascata` (`MC_CED_CEDENTE_VINCULADO` — buscar o cedente vinculado em HML
  por CNPJ/CPF, disparar clonagem recursiva via `cy.clonarCedenteCompleto` se
  ausente, detectar ciclo A-vinculado-a-B-vinculado-a-A, conforme
  Resposta-7/item 2); (2) o DELETE (apaga-e-refaz,
  `ordenarTabelasParaExclusaoEstrutural`, um cedente por execução, regra 12 do
  `AGENTE.md`) — depois de implementado, trocar
  `ACAO_CLONAGEM_APAGAR_E_RECRIAR_PENDENTE` em `cy.clonarCedenteCompleto` para
  de fato apagar e então inserir. Nenhum arquivo temporário ficou para trás
  (`git status` confirmou working tree limpa após o commit).

### Ciclo 19 (2026-09-17) — descoberta de múltiplas raízes (prospect+proposta+comitê) para o orquestrador de INSERT

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `6cfd36d`,
working tree limpa, sem dúvida pendente), antes de atacar o "próximo passo
pendente" do Ciclo 18 (cascata/DELETE), revisei o `git diff`/estado da
implementação existente (regra do `conhecimento-geral.md`, "Alterações não
commitadas... revisar contra o AGENTE.md antes de continuar") e, ao reler
`cy.clonarGrafoEstruturalCedente` com atenção ao mapeamento real, encontrei um
problema de correção que os Ciclos 16-18 não tinham exercitado com dados reais
(só o caminho de skip, sem `documentoOrigem`):

- **O achado**: `cy.clonarGrafoEstruturalCedente` (Ciclo 17) partia de uma
  única raiz (`tabelaRaiz`/`linhaRaiz`, sempre o prospect) e descobria o resto
  só por busca de satélite (`dependenciasEstruturaisResolviveis`/
  `montarCondicaoBuscaSatelite` — uma tabela só é encontrada se tiver, ela
  mesma, uma dependência estrutural para uma tabela-PAI já processada). Mas
  `MC_POC_PROPOSTA` (âncora da fase POC) e `MC_CAD_COMITE` (âncora da fase
  comitê) **não têm nenhuma dependência estrutural de volta para
  `MC_PRT_PROSPECT`** (`MC_POC_PROPOSTA.dependeDe` só tem catálogo +
  `idComite`; `MC_CAD_COMITE.dependeDe` só tem catálogo) — partindo só do
  prospect, essas duas âncoras (e tudo que dependesse delas: toda a fase
  POC/comitê/cedente) nunca eram alcançadas pela busca de satélite; ficavam
  "processadas" sem nenhuma linha real, silenciosamente. Um clone real teria
  produzido só o prospect (e satélites diretos dele), sem POC/comitê/cedente
  nenhum — só não foi percebido antes porque nenhum ciclo anterior rodou isso
  contra dados reais (decisão deliberada dos Ciclos 16-18, para não criar dado
  de negócio de teste sem necessidade).
- **A causa raiz**: o vínculo real prospect -> proposta é a tabela de junção
  `MC_POC_PROSPECT` (`idProspect` + `idProposta`, ambas colunas estruturais já
  mapeadas) — não uma FK direta entre as duas âncoras. Não há decisão de
  negócio nova aqui (a tarefa original já diz "tudo o que tiver da POC, tudo o
  que tiver de comitê" — confirma clonar TODAS as propostas/comitês
  relacionados, não só o mais recente), então resolvido sem dúvida bloqueante
  (regra 8 do `AGENTE.md` — é correção de uma lacuna de implementação dentro
  do escopo já confirmado, não inclusão de tabela nova nem mudança de regra de
  negócio).
- **A correção** (commit `03db772`): `cy.clonarGrafoEstruturalCedente` agora
  recebe um mapa de "sementes" (`{ [tabela]: linhas[] }`, uma por
  tabela-âncora de fase) em vez de `tabelaRaiz`/`linhaRaiz` único — um só
  `reduce` sobre `ordemTabelas` usa a semente quando existe, senão cai na
  busca de satélite genérica de sempre (unifica a inserção de raiz e satélite
  num só loop, eliminando a duplicação de código que existia antes). Novos
  comandos em `estruturaCedente.js`:
  `cy.buscarPropostasRelacionadasAoProspectEmProd` (via `MC_POC_PROSPECT`) e
  `cy.buscarComitesRelacionadosEmProd` (via `idComite` das propostas
  encontradas) — ambos devolvem array vazio (não erro) quando não há
  relacionado, tratado como "nada a semear" naquela fase. Nova função pura
  `construirSementesGrafoEstrutural` (`shared/clonagemCedente.js`, 3 testes
  novos) monta o mapa de sementes. `cy.clonarCedenteCompleto` (`commands/cedente.js`)
  chama essa descoberta antes de orquestrar.
- **`npm run lint`** (0 erros, mesmos 4 warnings pré-existentes) e
  **`npm run test:safety`** (120/120, +3 novos) passam. `npx cypress run --env
  tags=@cedente` (sem `documentoOrigem`) continua 3/3 passando, nenhuma
  escrita em HML — mesma decisão deliberada dos ciclos anteriores de adiar o
  teste fim a fim com dado de negócio real para quando o Thiago confirmar qual
  cedente usar.
- **A ordem topológica garante a correção da inserção das sementes**: como
  `ordemTabelas` já é a ordenação topológica do grafo unificado, `MC_CAD_COMITE`
  sempre aparece antes de `MC_POC_PROPOSTA` (que depende dele via `idComite`)
  — inserir as sementes na ordem em que aparecem em `ordemTabelas` (em vez de
  todas de uma vez, sem ordem) já resolve suas próprias dependências
  cruzadas entre si, sem lógica extra.
- **O DELETE (apaga-e-refaz) tem o mesmo problema de raiz única, ainda não
  resolvido**: quando o cedente já existe em HML, o ponto de partida
  conhecido é só `cedenteHmlExistente` (a linha de `MC_CED_CEDENTE`) — mas
  essa linha **guarda `idProspect`/`idProposta` (nullable) como colunas
  próprias** (ver `MAPEAMENTO_CEDENTE_CEDENTE.MC_CED_CEDENTE` em
  `mapeamentoCedente.js`), o que dá uma forma direta de encontrar as raízes de
  prospect/POC a apagar em HML (diferente do INSERT, que precisou descobrir
  via `MC_POC_PROSPECT`) — mas ainda falta implementar essa descoberta do lado
  HML (`buscarPropostaEmHmlPorId`/equivalente) e o comando de exclusão em si
  (`ordenarTabelasParaExclusaoEstrutural`, regra 12 do `AGENTE.md`). Registrar
  isso como parte do próximo passo pendente, não uma dúvida bloqueante (é
  outra aplicação do mesmo padrão de "sementes múltiplas" já resolvido aqui,
  não uma decisão de negócio nova).
- **Próximo passo pendente**: (1) implementar o DELETE (apaga-e-refaz) —
  descobrir em HML as linhas existentes do cedente (a partir de
  `cedenteHmlExistente.idProspect`/`.idProposta`, mais o próprio
  `cedenteHmlExistente`, seguindo o mesmo grafo estrutural mas lendo de HML em
  vez de PROD) e excluir na ordem de `ordenarTabelasParaExclusaoEstrutural`,
  um cedente por execução (regra 12 do `AGENTE.md`); (2) resolver a execução
  real da dependência `cascata` (`MC_CED_CEDENTE_VINCULADO`); (3) depois de
  (1), trocar `ACAO_CLONAGEM_APAGAR_E_RECRIAR_PENDENTE` em
  `cy.clonarCedenteCompleto` para de fato apagar e então inserir. Nenhum
  arquivo temporário ficou para trás (`git status` confirmou working tree
  limpa após o commit).

