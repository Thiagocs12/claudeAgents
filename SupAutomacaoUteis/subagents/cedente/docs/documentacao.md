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

### Ciclos 14-19 (2026-09-16/17) — resolvedor de catálogo, INSERT estrutural, orquestrador e correção de múltiplas raízes (resumo)

Histórico ciclo a ciclo completo em `docs/documentacao-historico.md`. Resumo do que
ficou pronto (tudo ainda vigente, exceto onde um ciclo posterior corrigiu — ver notas):

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
  `bloqueado`/`inserir`/`apagar-e-recriar-pendente`, ver correção do Ciclo 20 acima).
- **Ciclo 19**: corrigido um problema de correção que os Ciclos 16-18 não tinham
  exercitado com dado real (só caminho de skip): `cy.clonarGrafoEstruturalCedente`
  (Ciclo 17) partia de uma única raiz (o prospect) e nunca alcançava POC/comitê/cedente,
  pois `MC_POC_PROPOSTA`/`MC_CAD_COMITE` (âncoras dessas fases) não têm dependência
  estrutural de volta ao prospect — o vínculo real é via a tabela de junção
  `MC_POC_PROSPECT`. Corrigido (commit `03db772`): `cy.clonarGrafoEstruturalCedente`
  passou a receber um mapa de "sementes" (`{ [tabela]: linhas[] }`, uma por âncora de
  fase) em vez de raiz única — um só `reduce` sobre `ordemTabelas` usa a semente quando
  existe, senão cai na busca de satélite genérica (unifica raiz+satélite, sem duplicar
  código; a ordem topológica de `ordemTabelas` já garante a ordem certa entre as
  sementes, ex. comitê antes de proposta). Novos comandos
  `cy.buscarPropostasRelacionadasAoProspectEmProd`/`cy.buscarComitesRelacionadosEmProd`
  (devolvem array vazio, não erro, quando não há relacionado) + função pura
  `construirSementesGrafoEstrutural` (3 testes novos). `npm run lint`/`test:safety`
  (120/120) passam; `cypress run --env tags=@cedente` sem `documentoOrigem` continua
  3/3, nenhuma escrita em HML. Este ciclo identificou (sem resolver ainda) que o DELETE
  tinha o mesmo problema de raiz única — **resolvido no Ciclo 20 acima**, usando
  `idProspect`/`idProposta` de `cedenteHmlExistente` como sementes do lado HML.

