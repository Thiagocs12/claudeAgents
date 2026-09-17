# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **executando** (Ciclo 20) — `cy.clonarCedenteCompleto`
(`commands/cedente.js`) agora cobre as 3 ações inteiras: `bloqueado` (só log),
`inserir` e `apagar-e-recriar` (apaga o grafo estrutural do cedente em HML e
insere de novo a partir de PROD — ver Ciclo 20 abaixo). Branch
`cedente/clonar-cedente-completo-prod-hml`, pushada (commit `77d60a6`), aviso
ainda **não** enviado a `agent-master/fila-merge/pendentes/` — falta a
dependência `cascata` (ver "Próximo passo pendente" abaixo) antes de considerar
a tarefa concluída.

### Ciclo 20 (2026-09-17) — DELETE (apaga-e-refaz) do grafo estrutural em HML

Implementado o item (1) do "próximo passo pendente" do Ciclo 19: o DELETE que
faltava para a estratégia `apagar-e-recriar` deixar de ser só-log.

- **Generalização por ambiente** (`commands/estruturaCedente.js`): os 3
  comandos que antes só liam PROD (`buscarLinhasSatelitesEmProd`,
  `buscarPropostasRelacionadasAoProspectEmProd`,
  `buscarComitesRelacionadosEmProd`) agora recebem `ambiente` (`prod`/`hml`)
  como primeiro parâmetro (renomeados para `...EmAmbiente`) — mesma query,
  reaproveitada pelos dois lados (INSERT a partir de PROD, DELETE a partir de
  HML) sem duplicar lógica. Único ponto de atualização: `cy.clonarGrafoEstruturalCedente`
  (chamador existente) passou a passar `'prod'` explicitamente.
- **Descoberta do grafo a apagar** (`cy.descobrirGrafoEstruturalCedenteEmHml`,
  novo em `estruturaCedente.js`): mesma travessia de
  `cy.clonarGrafoEstruturalCedente` (semente conhecida vs. busca de satélite
  via `montarCondicaoBuscaSatelite`), mas só leitura — em vez de inserir,
  acumula os ids já existentes em HML por tabela (`{ [tabela]: Set<id> }`).
  Como já estamos em HML, não precisa de dois mapas separados
  (`idsHmlPorTabela`/`idsProdPorTabela`) como o INSERT — o id do pai já é o
  valor usado pela FK das tabelas filhas no próprio HML.
