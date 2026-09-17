# Conhecimento acumulado do módulo cedente

> Este Supervisor não mantém mais um `docs/conhecimento-geral.md` compartilhado (aposentado em
> 2026-09-17). Este módulo é o único que acessa SQL Server direto (fora de API REST) — a seção
> abaixo consolida lições reaproveitáveis por qualquer módulo futuro que vier a precisar do mesmo.

## Lições reaproveitáveis: acesso a SQL Server direto (não via API REST)

- **Script Node temporário pra explorar schema** (`INFORMATION_SCHEMA`/`sys.*` via `dbClient.cjs`,
  fora do Cypress): crie o script `.cjs` **dentro de `repo/`** (raiz do clone, onde `node_modules`
  já está instalado) — fora dele, `require('dotenv')`/`require('mssql/...')` não resolve. Rode com
  `node nome-do-script.cjs` e **apague antes de commitar** (`git status` confirma que não sobrou).
- **SQL Server (PROD/HML) inacessível via rede**: se uma consulta via `dbClient.cjs` travar sem
  produzir saída nem erro (nem timeout do driver, nem erro de autenticação), é sinal de rede/VPN
  indisponível, não consulta lenta/schema inesperado. Diagnóstico rápido: teste de TCP puro
  (`net.createConnection`, sem passar pelo driver `mssql`) contra `*_DB_HOST:*_DB_PORT` (de `.env`)
  — mais rápido que esperar o timeout do driver, que pode não ter timeout configurado. Se
  confirmado, é dúvida bloqueante (regra 8 do `AGENTE.md`) pedindo ao Thiago confirmar VPN/rede —
  não há como o subAgent resolver sozinho.
- **Coluna sem FK física declarada — quando resolver por precedente vs. quando é dúvida
  bloqueante**: conte quantas outras tabelas usam a mesma combinação nome-de-coluna → tabela-alvo
  com FK física real. Duas ou mais ocorrências consistentes (nenhuma divergente) é precedente forte
  o bastante pra resolver sem perguntar, mesmo se a coluna for NOT NULL; uma única ocorrência (ou
  qualquer sinal de que o mesmo nome já apontou pra alvo diferente noutra tabela) continua ambíguo
  — não presumir, e se NOT NULL, vira dúvida bloqueante.
- **Nem toda tabela citada numa tarefa existe de fato no schema**: antes de declarar uma tabela
  satélite como parte do grafo de dependência (mesmo por inferência de padrão de nomenclatura
  `_HIST`/`_LOG`/`_VALIDADE`), confirme a existência real via `INFORMATION_SCHEMA.TABLES` — já
  aconteceu de 3 tabelas citadas por inferência não existirem de verdade no schema.
- **Criar registro em HML via SQL direto (não API REST): colunas de auditoria NOT NULL não se
  preenchem sozinhas.** Diferente dos domínios que criam registro via API REST (o servidor preenche
  `dataCadastro`/`usuarioCadastro`/etc. sozinho), um `INSERT` SQL direto não tem esse
  preenchimento automático — se a coluna for NOT NULL (comum, 38/38 tabelas de catálogo verificadas
  aqui), o SQL Server rejeita o `INSERT` sem valor explícito. Antes do primeiro `INSERT` de um
  módulo novo nesse estilo, confira `INFORMATION_SCHEMA.COLUMNS` para essas colunas na tabela de
  destino — se NOT NULL, decida com o Thiago (regra 8 do `AGENTE.md`, decisão que se propaga pra
  todo `INSERT` do módulo) que valor fixo usar; não invente um valor sozinho, mesmo que pareça
  inócuo (aqui, o precedente encontrado nos próprios dados foi o literal `"sistema"`).

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, levou 21 ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **concluída** (Ciclo 21, 2026-09-17) —
`cy.clonarCedenteCompleto` (`commands/cedente.js`) cobre as 3 ações
(`bloqueado`/`inserir`/`apagar-e-recriar`) fim a fim, incluindo o DELETE
apaga-e-refaz (Ciclo 20) e a execução real da dependência `cascata`
(`MC_CED_CEDENTE_VINCULADO`, Ciclo 21) — os dois últimos itens do "próximo
passo pendente" dos Ciclos 18/19. Branch
`cedente/clonar-cedente-completo-prod-hml`, pushada (commit `86eda12`), aviso
enviado a `agent-master/fila-merge/pendentes/`, tarefa movida para
`tarefas/concluidas/`. `README.md`/`CLAUDE.md` do repo atualizados (domínio
deixou de estar "em implementação"). `npm run lint` (0 erros) e `npm run
test:safety` (126/126) passam; `npx cypress run` seguiu bloqueado pelo mesmo
problema de ambiente (binário não instala, ver Ciclo 20/21 no
`docs/documentacao-historico.md`) — não é um bloqueio de decisão de negócio,
critérios de aceite exigem só `lint`+`test:safety` para a lógica pura.
Histórico ciclo a ciclo completo (Ciclos 20-21) em
`docs/documentacao-historico.md`.

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
  `bloqueado`/`inserir`/`apagar-e-recriar-pendente`, ver correção do Ciclo 20 em
  `docs/documentacao-historico.md`).
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
  tinha o mesmo problema de raiz única — **resolvido no Ciclo 20** (ver
  `docs/documentacao-historico.md`), usando `idProspect`/`idProposta` de
  `cedenteHmlExistente` como sementes do lado HML.

