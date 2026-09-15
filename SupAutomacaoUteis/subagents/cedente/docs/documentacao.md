# Conhecimento acumulado do módulo cedente

## Tarefa `20260915130215-clonar-cedente-completo-prod-hml` — progresso

Tarefa grande (174 tabelas no grafo, esperada em vários ciclos — ver regra 5 do
`AGENTE.md`). Estado atual: **aguardando resposta** (dúvida bloqueante
`mc-rat-rating-indicador-fora-do-padrao-mc-cad`, ver Ciclo 3 abaixo e
`duvidas.md`), branch `cedente/clonar-cedente-completo-prod-hml` (a partir de
`reviewAgents`, ainda não pushada — commits locais até o momento: fases `prospect`
e `poc` mapeadas).

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

1. ~~Montar `cypress/utils/mapeamentoCedente.js`~~ — feito para as fases `prospect`
   (Ciclo 2) e `poc` (Ciclo 3, ver abaixo). Falta ainda `comite`, `cedente`, nessa
   ordem (mesma ordem do ciclo de vida) — repetir o mesmo processo: script de
   investigação real (`INFORMATION_SCHEMA.COLUMNS` + `sys.foreign_keys`) contra
   PROD, um `.cjs` temporário dentro de `repo/` (não commitado, apagar antes do
   commit final do ciclo — ver "Ciclo 2"/"Ciclo 3" para o template reaproveitável),
   e acrescentar as novas entradas em `mapeamentoCedente.js` no mesmo formato
   (`dependeDe: [{ campo, tabela, tipo: 'estrutural'|'catalogo' }]`). **Antes de
   prosseguir para `comite`**: essa fase é bloqueada pela dúvida registrada em
   `duvidas.md` (`mc-rat-rating-indicador-fora-do-padrao-mc-cad`) — a tarefa está em
   `aguardando-resposta/` até o Thiago decidir.
2. ~~Ordem de dependência (FK) entre as tabelas do escopo~~ — a função pura
   (`construirGrafoEstrutural` + `ordenarTabelasPorDependenciaEstrutural`, em
   `clonagemCedente.js`) já existe e é testada (inclusive contra o grafo real da fase
   prospect). Falta só **usá-la** dentro de um comando Cypress real assim que a etapa
   de INSERT/DELETE em HML for escrita — construir o grafo unificado (todas as fases
   já mapeadas) e chamar a função, nunca hardcodar/reordenar manualmente.
3. Ainda não decidido/implementado: como resolver `MC_CED_CEDENTE.idProximaProposta`
   (aponta pra uma próxima proposta, possivelmente fora do "tudo de POC" já coberto se
   for uma proposta futura ainda não comitada) — avaliar no ciclo que implementar a
   fase `cedente`; se ambíguo, é dúvida bloqueante (regra 8 do `AGENTE.md`), não decidir
   sozinho.
4. Comandos genéricos ainda não escritos: a etapa de leitura/join em PROD (localizar
   pessoa+prospect pelo CNPJ/CPF informado via `--env`), a etapa de busca em HML, e a
   etapa de INSERT/DELETE em HML propriamente ditas — hoje só existe a lógica pura de
   decisão (`clonagemCedente.js` + `mapeamentoCedente.js`), nenhum `commands/*.js` ou
   `.feature` novo ainda. Boa próxima etapa (ainda só leitura, sem risco): um comando/
   step `@cedente` que resolve `decidirEstrategiaClonagemCedente` de verdade contra
   PROD/HML pra um CNPJ/CPF passado via `--env` (localizar pessoa+prospect em PROD,
   checar se já existe cedente em HML) — dá um autoteste executável fim-a-fim antes de
   escrever qualquer INSERT/DELETE.
5. Colunas de negócio (o que efetivamente entra no INSERT) foram **propositalmente
   não** transcritas à mão em `mapeamentoCedente.js` — a decisão foi guardar só o
   grafo de dependência (campo/tabela/tipo) e resolver as colunas dinamicamente em
   tempo de execução via `INFORMATION_SCHEMA.COLUMNS` menos um conjunto fixo de
   colunas de auditoria (`id`, `dataCadastro`, `dataUltimaAlteracao`, `usuarioCadastro`,
   `usuarioUltimaAlteracao`) — evita transcrever ~26 listas de coluna à mão (propenso a
   erro/desatualização) e mantém consistência com "calculado, não hardcoded" já
   decidido para a ordem de FK. Ainda não implementado; ver comando `useTasks`
   apontado no item 4.

### Ciclo 2 (2026-09-15) — grafo de FK real da fase prospect + ordenação topológica

Commit `149c8f6`: `cypress/utils/mapeamentoCedente.js` (novo) +
`clonagemCedente.js`/`__tests__/clonagemCedente.test.js` (`construirGrafoEstrutural`,
`ordenarTabelasPorDependenciaEstrutural`). `npm run lint` e `npm run test:safety`
passam (74/74, 0 erros).

