# Histórico detalhado — módulo cedente (Ciclos 1-13)

> Arquivado do `docs/documentacao.md` principal em 2026-09-16 (Ciclo 15), regra 12 do
> `AGENTE.md` (arquivar quando o arquivo principal passar de ~200-250 linhas) — nada foi
> descartado, só movido para cá. O arquivo principal mantém um resumo compacto do que
> ainda é operacionalmente relevante + esta seção completa de Ciclos 1-13. Ciclos 14 em
> diante continuam no arquivo principal até a próxima rodada de arquivamento.

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
nome exato de cada uma, não só do prefixo). **[Resolvido no Ciclo 3 — lista fechada real
já enumerada.]**

### Próximos passos (registrados no Ciclo 1 — todos resolvidos em ciclos posteriores, mantidos aqui só como histórico)

1. ~~Montar `cypress/utils/mapeamentoCedente.js`~~ — feito para as 4 fases (Ciclos 2/3/6/9).
2. ~~Ordem de dependência (FK) entre as tabelas do escopo~~ — `construirGrafoEstrutural`/
   `ordenarTabelasPorDependenciaEstrutural` (Ciclo 2), usadas no grafo unificado (Ciclo 13).
3. ~~`MC_CED_CEDENTE.idProximaProposta`~~ — não voltou a aparecer como bloqueio nos ciclos
   de mapeamento da fase `cedente` (Ciclo 9); se reaparecer ao implementar o INSERT
   estrutural, tratar como dúvida bloqueante se ambíguo.
4. ~~Comandos genéricos de leitura/INSERT/DELETE~~ — leitura/estratégia implementada no
   Ciclo 12, resolvedor de catálogo (equivalente a INSERT para tabelas de domínio
   compartilhado) nos Ciclos 13-15. INSERT estrutural (tabelas não-catálogo) e DELETE
   (apaga-e-refaz) ainda pendentes — ver arquivo principal.
5. ~~Colunas de negócio via `INFORMATION_SCHEMA.COLUMNS` menos colunas de auditoria~~ —
   parcialmente implementado (`montarInsertCatalogo`, Ciclos 14/15, só para catálogo);
   ainda falta para as tabelas estruturais.

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
  `tarefas/aguardando-resposta/`. **[Resolvido — Thiago confirmou tratar como
  catálogo, ver Resposta-1 em `duvidas.md`.]**

### Ciclo 4 (2026-09-15) — dúvida anterior respondida e já implementada; nova dúvida (infraestrutura) ao tentar mapear `comitê`

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, checkout do que já
existia — `git branch -vv` mostrou o HEAD em `5edaad0`, já com a resolução da
dúvida do Ciclo 3 implementada e commitada localmente, ainda não pushada): nenhum
código novo escrito neste ciclo.

- Encontrado um script de investigação `investigar-schema-comite.cjs` já
  preparado em `repo/` (untracked, não commitado — convenção normal, ver
  `docs/conhecimento-geral.md`), pronto pra levantar colunas/FKs reais das 18
  tabelas da fase `comitê` contra PROD. Ao rodar (`node investigar-schema-comite.cjs`),
  o processo ficou sem produzir nenhuma saída por mais de 8 minutos (bem acima do
  tempo que as investigações reais dos Ciclos 2/3 levaram) — sinal de conexão
  travada, não consulta lenta.
- **Diagnóstico** (script `.cjs` temporário descartável, mesmo padrão de
  investigação pontual, removido antes de terminar o ciclo): um teste de TCP puro
  (`net.createConnection`, sem passar pelo driver `mssql`/autenticação Windows)
  contra `PROD_DB_HOST:PROD_DB_PORT` deu timeout em ~8s. Testado também
  `HOMOLOG_DB_HOST:HOMOLOG_DB_PORT` (mesmo `.env`) — **também** timeout. Ou seja,
  não é um problema específico de PROD (nem de credencial/driver): a máquina
  não tinha rota de rede para o SQL Server (nem PROD nem HML) neste momento —
  bem diferente do que se viu nos Ciclos 2/3, quando a mesma investigação
  funcionou normalmente.
- **Isso não é uma dúvida de escopo/negócio** (não é "como classificar uma
  tabela", é infraestrutura da máquina) — mas como não há decisão nenhuma a
  tomar sozinho que resolva isso (rede/VPN não é algo que o subAgent controla) e
  o ciclo não pode prosseguir sem conseguir consultar o schema real, registrado
  como dúvida bloqueante mesmo assim (`duvidas.md`,
  `conexao-sql-server-prod-hml-inacessivel-20260915`), pedindo ao Thiago para
  confirmar VPN/rede — ver seção nova em `../../docs/conhecimento-geral.md`
  sobre esse tipo de bloqueio.
- **Cuidado ao registrar uma segunda dúvida para a mesma tarefa** (a primeira já
  estava `Status: respondida` no arquivo): **não** criar um segundo bloco
  `## <id>` com o mesmo título — a pré-checagem do `run-cycle.ps1`
  (`Test-DuvidaRespondida`) faz `[regex]::Split` por `^## ` e retorna no
  **primeiro** bloco cujo conteúdo comece com o id, então um segundo bloco com o
  mesmo título nunca seria visto (o primeiro, já respondido, faria a
  pré-checagem devolver `$true` incorretamente e a tarefa voltaria pra
  `pendentes/` sem a dúvida nova ter sido respondida de verdade). Consolidado
  num único bloco: o campo `Status:` (sem sufixo) reflete sempre a pergunta
  atualmente em aberto; a pergunta/resposta já resolvida vai para
  `Status-historico-N:`/`Pergunta-N:`/`Resposta-N:` (sufixo numérico), que não
  batem com o regex `^Status:\s*respondida\s*$` da pré-checagem. Ver também a
  seção já existente sobre título de dúvida ter que ser o id exato — este é um
  problema relacionado, mas distinto (não é o título que estava errado, era ter
  dois blocos com o título certo).
- Nenhum arquivo de investigação temporário ficou para trás (`test-tcp-temp.cjs`
  e o `schema-comite-out.json` vazio de uma tentativa anterior interrompida
  foram removidos); `investigar-schema-comite.cjs` continua em `repo/`
  (untracked, não é escopo pra commitar), pronto pra ser rodado assim que a
  rede/VPN for confirmada — não precisa ser reescrito.

### Ciclo 5 (2026-09-15) — dúvida de VPN respondida, mas conexão ainda inacessível

Ao retomar (dúvida `conexao-sql-server-prod-hml-inacessivel-20260915` já com
`Status: respondida`, Thiago confirmou reconexão de VPN), a tarefa voltou de
`aguardando-resposta/` pra `pendentes/` e depois `executando/` normalmente. Branch
`cedente/clonar-cedente-completo-prod-hml` já estava no commit `5edaad0` (nada a
retomar em código, só a investigação de schema da fase `comitê`).

- Repetido o mesmo teste de conectividade TCP pura (`net.createConnection`, script
  `.cjs` temporário em `repo/`, removido antes de terminar o ciclo) contra
  `PROD_DB_HOST:PROD_DB_PORT` (`10.101.1.18:1433`) e `HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`
  (`10.201.1.6:1433`) — **timeout nos dois novamente**, rodado duas vezes seguidas
  pra descartar instabilidade pontual (mesmo resultado nas duas).
- Ou seja, a resposta anterior (VPN reconectada) não se confirmou na prática nesta
  máquina/momento — pode ter caído de novo depois da confirmação, ou a reconexão não
  cobriu a rota até esses hosts especificamente. Não é algo que o subAgent possa
  diagnosticar mais fundo sem acesso à infraestrutura de rede.
- **Nova dúvida registrada em `duvidas.md`, no mesmo bloco `## <id>` já existente**
  (não criado um bloco novo — ver seção já existente em
  `../../docs/conhecimento-geral.md` sobre não duplicar título): a pergunta/resposta
  anterior (VPN) migrou para `Status-historico-2`/`Pergunta-2`/`Resposta-2`; o campo
  `Status`/`Pergunta-3`/`Resposta-3` (sem sufixo o `Status`) agora reflete esta nova
  pergunta, ainda em aberto. Tarefa movida de volta para `tarefas/aguardando-resposta/`.
- Nenhum arquivo temporário de investigação ficou para trás (`test-tcp-temp.cjs`
  removido); `investigar-schema-comite.cjs` continua em `repo/` (untracked), pronto
  pra rodar assim que a conectividade for confirmada de verdade.

### Ciclo 6 (2026-09-15) — VPN ok de novo; grafo real da fase comitê mapeado; nova dúvida (idParticipante)

Ao retomar (dúvida de VPN, `Status-historico-3` em `duvidas.md`, já respondida —
Thiago confirmou reconexão de novo), teste de conectividade TCP puro repetido contra
`PROD_DB_HOST:PROD_DB_PORT` e `HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois**
(126ms/182ms) — rede normalizada. Nota à parte, sem relação com a tarefa: o
`console.log` do próprio `dotenv@17.4.2` (`require('dotenv').config()`) imprime uma
linha de "tip" promocional rotativa (`◇ injected env (N) from .env // tip: ...`,
incluindo uma variante `⌁ auth for agents [www.vestauth.com]`) — investigado a fundo
(`node_modules/dotenv/lib/main.js`, array `TIPS`) porque à primeira vista parecia
saída suspeita/injetada; é comportamento real e documentado do próprio pacote
(`node_modules/dotenv/skills/dotenv/SKILL.md`), não uma dependência comprometida.
Sem ação necessária, só registrado aqui pra quem se deparar com a mesma linha e
estranhar.

