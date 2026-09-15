# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **em andamento**, branch
`cedente/clonar-cedente-completo-prod-hml` (a partir de `reviewAgents`).

### Ciclo 1 (2026-09-15) — lógica pura de classificação/match/estratégia

Commit `42b3154`: `cypress/support/shared/clonagemCedente.js` +
`__tests__/clonagemCedente.test.js` (21 casos, `npm run test:safety` e `npm run lint`
passam, 0 erros).

- `classificarTabelaCedente(nomeTabela)`: transcreve o escopo ENTRA/FICA-DE-FORA da
  tarefa em código — fonte única de verdade para "essa tabela entra na cópia, e em
  qual fase (`prospect`/`poc`/`comite`/`cedente`/`catalogo`)?". Qualquer comando futuro
  que precisar dessa decisão deve importar daqui, não duplicar a lista.
- `normalizarDocumento`/`documentosCoincidem`: match por CNPJ/CPF ignorando máscara.
- `decidirEstrategiaClonagemCedente`: implementa "pessoa+prospect obrigatórios, senão
  bloqueia" e "já existe em HML → apaga e refaz, nunca update".

**Investigação de schema real feita nesse ciclo (só leitura, `INFORMATION_SCHEMA.COLUMNS`
contra PROD, via um script Node temporário reaproveitando `dbClient.cjs`/`.env`, removido
ao final do ciclo — não commitado):**

- **Confirmação importante sobre a chave de match**: `MC_CED_CEDENTE` **não** tem um
  campo de CNPJ/CPF próprio — o documento vive em `MC_CAD_PESSOA.cnpjCpf`, alcançado via
  `MC_CED_CEDENTE.idPessoa` (`int`, `NOT NULL`). Mesma estrutura em `MC_PRT_PROSPECT`
  (`idPessoa`, `NOT NULL`) e no prospect (`idProspect`, nullable em `MC_CED_CEDENTE` —
  compatível com "pessoa+prospect obrigatórios só na origem PROD", não necessariamente
  preenchido em todo cedente já existente). Ou seja: localizar o cedente em HML pelo
  CNPJ/CPF do CNPJ informado exige **join** `MC_CED_CEDENTE.idPessoa = MC_CAD_PESSOA.id`
  e comparar `MC_CAD_PESSOA.cnpjCpf`, não uma coluna direta em `MC_CED_CEDENTE`. Isso
  refina (não contradiz) a redação da tarefa, que descreveu o campo como "equivalente em
  MC_CED_CEDENTE" de forma aproximada.
- `MC_PRT_PROSPECT` tem 17 colunas, incluindo `idCedenteVinculado` (nullable) — um
  prospect pode já apontar de volta para um cedente.
- `MC_CED_CEDENTE` tem 30 colunas, incluindo `idProspect`/`idProposta` (nullable) —
  confirma o encadeamento prospect→proposta→cedente por FK direta na âncora, além do
  encadeamento via comitê.

### Famílias citadas só por prefixo na tarefa (ainda não enumeradas contra o schema real)

A tarefa cita 3 famílias de tabela do domínio POC sem listar cada nome:
`MC_POC_INCORP_*`, `MC_POC_RATING_*`, `MC_POC_RESTRIT*`. `classificarTabelaCedente`
trata essas três por prefixo/regex (não lista fechada) para não arriscar excluir por
engano uma tabela da família ainda não enumerada. **Próximo passo pendente**: rodar
`SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'MC_POC_INCORP_%'`
(e equivalente para as outras duas) contra PROD para ter a lista fechada real, útil na
hora de montar `cypress/utils/mapeamentoCedente.js` tabela por tabela (vai precisar do
nome exato de cada uma, não só do prefixo).

### Próximos passos (para o próximo ciclo continuar, não repetir)

1. Montar `cypress/utils/mapeamentoCedente.js` seguindo o padrão de
   `mapeamentoVinculos.js` (campo `tabela`, `campoIdentificador`, `camposUpdate`,
   `nivelDependencia`, acesso via `cy.executarQuery`) — começar pela fase `prospect`
   (tabela-âncora `MC_PRT_PROSPECT` + `MC_CAD_PESSOA` para resolver a chave de match),
   depois `poc`, `comite`, `cedente`, nessa ordem (mesma ordem do ciclo de vida).
2. Para cada tabela, ainda falta buscar as colunas reais via `INFORMATION_SCHEMA.COLUMNS`
   (só fiz isso para `MC_PRT_PROSPECT`, `MC_CAD_PESSOA`, `MC_CED_CEDENTE` neste ciclo) —
   reaproveitar o mesmo script temporário (não commitado, recriar quando precisar:
   `require('dotenv').config()` + `executeQuery('prod', prodConfig(), 'SELECT
   COLUMN_NAME... FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ...')`, ver
   `cypress/support/db/dbClient.cjs`).
3. Ordem de dependência (FK) entre as tabelas do escopo para o `DELETE`+recriação em
   HML (regra 12 do `AGENTE.md`) ainda não foi transcrita para código — usar
   `sys.foreign_keys`/`sys.foreign_key_columns` contra HML em tempo de execução (não
   hardcodar a ordem, o grafo é grande demais e mais confiável calculado do que
   copiado à mão) para descobrir filhas-antes-de-pais na hora do DELETE.
4. Ainda não decidido/implementado: como resolver `MC_CED_CEDENTE.idProximaProposta`
   (aponta pra uma próxima proposta, possivelmente fora do "tudo de POC" já coberto se
   for uma proposta futura ainda não comitada) — avaliar no ciclo que implementar a
   fase `cedente`; se ambíguo, é dúvida bloqueante (regra 8 do `AGENTE.md`), não decidir
   sozinho.
5. Comandos genéricos ainda não escritos: a etapa de leitura/join em PROD (localizar
   pessoa+prospect pelo CNPJ/CPF informado via `--env`), a etapa de busca em HML, e a
   etapa de INSERT/DELETE em HML propriamente ditas — hoje só existe a lógica pura de
   decisão (`clonagemCedente.js`), nenhum `commands/*.js` ou `.feature` novo ainda.