- **Investigação real** (script `.cjs` temporário em `repo/`, removido antes do
  commit — template: `require('dotenv').config()` +
  `executeQuery('prod', prodConfig(), 'SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE,
  IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN (...)')` para
  colunas, e a mesma ideia com `sys.foreign_keys`/`sys.foreign_key_columns` +
  `sys.tables`/`sys.columns` para FKs — ambas em uma única query cobrindo todas as
  tabelas da fase de uma vez, em vez de tabela por tabela): 26 tabelas da fase
  prospect + `MC_CAD_PESSOA`, colunas reais e todas as FKs físicas envolvendo essas
  tabelas.
- **Descoberta importante, contraria a suposição da fase por prefixo**: a família
  `MC_PRT_PLEITO*` (`MC_PRT_PLEITO`, `_BOLETO`, `_GARANTIA`, `_PRODUTO`,
  `_PRODUTO_CONC`, `_PRODUTO_FLUXO`, `_PRODUTO_OPERACAO`) tem prefixo `MC_PRT_`
  (sugerindo "prospect") e a tarefa a lista na seção "1. Prospect" — mas a FK real é
  `MC_PRT_PLEITO(...).idProposta -> MC_POC_PROPOSTA.id`, ou seja, essas tabelas só
  podem ser inseridas em HML **depois** que a proposta (fase POC) correspondente já
  existir lá. **Conclusão registrada em `mapeamentoCedente.js`**: a classificação por
  fase (`clonagemCedente.js`) define só ENTRA/FICA-DE-FORA (escopo) — a ordem de
  inserção/exclusão precisa *sempre* vir do grafo de FK real calculado
  (`construirGrafoEstrutural`/`ordenarTabelasPorDependenciaEstrutural`), nunca da
  suposição "processa uma fase inteira, depois a próxima". Isso vale como alerta para
  quem for montar as fases `poc`/`comite`/`cedente`: não presumir que uma tabela
  pertence estruturalmente à fase que a tarefa/prefixo sugere sem confirmar a FK real.
- **Colunas sem FK física declarada** (referência só por convenção de nome, não
  verificável via `sys.foreign_keys`): `MC_AGE_ACOMPANHAMENTO.idCedente` e
  `.idSacado` existem como colunas mas não têm constraint de FK no schema real — não
  resolvidas neste ciclo, decisão adiada pra quando a tabela referenciada
  (cedente/`MC_CAD_SACADO`) for implementada.
- **Precedente aplicado (não é decisão nova)**:
  `MC_AGE_AGENDA_VISITA_RELATORIO.idRelatorioVisitaAnexo` (nullable) aponta pra uma
  tabela de anexo (`MC_AGE_AGENDA_VISITA_ANEXO`, fora do grafo mapeado) — tratado como
  não resolvido/null na cópia, pela mesma razão já decidida na tarefa para
  `MC_CED_CEDENTE.idArquivoLogo` (referência a arquivo/documento, fora de escopo).
  Registrado aqui para deixar claro que não foi uma decisão nova/autônoma sobre tabela
  fora de escopo (o que exigiria dúvida bloqueante, regra 8 do `AGENTE.md`), e sim a
  aplicação do mesmo critério já confirmado pelo Thiago para o caso análogo.

### Ciclo 3 (2026-09-15) — grafo de FK real da fase POC (proposta), tarefa bloqueada ao final

Commit `9eac416` (local, ainda não pushado — só push ao concluir a tarefa com
sucesso, regra 7 do `AGENTE.md`): `cypress/utils/mapeamentoCedente.js`
(`MAPEAMENTO_CEDENTE_POC`, 50 tabelas) + `clonagemCedente.js` (comentário de
`MC_CAD_ARQUIVO` corrigido) + testes novos em `__tests__/clonagemCedente.test.js`.
`npm run lint` (0 erros, 4 warnings pré-existentes fora do escopo) e
`npm run test:safety` (77/77) passam.

- **Investigação real** (mesmo template do Ciclo 2 — `INFORMATION_SCHEMA.COLUMNS` +
  `sys.foreign_keys`, script `.cjs` temporário em `repo/`, removido antes do commit):
  as 28 tabelas explícitas da fase POC citadas na tarefa + as 22 tabelas reais das
  3 famílias citadas só por prefixo (`MC_POC_INCORP_*`, `MC_POC_RATING_*`,
  `MC_POC_RESTRIT*`), enumeradas via `INFORMATION_SCHEMA.TABLES ... LIKE`. Lista
  fechada real (útil pra quem for implementar o `commands/*.js` de leitura em PROD):
  `MC_POC_INCORP_OBRA_ANDAMENTO`, `MC_POC_INCORP_OBRA_CONCLUIDA`,
  `MC_POC_INCORP_RESUMO`, `MC_POC_INCORP_RESUMO_RESULTADO`,
  `MC_POC_RATING_INDICADOR_RESULTADO`, `MC_POC_RATING_RESULTADO`, `MC_POC_RESTRIT`
  (tabela com esse nome exato, âncora da sub-família `RESTRIT_*`),
  `MC_POC_RESTRIT_ACAO_JUDICIAL`, `_DIV_VENCIDA`, `_FALENCIA`, `_PEFIN`,
  `_PROTESTO`, `_RECHEQUE`, `_REFIN`, `_TRIBUTO_DIVIDA`, `_ULTIMAS_CONSULTAS`, e a
  sub-família `MC_POC_RESTRITIVO_*`: `_EVOL_PROTESTO_ANO`, `_EVOL_PROTESTO_MES`,
  `_PROTESTO`, `_PROTESTO_ESTADO`, `_TRAB_ESCRAVO`, `_TRIBUTO_DIVIDA`.