- **Sementes do lado HML** (`cy.apagarCedenteEmHml`, novo em `commands/cedente.js`):
  resolvido o achado do Ciclo 19 ("O DELETE tem o mesmo problema de raiz
  única") usando as colunas próprias de `cedenteHmlExistente`
  (`idProspect`/`idProposta`, nullable) como ponto de partida — busca TODAS as
  propostas relacionadas ao prospect em HML
  (`cy.buscarPropostasRelacionadasAoProspectEmAmbiente('hml', ...)`) e todos
  os comitês relacionados a elas (`cy.buscarComitesRelacionadosEmAmbiente('hml', ...)`),
  mesmo raciocínio "tudo relacionado" já usado no INSERT. `idProspect`/`idProposta`
  nulos em `cedenteHmlExistente` simplesmente não semeiam aquela fase (não é
  erro — só significa que este cedente em HML não tem prospect/proposta
  vinculada).
- **Execução do DELETE** (`cy.executarExclusaoEstruturalEmHml` +
  `montarDeleteEmLote`, este último em `shared/clonagemCedente.js`, pura/testada
  via `node:test`): um `DELETE FROM tabela WHERE id IN (...)` por tabela, na
  ordem de `ordenarTabelasParaExclusaoEstrutural` (filhas antes de pais, regra
  12 do `AGENTE.md`). Tabelas de catálogo nunca são apagadas (compartilhadas
  entre cedentes).
- **`cy.clonarCedenteCompleto` religado**: a ação (renomeada de
  `ACAO_CLONAGEM_APAGAR_E_RECRIAR_PENDENTE` para `ACAO_CLONAGEM_APAGAR_E_RECRIAR`,
  já que deixou de ser "pendente") agora chama `cy.apagarCedenteEmHml` e, em
  seguida, `cy.inserirGrafoCompletoCedenteEmHml` (lógica de INSERT do Ciclo 19,
  extraída para um comando próprio para ser compartilhada entre as ações
  `inserir` e `apagar-e-recriar` sem duplicar código).
- **`npm run lint`** (0 erros, mesmos 4 warnings pré-existentes, não
  relacionados a este módulo) e **`npm run test:safety`** (123/123, +3 testes
  novos para `montarDeleteEmLote`) passam.
- **`npx cypress run` não pôde ser exercitado neste ciclo** — problema de
  ambiente (não de código): `npx cypress install`/`cypress install --force`
  baixa o binário mas o unzip nunca termina de verdade (só
  `browser_v8_context_snapshot.bin`, ~117MB, aparece no cache;
  `Cypress.exe` nunca é extraído, `cypress verify` continua reportando "No
  version of Cypress is installed" mesmo depois de limpar o cache e
  reinstalar do zero duas vezes). Um `df -h` simples no mesmo diretório
  também travou e foi movido para segundo plano pela ferramenta de shell —
  sinal de disco/IO anormalmente lento nesta máquina neste momento, não
  específico do Cypress. Não é um bloqueio de decisão de negócio (por isso
  não virou dúvida em `duvidas.md`, regra 8 do `AGENTE.md`) — os critérios de
  aceite da tarefa citam explicitamente `lint`+`test:safety` como a cobertura
  automatizada exigida da lógica pura; o teste fim a fim com dado de negócio
  real já vinha sendo deliberadamente adiado desde os Ciclos 16-18. Registrado
  aqui para o caso de outro módulo esbarrar no mesmo sintoma — se persistir em
  um próximo ciclo, considerar registrar como dúvida bloqueante (mesmo
  precedente do "SQL Server inacessível" de 2026-09-15).

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

### Ciclos 14-18 (2026-09-16/17) — resolvedor de catálogo, INSERT estrutural e orquestrador (resumo)

Histórico ciclo a ciclo completo em `docs/documentacao-historico.md`. Resumo do que
ficou pronto (tudo ainda vigente, exceto onde o Ciclo 19 corrigiu — ver nota):

- **Ciclos 14-15**: `cy.resolverIdCatalogoEmHml` (`catalogoCedente.js`) — resolvedor
  genérico de dependência de catálogo (busca por chave natural em HML via
  `METADADOS_CATALOGO_CEDENTE`, cria cópia se não existir). `montarInsertCatalogo`
  aplica os valores fixos de auditoria da Resposta-9 (`gerarValoresAuditoriaCedente`
  — timestamp + `USUARIO_AUDITORIA_CEDENTE = 'sistema'`). Testado fim a fim contra
  PROD/HML reais (`MC_CAD_SITUACAO` id 50 "MAJORADO" criado de verdade em HML).
- **Ciclo 16**: resolvedor genérico de INSERT ESTRUTURAL (não-catálogo) —
  `resolverDependenciasEstruturais`/`montarInsertEstrutural`
  (`shared/clonagemCedente.js`) + `cy.resolverIdParticipanteFixoEmHml`/
  `cy.resolverValoresDependenciasLinhaEstrutural`/`cy.inserirLinhaEstruturalEmHml`
  (`estruturaCedente.js`, novo). Só testado com lógica pura (`node:test`) — decisão
  deliberada de não criar dado estrutural de teste sem necessidade.
- **Ciclo 17**: orquestrador que percorre o grafo — `dependenciasEstruturaisResolviveis`/
  `montarCondicaoBuscaSatelite` (`shared/clonagemCedente.js`) +
  `cy.clonarGrafoEstruturalCedente`/`cy.buscarLinhasSatelitesEmProd`
  (`estruturaCedente.js`). **Versão original tinha só uma raiz (`tabelaRaiz`/
  `linhaRaiz`, sempre o prospect) — corrigida no Ciclo 19 (ver abaixo), ver o texto
  original completo em `docs/documentacao-historico.md`.**
- **Ciclo 18**: `cy.clonarCedenteCompleto(documento)` (`commands/cedente.js`) — liga
  `cy.resolverEstrategiaClonagemCedente` (leitura) a `cy.clonarGrafoEstruturalCedente`
  (Ciclo 17), com `decidirAcaoOrquestracaoCedente` (função pura, 3 ações:
  `bloqueado`/`inserir`/`apagar-e-recriar-pendente` — DELETE ainda não implementado,
  então este último caminho só loga, nunca insere sobre um cedente já existente em
  HML). Cenário/feature novo `@cedente` (`gerenciamentoDoCedente.feature`,
  `--env documentoOrigem=...`). Só o caminho de skip (sem `documentoOrigem`) foi
  exercitado de verdade — 3/3 passam, nenhuma escrita em HML.

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