Commit `e635eab` (local, ainda não pushado): `cypress/utils/mapeamentoCedente.js`
(`MAPEAMENTO_CEDENTE_COMITE`, 18 tabelas) + 4 testes novos em
`__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, 4 warnings
pré-existentes fora do escopo) e `npm run test:safety` (82/82) passam.

- **Investigação real** (mesmo template dos ciclos anteriores — `INFORMATION_SCHEMA.COLUMNS`
  + `sys.foreign_keys`, script `investigar-schema-comite.cjs`, já preparado em `repo/`
  desde o Ciclo 4, removido após o uso neste ciclo — não é mais necessário, a
  investigação da fase `comitê` está concluída): as 18 tabelas da fase `comitê`
  citadas na tarefa (`TABELAS_POR_FASE[FASE_COMITE]`, já existente em
  `clonagemCedente.js`).
- **`MC_CAD_COMITE`/`MC_CAD_COMITE_PROPOSTA`/`MC_CAD_MODELO_ATA_COMITE`** têm prefixo
  `MC_CAD_` mas já estavam classificadas como estruturais da fase `comitê` (não
  catálogo genérico) desde antes deste ciclo, em `clonagemCedente.js`
  (`TABELAS_POR_FASE[FASE_COMITE]`, checado antes do fallback `MC_CAD_*` em
  `classificarTabelaCedente`) — não uma decisão nova aqui, só confirmado que o grafo
  de FK real é consistente com essa classificação.
- **Duas âncoras estruturais na prática**: `MC_CAD_COMITE` (âncora nominal da fase,
  `TABELA_ANCORA_POR_FASE`) só tem dependência de catálogo; a maioria das satélites
  na verdade depende de `MC_POC_COMITE` (via `idComiteProposta`), que por sua vez
  depende de `MC_POC_PROPOSTA` (fase POC, `idProposta` NOT NULL) — o vínculo entre
  `MC_CAD_COMITE` e `MC_POC_COMITE` só existe indiretamente, via
  `MC_POC_PROPOSTA.idComite` (aresta já registrada na fase POC).
- **Duas dependências cruzam pra fora da fase comitê** (mesmo padrão já registrado
  nos Ciclos 2/3 pra `MC_PRT_PLEITO*`/`MC_POC_PROPOSTA.idComite`): `MC_CAD_COMITE_PROPOSTA.idProposta`
  e `MC_POC_COMITE.idProposta` (ambas NOT NULL) apontam pra `MC_POC_PROPOSTA` (fase
  POC, já mapeada); `MC_PORTAL_COMITE_VOTACAO.idPortalConvenio` (NOT NULL) aponta pra
  `MC_CED_PORTAL_CONVENIO` (fase `cedente`, ainda não mapeada) — registrado como
  aresta estrutural apontando pra uma tabela ainda ausente do mapeamento
  (`construirGrafoEstrutural` trata como folha até lá, comportamento já coberto por
  teste).
- **Colunas sem FK física, nullable** (mesmo tratamento não resolvido já aplicado nos
  ciclos anteriores — `idCedente`/`idSacado`, `idAtaReferencial`, etc.): `MC_POC_COMITE_ATA_HIST.idCedPortalConvenio`
  (aponta por nome pra `MC_CED_PORTAL_CONVENIO`, fase cedente, ainda não mapeada) e
  `MC_POC_COMITE_FUNDO.idPorteEmpresaAdm` (mesmo nome de coluna que
  `MC_POC_FUNDO.IdPorteEmpresaAdm`, fase POC, que **tem** FK física pra
  `MC_CAD_CLASSIFICACAO_EMPRESA` — mas aqui, sem constraint verificável, não
  presumimos o mesmo alvo só por analogia de nome). Nenhuma das duas bloqueia a fase
  (nullable).
- **Dúvida bloqueante nova registrada** (`duvidas.md`,
  `id-participante-sem-fk-fisica-votacao-comite-20260915`, mesmo bloco `## <id>`
  já existente, migrando a pergunta/resposta de VPN pra `Status-historico-3`):
  `idParticipante` (**NOT NULL**, sem constraint de FK física, não existe tabela
  `PARTICIPANTE` no schema) em `MC_POC_COMITE_VOTACAO` e `MC_PORTAL_COMITE_VOTACAO`
  (a mesma coluna também existe em `MC_CED_ATA_VOTACAO`, fase `cedente`, ainda não
  mapeada — resposta serve pras três). Amostra de `MC_POC_COMITE_VOTACAO` tem valores
  de `idParticipante` (39-49) dentro do range de `MC_CAD_ANALISTA` (1-86) — hipótese
  registrada na dúvida, não uma FK verificável. Diferente das colunas nullable sem FK
  física (item acima), esta é NOT NULL — não pode ficar sem resolução, então não dá
  pra só "deixar null" (mesma categoria de decisão do precedente `MC_RAT_RATING_INDICADOR`,
  regra 8 do `AGENTE.md`). Tarefa movida para `tarefas/aguardando-resposta/`.