- **Duas dependências cruzam para a fase comitê** (ainda não mapeada), mesmo padrão
  já registrado no Ciclo 2 para `MC_PRT_PLEITO*` → `MC_POC_PROPOSTA`: a ordem real
  vem sempre do grafo de FK, nunca da suposição "fase termina antes da próxima
  começar". `MC_POC_PROPOSTA.idComite` → `MC_CAD_COMITE` (nullable),
  `MC_POC_GARANTIA_REGRA.idPocComite` → `MC_POC_COMITE` (nullable),
  `MC_POC_PRODUTO_GARANTIA_REGRA.idComiteLimiteProduto` → `MC_POC_COMITE_LIMITE_PRODUTO`
  (**NOT NULL** — essa tabela só pode ser inserida em HML depois que a fase comitê
  existir lá).
- **`MC_CAD_ARQUIVO` não é exclusividade das tabelas de documento**: a tarefa
  descrevia `MC_CAD_ARQUIVO` como "só referenciado por tabelas de documento, que já
  estão fora" — mas `MC_POC_PROPOSTA.idArquivo` (tabela-âncora, dentro do escopo)
  também referencia. Aplicado o mesmo critério já confirmado pelo Thiago para
  `MC_CED_CEDENTE.idArquivoLogo`/`MC_AGE_AGENDA_VISITA_RELATORIO.idRelatorioVisitaAnexo`
  (referência a arquivo/documento → não resolvida/fica `null` na cópia) — não é uma
  decisão nova, só aplicação de precedente; o comentário em `TABELAS_FORA_DE_ESCOPO`
  (`clonagemCedente.js`) foi corrigido pra não afirmar mais que é exclusividade de
  documento.
- **Colunas sem FK física** (mesmo padrão do Ciclo 2): `MC_POC_GARANTIA_REGRA.idProposta`
  e `.idComiteProdutoOperacao` (ambas nullable, sem constraint em `sys.foreign_keys`)
  e `MC_POC_PROPOSTA.idAtaReferencial` (nullable, idem) — não resolvidas, mesmo
  tratamento de `MC_AGE_ACOMPANHAMENTO.idCedente`/`.idSacado`.
- **`MC_POC_INCORP_RESUMO` não tem `idProposta`** (só `descricao`/`descricaoGrupo` +
  catálogo) — mais parecida com uma lista compartilhada do que um dado "pertencente"
  a uma proposta específica (quem liga à proposta é `MC_POC_INCORP_RESUMO_RESULTADO`).
  Não é uma dúvida bloqueante da etapa de mapeamento (não muda ENTRA/FICA-FORA nem
  quebra a ordenação), mas é um ponto de atenção pra quem for implementar o INSERT de
  verdade: uma cópia ingênua "uma linha por cedente clonado" pode duplicar o que
  deveria ser uma linha compartilhada entre propostas — avaliar nesse momento.
- **Dúvida bloqueante registrada** (`duvidas.md`,
  `mc-rat-rating-indicador-fora-do-padrao-mc-cad`): `MC_POC_RATING_INDICADOR_RESULTADO.idRatingIndicador`
  (**NOT NULL**) e `.idRatingIndicadorItem` (nullable) apontam pra
  `MC_RAT_RATING_INDICADOR`/`MC_RAT_RATING_INDICADOR_ITEM` — tabelas de catálogo
  aparentes (referenciadas de forma análoga às `MC_CAD_*`: indicador/item de rating,
  dado compartilhado entre propostas, não "pertence" a uma proposta específica), mas
  com prefixo `MC_RAT_`, fora do padrão que `classificarTabelaCedente` sabe resolver
  automaticamente como catálogo (`nomeTabela.startsWith('MC_CAD_')`). Nenhuma das
  duas apareceu na tarefa original — classificá-las é uma decisão nova de escopo
  (regra 8 do `AGENTE.md`: "dúvida sobre como classificar uma tabela nova que não
  estava no escopo original"), não decidida sozinho aqui. Efeito prático: a tabela
  `MC_POC_RATING_INDICADOR_RESULTADO` fica com as arestas resolvidas parcialmente em
  `mapeamentoCedente.js` (catálogo + `idProposta`), mas **não pode ser inserida em
  HML** até a resposta chegar (coluna NOT NULL sem resolução). Tarefa movida para
  `tarefas/aguardando-resposta/`.