- Nenhum arquivo temporário de investigação ficou para trás neste ciclo
  (`investigar-schema-comite.cjs`, `investigar-participante.cjs`,
  `investigar-participante2.cjs`, `parse-schema-comite.cjs` e as respectivas saídas
  removidos antes do commit).

### Ciclo 7 (2026-09-15) — idParticipante resolvido (participante fixo); nova dúvida (campo votado/aprovado ambíguo)

Ao retomar (dúvida `id-participante-sem-fk-fisica-votacao-comite-20260915` já com
`Status: respondida` — Thiago respondeu com a decisão completa, ver Resposta-4 em
`duvidas.md`), teste de conectividade TCP puro repetido contra `PROD_DB_HOST:PROD_DB_PORT`
e `HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois** — rede seguia normalizada desde o
Ciclo 6.

Commit `ff6c57c` (local, ainda não pushado): `cypress/utils/mapeamentoCedente.js`
(`idParticipante` em `MC_POC_COMITE_VOTACAO`/`MC_PORTAL_COMITE_VOTACAO` passa a ter
entrada em `dependeDe` com tipo novo `participante-fixo`, tabela `MC_CAD_ANALISTA`) +
`clonagemCedente.js` (`NOME_ANALISTA_RESPONSAVEL_CLONAGEM_CEDENTE`, exportado) + 2
testes novos em `__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, 4
warnings pré-existentes fora do escopo) e `npm run test:safety` (84/84) passam.

- **Resolução de `idParticipante` (primeira metade da Resposta-4)**: implementada
  como um novo tipo de dependência, `participante-fixo` (distinto de `catalogo`)
  porque a semântica é diferente — `catalogo` resolve o valor de cada linha
  buscando o equivalente da referência de PROD em HML; `participante-fixo` **ignora**
  o valor de origem e sempre aponta para o mesmo registro (o do próprio Thiago),
  qualquer que seja a linha. `construirGrafoEstrutural` já ignora qualquer `tipo`
  diferente de `estrutural` (comportamento pré-existente, coberto por teste novo
  específico para este tipo) — nenhuma mudança de lógica central foi necessária, só
  a declaração de dados + a constante do nome. **Confirmado contra HML** (script
  `.cjs` temporário em `repo/`, removido antes do commit): existe exatamente um
  registro ativo em `MC_CAD_ANALISTA` com nome `THIAGO DA COSTA SANTOS` (id 29 no
  momento da checagem — não hardcoded no código, resolvido em tempo de execução
  pela busca por nome, mesmo padrão das dependências de catálogo). A resolução em
  tempo de execução (comando/step que efetivamente faz essa busca e grava o id) só
  será escrita quando a etapa de INSERT for implementada — este ciclo só declara a
  decisão no grafo, mesmo estágio (mapeamento, não execução) dos demais ciclos.
- **Segunda metade da Resposta-4 ("todos os comitês clonados devem ficar marcados
  como votados e aprovados") gerou nova dúvida bloqueante**, seguindo a instrução
  explícita do próprio Thiago na resposta ("se houver ambiguidade... registrar nova
  dúvida específica com os nomes de coluna encontrados em vez de adivinhar"):
  investigação real (`INFORMATION_SCHEMA.COLUMNS` + distribuição de valores reais
  via `GROUP BY`, script `.cjs` temporário em `repo/`, removido antes do commit)
  encontrou `MC_POC_COMITE.situacaoVotacao` (NOT NULL; valores reais:
  `FINALIZADA`=5569, `NAO_INICIADA`=820, `INICIADA`=11, `REABERTA`=8 — claramente o
  campo de "votado") e `MC_POC_COMITE.resultadoVotacao` (nullable, seria o campo
  óbvio de "aprovado/reprovado") **null nas 6408 linhas da amostra, sem exceção** —
  existe no schema mas não é usado na prática em PROD, então não há um valor real
  de "aprovado" pra replicar por precedente. `MC_POC_COMITE_VOTACAO`/
  `MC_PORTAL_COMITE_VOTACAO.situacaoVoto` (`CONCLUIDO`/`PENDENTE`/`AUSENTE`, +
  variante rara `FAVORAVEL` em 5 linhas de `MC_PORTAL_COMITE_VOTACAO`, parece dado
  inconsistente/legado) e `.voto` (nullable, único valor não-nulo observado é
  `FAVORAVEL`) — candidatos pro "aprovado" a nível de voto individual.
  `MC_POC_PROPOSTA.idSituacao` (catálogo `MC_CAD_SITUACAO`, já mapeado como
  dependência de catálogo comum desde o Ciclo 3) é outro candidato possível (a
  aprovação podendo estar representada na proposta, não no comitê/voto em si) —
  seus valores reais ainda não foram investigados. Registrada dúvida bloqueante em
  `duvidas.md` (mesmo bloco `## <id>` já existente — Resposta-4 migrada para
  `Status-historico-4`, nova pergunta em `Pergunta-5`/`Id-original-da-duvida-5`,
  `campo-votado-aprovado-ambiguo-comite-votacao-20260915`) com os nomes de coluna e
  valores reais encontrados, pedindo ao Thiago pra decidir a combinação exata.
  Tarefa movida para `tarefas/aguardando-resposta/`.
- Nenhum arquivo temporário de investigação ficou para trás neste ciclo (testes de
  conectividade e os `.cjs` de investigação de schema/valores/analista, e as
  respectivas saídas, removidos antes do commit).

### Ciclo 8 (2026-09-15) — Resposta-5 implementada; VPN caiu de novo ao tentar mapear a fase `cedente`

Ao retomar (dúvida `campo-votado-aprovado-ambiguo-comite-votacao-20260915` já com
`Status: respondida` — Thiago escolheu a opção recomendada, ver Resposta-5 em
`duvidas.md`), conectividade **não** foi testada antes de implementar a Resposta-5
(não dependia de rede — é só uma decisão de valores fixos sobre o mapeamento já
commitado).

Commit `9de9cf0`: `cypress/utils/mapeamentoCedente.js` (novo campo declarativo
`valoresFixos` em `MC_POC_COMITE` — `{ situacaoVotacao: 'FINALIZADA' }`, propositalmente
sem `resultadoVotacao` — e em `MC_POC_COMITE_VOTACAO`/`MC_PORTAL_COMITE_VOTACAO` —
`{ situacaoVoto: 'CONCLUIDO', voto: 'FAVORAVEL' }`) + `clonagemCedente.js` (função pura
nova `aplicarValoresFixos(nomeTabela, linha, mapeamento)`, sobrescreve só as colunas
declaradas sobre uma linha vinda de PROD, sem mutar o objeto original) + 3 testes
novos em `__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, 4 warnings
pré-existentes fora do escopo) e `npm run test:safety` (87/87) passam.

- **Por que um campo novo (`valoresFixos`) e não reaproveitar `dependeDe`**: a
  semântica é diferente de todos os tipos de dependência já existentes
  (`estrutural`/`catalogo`/`participante-fixo`) — não é uma FK a resolver, é uma
  sobrescrita direta de valor de coluna, sem relação com nenhuma outra tabela. Um
  campo separado e explícito evita forçar esse conceito dentro do modelo de
  dependência (que `construirGrafoEstrutural`/resolução de catálogo não devem nem
  precisam enxergar).
- Ao tentar prosseguir para o próximo passo pendente (mapear o grafo de FK real da
  fase `cedente`, última fase, 28 tabelas — script `investigar-schema-cedente.cjs`,
  mesmo template das fases anteriores), a conexão SQL Server travou de novo (mais de
  6 minutos sem retorno). Diagnóstico (mesmo teste de TCP puro já usado nos Ciclos
  4/5): timeout em PROD e HML de novo. **Terceira vez que esse bloqueio de
  infraestrutura acontece nesta mesma tarefa** — ver
  `../../docs/conhecimento-geral.md` (seção já existente sobre esse tipo de
  bloqueio, não precisou de entrada nova, só mais um caso confirmando o padrão).
  Script `investigar-schema-cedente.cjs` e o teste de TCP temporário removidos antes
  de terminar o ciclo (nenhum arquivo não commitado ficou para trás — `git status`
  confirmou working tree limpa).
- Nova dúvida registrada em `duvidas.md`, **mesmo bloco `## <id>` já existente**
  (Resposta-5 migrada para `Status-historico-5`, nova pergunta em
  `Pergunta-6`/`Id-original-da-duvida-6`, `Status` voltou para `pendente`). Tarefa
  movida para `tarefas/aguardando-resposta/`.

### Ciclo 9 (2026-09-15) — VPN ok; grafo real da fase `cedente` (última fase) mapeado; 3 novas dúvidas

Ao retomar (dúvida de VPN, `Status-historico-6` em `duvidas.md`, já respondida),
teste de conectividade TCP puro repetido contra `PROD_DB_HOST:PROD_DB_PORT` e
`HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois** (~150ms) — rede normalizada.

Commit `765127e` (local, ainda não pushado): `cypress/utils/mapeamentoCedente.js`
(`MAPEAMENTO_CEDENTE_CEDENTE`, 25 tabelas) + `clonagemCedente.js`
(`TABELAS_POR_FASE[FASE_CEDENTE]` corrigida) + 5 testes novos em
`__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, 4 warnings
pré-existentes fora do escopo) e `npm run test:safety` (92/92) passam.

- **Investigação real** (mesmo template dos ciclos anteriores — `INFORMATION_SCHEMA.COLUMNS`
  + `sys.foreign_keys`, script `investigar-schema-cedente.cjs` temporário em `repo/`,
  removido antes do commit): as 28 tabelas da fase `cedente` citadas na tarefa + a
  checagem de existência de `MC_CED_ATA_VOTACAO` (citada só em `duvidas.md`, Resposta-4,
  não na tarefa original).
- **3 tabelas citadas na tarefa não existem de fato no schema**: `MC_CED_GERENTE_FOCO_HIST`,
  `MC_CED_GERENTE_FOCO_LOG` e `MC_CED_FIRMAS_PODERES_REGRA_VALIDADE` — a tarefa assumia
  que eram satélites de `MC_CED_GERENTE_FOCO`/`MC_CED_FIRMAS_PODERES_REGRA`, mas
  `INFORMATION_SCHEMA.TABLES` não retorna nenhuma das três. Não é decisão de escopo, só
  constatação — removidas de `TABELAS_POR_FASE[FASE_CEDENTE]`, ficando 25 tabelas reais
  de 28 citadas.
- **Colunas NOT NULL sem FK física, mas resolvidas por precedente forte (sem dúvida
  nova)**: `MC_CED_FORMULARIO_GARANTIA.idConsultoriaEspecializada`/`.idGarantiaCategoria`
  não têm constraint no schema real, mas são exatamente o mesmo nome+semântica usado
  com FK física de verdade em dezenas de outras tabelas do mesmo módulo (ex.
  `MC_CED_GARANTIA.idGarantiaCategoria -> MC_CAD_GARANTIA_CATEGORIA`) — diferente das
  colunas "sem FK física, não presumidas" dos ciclos anteriores (que tinham mais de um
  alvo plausível), aqui não há ambiguidade real sobre o alvo; resolvidas como `catalogo`
  sem precisar de decisão nova do Thiago.
- **3 dúvidas bloqueantes novas, todas sobre colunas NOT NULL sem resolução automática
  possível** (registradas em `duvidas.md`, mesmo bloco `## <id>` já existente,
  `Pergunta-7`/`Id-original-da-duvida-7`, cobrindo as três num único bloco — mesmo
  padrão do Ciclo 3, que também bundlou 2 tabelas relacionadas numa única pergunta):
  1. `MC_CED_ATA_VOTACAO.idCedenteAta` (NOT NULL) -> `MC_CED_ATA`, tabela de
     documentação explicitamente fora de escopo. A tabela `MC_CED_ATA_VOTACAO` em si
     não estava na lista original da fase `cedente` — só foi citada por nome na
     Resposta-4 (para o tratamento de `idParticipante`), mas o schema real revelou essa
     dependência estrutural incompatível com a exclusão de documentação. Tabela
     deixada de fora de `TABELAS_POR_FASE`/`MAPEAMENTO_CEDENTE_CEDENTE` até a resposta.
  2. `MC_CED_CEDENTE_VINCULADO.idCedenteVinculado` (NOT NULL) aponta pra OUTRO
     `MC_CED_CEDENTE` (cedente relacionado, não o que está sendo clonado) — incompatível
     à primeira vista com a regra "um cedente por execução"; não decidido sozinho como
     tratar (pular a linha se o vinculado não existir em HML? clonar em cascata? nunca
     copiar esta tabela?).
  3. `MC_CED_LOGIN.idLogin` (NOT NULL) aponta pra `MC_LOGIN`, tabela fora do padrão
     `MC_CAD_*`, possivelmente com dado de autenticação/credencial do cedente no portal
     — mesma categoria do precedente `MC_RAT_RATING_INDICADOR` (tabela nova fora do
     padrão), mas potencialmente mais sensível; conteúdo de `MC_LOGIN` não investigado
     a fundo de propósito, para não arriscar expor dado sensível sem autorização.
  Tarefa movida para `tarefas/aguardando-resposta/`. **Com este ciclo, o grafo de FK
  real das 4 fases (prospect/POC/comitê/cedente) está totalmente mapeado** — as 3
  dúvidas pendentes não bloqueiam o restante do grafo, só essas 3 tabelas/colunas
  específicas; o próximo passo depois delas é escrever os comandos de
  leitura/INSERT/DELETE em HML (ainda não iniciado).
- Nenhum arquivo temporário de investigação ficou para trás neste ciclo
  (`investigar-schema-cedente.cjs`, `verificar-tabelas.cjs`, `parse-schema-cedente.cjs`
  e as respectivas saídas removidos antes do commit; `git status` confirmou working
  tree limpa).

### Ciclo 10 (2026-09-16) — itens 2/3 da Resposta-7 implementados; trabalho não commitado de um ciclo anterior corrigido; nova dúvida (item 1)

Ao retomar (tarefa já em `tarefas/executando/`, sem passar por `aguardando-resposta/`
— a dúvida da Resposta-7 nunca tinha `Status: respondida` completo, item 1 seguia
pendente de investigação por decisão explícita do próprio Thiago), a branch já tinha
**alterações não commitadas** de um ciclo anterior (`cypress/support/shared/clonagemCedente.js`
e `cypress/utils/mapeamentoCedente.js`) implementando os 3 itens da Resposta-7 —
incluindo o item 1 (`MC_CED_ATA`/`MC_CED_ATA_VOTACAO`), que aquele ciclo decidiu
incluir no escopo sozinho, sem registrar a nova dúvida que o próprio Thiago pediu
explicitamente ("se não for viável [baixar o documento real], registre isso como
nova dúvida... não decida sozinho"). Nenhum teste novo acompanhava essa parte
(sinal de trabalho incompleto, não só não commitado).

- **Correção**: revertida só a parte do item 1 (remoção de `MC_CED_ATA`/
  `MC_CED_ATA_VOTACAO` de `TABELAS_POR_FASE[FASE_CEDENTE]`, `MC_CED_ATA` de volta em
  `TABELAS_FORA_DE_ESCOPO`, remoção das entradas correspondentes em
  `MAPEAMENTO_CEDENTE_CEDENTE`) — mantidas as partes dos itens 2/3 (já eram decisões
  confirmadas pelo Thiago, não uma decisão autônoma). Commit `af709f8`:
  `MC_CED_CEDENTE_VINCULADO.idCedenteVinculado` com dependência tipo novo `cascata`
  (`TIPO_DEPENDENCIA_CASCATA`, ignorado por `construirGrafoEstrutural`, mesmo padrão
  de `participante-fixo` — execução da cascata em si ainda não implementada, só a
  declaração no grafo); `MC_CED_LOGIN` removida inteira de `MAPEAMENTO_CEDENTE_CEDENTE`
  e movida para `TABELAS_FORA_DE_ESCOPO`. Testes atualizados (2 novos, substituindo o
  teste antigo que checava as duas colunas como "sem dependência" — agora
  `MC_CED_CEDENTE_VINCULADO.idCedenteVinculado` tem dependência real, e `MC_CED_LOGIN`
  nem existe mais no mapeamento). `npm run lint` (0 erros, 4 warnings pré-existentes
  fora do escopo) e `npm run test:safety` (93/93) passam.
- **Investigação real do item 1** (mesmo template de scripts temporários já usado nos
  ciclos anteriores — `INFORMATION_SCHEMA.COLUMNS` contra PROD para `MC_CED_ATA`,
  script `.cjs` removido antes do commit): a premissa da Resposta-7 (existe um
  documento externo, baixável via `mc-documento-ms`/Beyond) **não se confirmou** —
  `MC_CED_ATA` guarda o conteúdo da ata inline (`textoAtaComite`, texto/HTML com
  imagem embutida em base64, provavelmente assinatura/carimbo), não como arquivo
  separado. A única coluna que referencia arquivo de fato (`idArquivo`, nullable, sem
  FK física) segue vazia na maior parte da amostra. Isso muda a pergunta original
  ("é viável baixar o documento?") para uma pergunta diferente ("o Thiago quer copiar
  o conteúdo inteiro da ata como texto inline, sabendo que não há download
  envolvido?") — registrada como nova dúvida específica em `duvidas.md`
  (`mc-ced-ata-conteudo-inline-nao-e-documento-externo-20260916`, mesmo bloco `## <id>`
  já existente, `Pergunta-8`/`Resposta-8`), em vez de decidir sozinho (regra 8 do
  `AGENTE.md` — a tarefa original lista `MC_CED_ATA` nominalmente entre as tabelas de
  documentação excluídas). Tarefa movida para `tarefas/aguardando-resposta/`.
- **Aprendizado registrado em `../../docs/conhecimento-geral.md`**: encontrar
  alterações não commitadas na branch de uma tarefa retomada não significa que o
  trabalho deva ser aceito/commitado como está — pode ser uma decisão de escopo tomada
  sem autorização por um ciclo anterior que ficou sem orçamento antes de seguir o
  protocolo de dúvida corretamente. Revisar o diff contra as regras do `AGENTE.md`
  antes de commitar, não só rodar o autoteste.
- Nenhum arquivo temporário de investigação ficou para trás neste ciclo.

### Ciclo 11 (2026-09-16) — Resposta-8 implementada; grafo de FK das 4 fases completo, sem dúvidas pendentes

Ao retomar (dúvida `mc-ced-ata-conteudo-inline-nao-e-documento-externo-20260916` já
com `Status: respondida` — Thiago escolheu a opção 1, ver Resposta-8 em `duvidas.md`),
teste de conectividade TCP puro repetido contra `PROD_DB_HOST:PROD_DB_PORT` e
`HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois** (146ms/179ms). Branch já estava
limpa (`af709f8`, nada não commitado para revisar desta vez).

Commit `612750b`: `cypress/support/shared/clonagemCedente.js` (`MC_CED_ATA` removida
de `TABELAS_FORA_DE_ESCOPO`, `MC_CED_ATA`/`MC_CED_ATA_VOTACAO` adicionadas a
`TABELAS_POR_FASE[FASE_CEDENTE]`) + `cypress/utils/mapeamentoCedente.js` (duas novas
entradas em `MAPEAMENTO_CEDENTE_CEDENTE`) + 3 testes novos/1 test atualizado em
`__tests__/clonagemCedente.test.js`. `npm run lint` (0 erros, 4 warnings
pré-existentes fora do escopo) e `npm run test:safety` (94/94) passam.

- **Investigação real** (mesmo template dos ciclos anteriores —
  `INFORMATION_SCHEMA.COLUMNS` + `sys.foreign_keys` contra PROD, script `.cjs`
  temporário em `repo/`, removido antes do commit, cobrindo só as 2 tabelas em
  questão): confirmou a estrutura já levantada no Ciclo 10 (`MC_CED_ATA.textoAtaComite`
  nullable, `idArquivo` nullable sem FK física) e revelou o campo que faltava para
  fechar a Resposta-8 — `MC_CED_ATA.situacaoVotacao` (nullable, valores reais em PROD:
  `FINALIZADA`=134, `NAO_INICIADA`=27, `INICIADA`=14, `REABERTA`=4 — mesmo vocabulário
  de `MC_POC_COMITE.situacaoVotacao`). `MC_CED_ATA_VOTACAO.idParticipante` (NOT NULL)
  confirmado sem constraint em `sys.foreign_keys`, igual a `MC_POC_COMITE_VOTACAO`/
  `MC_PORTAL_COMITE_VOTACAO`; `situacaoVoto`/`voto` com o mesmo vocabulário
  (`CONCLUIDO`/`FAVORAVEL` entre os valores reais observados).
- **Implementação**: `MC_CED_ATA` entra na fase `cedente` com `idCedente` (estrutural)
  + `idConsultoriaEspecializada` (catálogo) + `valoresFixos: { situacaoVotacao:
  'FINALIZADA' }` (mesmo padrão de `MC_POC_COMITE`, Resposta-5); `textoAtaComite`
  copiado como está (não é FK, não entra em `dependeDe`), `idArquivo` não resolvido
  (mesmo precedente de `idArquivoLogo`). `MC_CED_ATA_VOTACAO` entra com `idCedenteAta`
  (estrutural → `MC_CED_ATA`) + `idConsultoriaEspecializada` (catálogo) +
  `idParticipante` (tipo `participante-fixo` → `MC_CAD_ANALISTA`, mesmo padrão das
  votações de comitê) + `valoresFixos: { situacaoVoto: 'CONCLUIDO', voto:
  'FAVORAVEL' }`.
- **Com este ciclo, o grafo de FK das 4 fases (prospect/POC/comitê/cedente) está
  completo e sem nenhuma dúvida pendente em aberto** — próximo passo (não iniciado):
  escrever os comandos de leitura em PROD (localizar pessoa+prospect pelo CNPJ/CPF via
  `--env`), busca em HML e INSERT/DELETE, usando o grafo unificado
  (`construirGrafoEstrutural`/`ordenarTabelasPorDependenciaEstrutural` sobre as 4
  constantes `MAPEAMENTO_CEDENTE_*` combinadas) — ver "Próximos passos" do Ciclo 1,
  itens 2 e 4, ainda válidos.
- Nenhum arquivo temporário de investigação ficou para trás neste ciclo (`git status`
  confirmou working tree limpa após o commit).

### Ciclo 12 (2026-09-16) — primeira etapa executável: resolução de estratégia (só leitura), testada fim a fim contra PROD/HML reais

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `612750b`,
working tree limpa — nada a revisar de um ciclo anterior desta vez), teste de
conectividade não foi repetido antes de começar (o passo em si já serve de teste:
se a rede estivesse fora, a query teria travado/dado timeout, sinal equivalente).
Com o grafo de FK das 4 fases já completo (Ciclo 11), este ciclo ataca o próximo
passo pendente listado em "Próximos passos" (item 4): uma etapa só de leitura que
já permite um autoteste executável fim a fim, sem nenhum risco de escrita.

Commit (branch da tarefa, ainda não pushado): `cypress/support/commands/cedente.js`
(novo) + `cypress/support/commands/index.js` (registra o novo módulo) +
`cypress/e2e/features/gerenciamentoDoCedente.feature` (novo, tag `@cedente`) +
`cypress/support/step_definitions/gerenciamentoDoCedente.js` (novo) +
`README.md`/`CLAUDE.md` (nova seção "Clonagem de Cedente", regra 2 do `AGENTE.md`).
`npm run lint` (0 erros, os mesmos 4 warnings pré-existentes fora do escopo) e
`npm run test:safety` (94/94, sem teste novo — nenhuma lógica pura nova foi
necessária, `decidirEstrategiaClonagemCedente`/`normalizarDocumento` já existiam e
já eram testadas) passam.

- **`cy.resolverEstrategiaClonagemCedente(documento)`**: busca em PROD a pessoa
  (`MC_CAD_PESSOA`, por `cnpjCpf` comparado ignorando máscara via `REPLACE`
  encadeado — T-SQL não tem regex nativo, e o conjunto de separadores de
  CPF/CNPJ é fechado: `.`, `-`, `/`) e o prospect vinculado a ela
  (`MC_PRT_PROSPECT.idPessoa`), checa em HML se já existe um cedente para o
  mesmo documento (join `MC_CED_CEDENTE.idPessoa = MC_CAD_PESSOA.id`, já que o
  cedente não guarda CNPJ/CPF próprio — confirmado no Ciclo 1), e devolve o
  resultado de `decidirEstrategiaClonagemCedente` (lógica pura já existente e já
  testada, reaproveitada sem alteração) junto com as 3 linhas de origem
  encontradas (para uso pelo comando de INSERT, ainda não escrito). Nenhuma
  escrita é feita — só 3 `SELECT`s.
- **Step `@cedente`** (`gerenciamentoDoCedente.js`), parametrizado via `--env
  documentoOrigem=...`, mesmo padrão de "parâmetro ausente não quebra o cenário"
  já usado em `gerenciamentoDeUsuarios.js` (loga e pula em vez de falhar, para
  não quebrar uma execução da suíte completa sem a tag). O log final expõe só a
  estratégia resolvida e booleanos (`encontrada`/`não encontrada`), nunca o
  conteúdo das linhas de pessoa/prospect/cedente (que podem conter dado
  pessoal) — consistente com a regra 10 do `AGENTE.md` (não expor dado
  sensível em log/documentação), aplicada aqui por analogia (a regra fala de
  credencial/segredo, mas o mesmo cuidado vale para PII de pessoa física).
- **Autoteste real, fim a fim, contra PROD/HML** (rede OK, sem timeout):
  1. Sem `documentoOrigem` informado → cenário passa, loga aviso, nenhuma query
     roda (path "pulado").
  2. `documentoOrigem` claramente inexistente (`99999999999999`) → estratégia
     `bloqueado-sem-origem`, pessoa/prospect não encontrados, cedente não
     existente em HML.
  3. `documentoOrigem` "00000000000191" (escolhido como um CNPJ obviamente
     fictício para o teste, só dígitos repetidos + sufixo) **na verdade bateu
     com um registro real** em PROD/HML (provável documento de teste/dummy já
     cadastrado no ambiente, não descoberto por mim propositalmente) —
     estratégia resolvida foi `apagar-e-recriar` (pessoa e prospect
     encontrados em PROD, cedente já existente em HML). Achado sem intenção,
     registrado aqui só porque documenta que **ambos os ramos da estratégia
     foram exercitados de verdade** (não só o de "não encontrado") — nenhum
     dado de pessoa/prospect/cedente foi exposto no log (só os booleanos, como
     desenhado), e nenhuma escrita foi feita (o comando é só leitura). Não
     decidi nada sobre esse registro nem tentei investigar quem é — fora do
     escopo deste ciclo.
- **Por que nenhuma lógica pura nova foi necessária**: a decisão de estratégia
  (`decidirEstrategiaClonagemCedente`) e a normalização de documento
  (`normalizarDocumento`) já existiam desde o Ciclo 1 e já tinham cobertura de
  `node:test` — este ciclo só precisou de comandos Cypress finos que buscam os
  3 fatos reais (pessoa/prospect em PROD, cedente em HML) e repassam para essa
  lógica já testada, sem duplicá-la.
- **Próximo passo pendente** (não iniciado): os comandos de INSERT (criação em
  HML, na ordem de `ordenarTabelasPorDependenciaEstrutural` sobre o grafo
  unificado das 4 fases) e DELETE (ordem inversa, para "apaga e refaz") — a
  parte de leitura/decisão de estratégia que os alimenta já está pronta e
  testada (este ciclo).
- Nenhum arquivo temporário ficou para trás (`git status` confirmou working
  tree limpa após o commit, incluindo os arquivos de saída de
  lint/test:safety/cypress run, apagados antes de commitar).

### Ciclo 13 (2026-09-16) — grafo unificado das 4 fases + metadados de chave natural das tabelas de catálogo (só declaração, ainda sem resolvedor)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `2ccd180`,
working tree limpa), teste de conectividade TCP puro repetido contra
`PROD_DB_HOST:PROD_DB_PORT`/`HOMOLOG_DB_HOST:HOMOLOG_DB_PORT`: **OK nos dois**
(124-134ms). Sem dúvida pendente (todas em `duvidas.md` já `Status: respondida`).
Ataca o próximo passo pendente listado no Ciclo 12 ("os comandos de INSERT
(criação em HML)... usando o grafo unificado — construirGrafoEstrutural/
ordenarTabelasPorDependenciaEstrutural sobre as 4 constantes MAPEAMENTO_CEDENTE_*
combinadas"), começando pela parte que dá pra fazer sem nenhum risco de escrita.

Commit (branch da tarefa, ainda não pushado): `cypress/utils/mapeamentoCedente.js`
(`MAPEAMENTO_CEDENTE_UNIFICADO`, `METADADOS_CATALOGO_CEDENTE`) +
`cypress/support/shared/clonagemCedente.js` (`ordenarTabelasParaExclusaoEstrutural`)
+ 3 testes novos/1 test simplificado em `__tests__/clonagemCedente.test.js`.
`npm run lint` (0 erros, os mesmos 4 warnings pré-existentes fora do escopo) e
`npm run test:safety` (97/97) passam.

- **`MAPEAMENTO_CEDENTE_UNIFICADO`**: merge por spread dos 4 mapeamentos por fase
  (confirmado sem colisão de chave — 122 tabelas únicas ao todo) — substitui o
  spread inline que já existia dentro de um teste (Ciclo 9) por uma constante
  exportada e reutilizável por qualquer comando futuro (INSERT/DELETE) que precisar
  do grafo completo, não só pelos testes.
- **`ordenarTabelasParaExclusaoEstrutural`**: função pura nova em
  `clonagemCedente.js`, sempre o inverso exato de
  `ordenarTabelasPorDependenciaEstrutural` (nunca uma ordenação calculada à parte,
  pra nunca divergir se o grafo mudar) — implementa a regra 12 do `AGENTE.md`
  ("filhas antes de pais" no DELETE do apaga-e-refaz).
- **`METADADOS_CATALOGO_CEDENTE`**: investigação real contra PROD
  (`INFORMATION_SCHEMA.COLUMNS`, script `.cjs` temporário em `repo/`, removido
  antes do commit) das 42 tabelas de catálogo referenciadas em algum `dependeDe`
  tipo `catalogo` nas 4 fases — declara, por tabela, se a chave natural (mesma
  convenção já usada em `commands/sincronizacaoNivel.js`,
  `campoDescricao || 'descricao'`, e pedida explicitamente pela tarefa) é
  `descricao` (maioria, 30 tabelas) ou `nome` (`MC_CAD_ANALISTA`,
  `MC_CAD_FORMULARIO`, `MC_CAD_FUNDO`, `MC_CAD_GERENTE_COMERCIAL`,
  `MC_CAD_INDICADOR`, `MC_CAD_INSTITUICAO`, `MC_CAD_SOCIO` — 8 tabelas). Isso é
  leitura de schema, não uma decisão de negócio nova (cada tabela só teve um
  candidato óbvio de coluna) — diferente das dúvidas bloqueantes já registradas
  nesta tarefa para colunas NOT NULL sem candidato nenhum.
- **4 exceções documentadas, propositalmente fora de `METADADOS_CATALOGO_CEDENTE`**
  (sem coluna única e óbvia — não presumidas, resolver quando a tabela que as
  referencia for implementada de fato): `MC_CAD_PESSOA` (já tem resolução própria
  por CNPJ/CPF, `buscarPessoaCedentePorDocumento`; quando referenciada como
  catálogo comum por outra tabela — ex. `MC_PRT_PROSPECT.idPessoaRelacionada` — vai
  precisar do mesmo critério de documento, não do genérico descricao/nome, já que
  nome/razão social não é confiável como chave única de pessoa),
  `MC_CAD_BLOQUEIO` (não tem descricao/nome, parece registrar ocorrências de
  bloqueio por entidade, não um catálogo de tipos), `MC_CAD_FORMULARIO_CAMPO` (não
  tem descricao/nome, só `label` nullable, referenciada por par
  `idFormulario`+`idCampo`), `MC_CAD_PESSOA_SOCIO` (tabela de associação
  `idPessoa`+`idSocio`, não é um catálogo de valor único).
- **Teste de regressão novo** (`METADADOS_CATALOGO_CEDENTE cobre toda tabela de
  catálogo referenciada...`): varre `MAPEAMENTO_CEDENTE_UNIFICADO` coletando toda
  tabela-alvo de `dependeDe` tipo `catalogo` e falha se alguma não tiver metadado
  nem estiver na lista de exceções documentadas — protege contra um ciclo futuro
  adicionar uma nova dependência de catálogo (ex. ao mapear uma tabela nova) sem
  declarar (ou documentar a exceção de) sua chave natural.
- **Ainda NÃO implementado** (não fazer parte deste ciclo por decisão de escopo,
  não por esquecimento): o resolvedor genérico de catálogo em si (comando Cypress
  que usa `METADADOS_CATALOGO_CEDENTE` pra buscar em HML por chave natural e criar
  o registro completo — copiado de PROD, com suas próprias dependências de
  catálogo resolvidas recursivamente — se não existir). Também não implementado:
  os comandos de INSERT das tabelas estruturais (usando
  `MAPEAMENTO_CEDENTE_UNIFICADO`/`ordenarTabelasPorDependenciaEstrutural`) e DELETE
  (`ordenarTabelasParaExclusaoEstrutural`) propriamente ditos, e a resolução
  dinâmica de colunas por `INFORMATION_SCHEMA.COLUMNS` menos as colunas de
  auditoria (já desenhada em "Próximos passos", item 5, mas não codificada).
  Próximo passo natural: implementar o resolvedor genérico de catálogo primeiro
  (mais simples, sem o grafo grande de tabelas estruturais), testado fim a fim
  contra um catálogo real de PROD/HML (mesmo padrão de autoteste do Ciclo 12).
  **[Feito nos Ciclos 14/15.]**
- Nenhum arquivo temporário de investigação ficou para trás (`investigar-catalogo.cjs`
  e a saída de lint/test removidos antes do commit; `git status` confirmou working
  tree limpa).

### Ciclo 14 (2026-09-16) — resolvedor genérico de catálogo implementado e testado; caminho "criar" bloqueado (colunas de auditoria NOT NULL)

> Arquivado do `docs/documentacao.md` em 2026-09-17 (Ciclo 16). O bloqueio de auditoria
> descrito abaixo foi respondido (Resposta-9) e implementado no Ciclo 15 (resumo
> compacto mantido no arquivo principal) — mantido aqui só como registro histórico
> completo, nada foi descartado.

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
  repo (Produtos/Esteiras/Vínculos/Grupos e Permissões) criam em HML via **API REST**
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

## Ciclos 14-18 (2026-09-16/17) — texto completo arquivado do `documentacao.md` (Ciclo 19 compactou)

### Ciclos 14-15 (2026-09-16) — resolvedor genérico de catálogo completo (resumo)

Histórico completo (bloqueio de auditoria, teste fim a fim contra HML real) já estava
arquivado acima. Resumo do que ficou pronto:

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

- **`resolverDependenciasEstruturais`**: sobrescreve, sobre a linha de PROD, só as
  colunas de `dependeDe` já resolvidas em HML (mapa `{campo: valorHml}` calculado
  pelo chamador) e aplica `aplicarValoresFixos` por último — uma coluna sem entrada
  em `valoresResolvidos` (nullable sem valor de origem, ou dependência ainda sem
  resolução automática, ex. `cascata`) mantém o valor original.
- **`montarInsertEstrutural`**: combina `resolverDependenciasEstruturais` +
  `montarInsertCatalogo` (mesmo tratamento de `id`/auditoria já usado no catálogo).
- **`cy.resolverIdParticipanteFixoEmHml()`**: resolve o participante fixo
  (Resposta-4) por chave natural em `MC_CAD_ANALISTA`, reaproveitando
  `cy.buscarRegistroCatalogoPorChaveNaturalEmHml` já existente.
- **`cy.resolverValoresDependenciasLinhaEstrutural`**: percorre `dependeDe` e
  resolve cada dependência `catalogo`/`participante-fixo`/`estrutural`. Encadeado
  via `reduce` sobre `cy.wrap({})`. `cascata` fica sem resolução aqui de propósito.
- **`cy.inserirLinhaEstruturalEmHml`**: resolve + monta o INSERT + executa contra
  HML, devolve o novo id.
- **Só testado com lógica pura desta vez** (`node:test`) — decisão deliberada de
  não exercitar um INSERT estrutural real contra HML neste ciclo (criaria dado de
  negócio "de mentira" sem necessidade).
- Nenhum arquivo temporário ficou para trás.

### Ciclo 17 (2026-09-17) — orquestrador de INSERT estrutural (percorre o grafo)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `c85c25b`,
working tree limpa, sem dúvida pendente), ataca o "próximo passo pendente" do
Ciclo 16: a orquestração que percorre a ordem de dependência estrutural tabela por
tabela.

Commit `675bc69`: 2 funções puras novas em `clonagemCedente.js` +
`cy.clonarGrafoEstruturalCedente`/`cy.buscarLinhasSatelitesEmProd` em
`estruturaCedente.js` + 6 testes novos. `npm run lint` (0 erros) e
`npm run test:safety` (113/113) passam.

- **`dependenciasEstruturaisResolviveis(tabela, mapeamento, tabelasJaProcessadas)`**:
  filtra, de `dependeDe`, só as `estrutural` cuja tabela-pai já está em
  `tabelasJaProcessadas` — uma tabela sem nenhuma dependência estrutural resolvível
  assim (ex.: `MC_CAD_MODELO_ATA_COMITE`, só catálogo) não é satélite de nada já
  processado.
- **`montarCondicaoBuscaSatelite`**: monta o `WHERE` (`campo IN (ids...)` por
  dependência, unidas por `AND`) que localiza em PROD as linhas satélite de uma
  tabela para as tabelas-pai já processadas. Une por `AND` (não só um pai) para
  tabelas de junção com mais de um pai estrutural já processado (ex.:
  `MC_CAD_COMITE_PROPOSTA`, depende de `MC_CAD_COMITE` **e** `MC_POC_PROPOSTA`).
  Devolve `null` quando a tabela não é satélite de nada já processado e `'1 = 0'`
  para a parte de um pai já processado mas sem nenhuma linha.
- **`cy.buscarLinhasSatelitesEmProd(tabela, condicaoWhere)`**: `SELECT *` simples
  com a condição já pronta.
- **`cy.clonarGrafoEstruturalCedente(ordemTabelas, tabelaRaiz, linhaRaiz,
  mapeamento)` — versão ORIGINAL, substituída no Ciclo 19 por uma versão com
  múltiplas "sementes" (ver `documentacao.md`, o problema descoberto foi que esta
  versão original só descobria a partir de UMA raiz — o prospect — e nunca
  alcançava POC/comitê/cedente numa clonagem real)**: inseria a linha-raiz única,
  iniciava `idsHmlPorTabela`/`idsProdPorTabela` com ela, e então percorria as
  tabelas restantes de `ordemTabelas` (pulando catálogo) via busca de satélite.
  Encadeado inteiramente via `reduce` sobre `cy.wrap(...)`.
- **Só testado com lógica pura desta vez** (`node:test`) — o orquestrador em si
  ainda não tinha sido exercitado contra PROD/HML reais nesta versão.
- Nenhum arquivo temporário ficou para trás.

### Ciclo 18 (2026-09-17) — orquestrador completo (`cy.clonarCedenteCompleto`)

Ao retomar (branch `cedente/clonar-cedente-completo-prod-hml`, commit `675bc69`,
working tree limpa, sem dúvida pendente), ataca o item (1) do "próximo passo
pendente" do Ciclo 17: um comando/feature que encadeie
`cy.resolverEstrategiaClonagemCedente` (já existia) com
`cy.clonarGrafoEstruturalCedente` (Ciclo 17).

Commit `6cfd36d`: `cy.clonarCedenteCompleto(documento)` em `commands/cedente.js`
(versão ORIGINAL — a chamada a `cy.clonarGrafoEstruturalCedente` foi atualizada no
Ciclo 19 para usar sementes múltiplas, ver `documentacao.md`) + função pura nova
`decidirAcaoOrquestracaoCedente` (4 testes novos) + cenário/steps novos em
`gerenciamentoDoCedente.feature`/`step_definitions`. `npm run lint` (0 erros) e
`npm run test:safety` (117/117) passam.

- **`decidirAcaoOrquestracaoCedente(estrategia)`**: traduz a estratégia já
  resolvida em uma de 3 ações (`ACAO_CLONAGEM_BLOQUEADO`/`ACAO_CLONAGEM_INSERIR`/
  `ACAO_CLONAGEM_APAGAR_E_RECRIAR_PENDENTE`).
- **`cy.clonarCedenteCompleto(documento)`**: resolve a estratégia e ramifica pela
  ação. `bloqueado` só loga o motivo (nenhuma escrita). `inserir` (nesta versão
  original) chamava `cy.clonarGrafoEstruturalCedente` com a tabela-âncora do
  prospect e a linha já resolvida — **este caminho tinha um problema de correção
  não percebido ainda** (ver Ciclo 19, `documentacao.md`: a busca de satélite nunca
  alcançava POC/comitê a partir só do prospect). **`apagar-e-recriar-pendente`**
  (cedente já existe em HML): como o DELETE ainda não existe, este caminho só loga
  a situação e nunca chama o orquestrador de INSERT.
- **Cenário/feature novo** (`@cedente`, `gerenciamentoDoCedente.feature`):
  parametrizado por `--env documentoOrigem=...`, mesmo padrão de "parâmetro
  ausente não quebra o cenário, só loga e pula".
- **Só o caminho de skip foi exercitado de verdade** (`npx cypress run --env
  tags=@cedente`, sem `documentoOrigem` — 3/3 cenários de `@cedente` passam,
  nenhuma escrita em HML).
- Nenhum arquivo temporário ficou para trás.

### Ciclo 19 (2026-09-17) — descoberta de múltiplas raízes (prospect+proposta+comitê) para o orquestrador de INSERT

> Arquivado do `docs/documentacao.md` em 2026-09-17 (compactação de rotina, regra 12 do
> `AGENTE.md`). O padrão de sementes múltiplas descrito abaixo está resumido no arquivo
> principal; o item "DELETE ainda não resolvido"/"próximo passo pendente" citado no
> texto original foi implementado no Ciclo 20 (resumo compacto mantido no arquivo
> principal) — mantido aqui só como registro histórico completo, nada foi descartado.

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
