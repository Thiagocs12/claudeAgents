---
id: 20260915130215-clonar-cedente-completo-prod-hml
modulo: cedente
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição

Nova automação (primeira do módulo `cedente`): clonar um cedente inteiro de PROD para HML,
percorrendo o ciclo de vida completo do banco — **prospect → pleito → proposta → comitê →
cedente** — e recriando em HML tudo que for necessário pra esse cadastro existir e funcionar lá,
sem os dados que são só histórico/auditoria/execução financeira.

Mapeamento do schema real (PROD) já feito pelo Supervisor via `INFORMATION_SCHEMA` +
`sys.foreign_keys` — ver o diagrama publicado (`mapa-cedente-diagrama.html`, na raiz do
Supervisor) pro contexto visual. O escopo abaixo já foi refinado e confirmado pelo Thiago
(2026-09-15) — não é rascunho.

### Como funciona o "clona tudo, exceto"

O Thiago descreveu a intenção assim: *"copiar o básico do prospect que houver e seja necessário,
tudo o que tiver da POC, tudo o que tiver de comitê, documentação não precisa, cedente e tudo o
que tiver de configuração direta — sem log, sem bkp, sem CPL, sem MOP/títulos, sem operações, sem
liquidações, sem KYC. Pessoa e prospect são obrigatórios pra criação. Se o cedente já existir em
HML, apaga o cadastro dele inteiro e refaz."*

## Escopo — o que ENTRA na cópia

Reaproveitar, pra cada tabela, o mesmo padrão já usado em Produtos/Esteiras/Vínculos
(`sincronizacaoNivel.js`/`dependencias.js`/`estoque.js`): buscar em PROD, resolver dependências
(inclusive tabelas de catálogo `MC_CAD_*` genéricas — ver nota de dependências abaixo), localizar
o correspondente em HML, criar o que faltar.

**1. Prospect (básico, o que houver)** — tabela-âncora `MC_PRT_PROSPECT`. Copiar o registro do
prospect de origem e as tabelas satélite que existirem para ele, **exceto KYC**:
`MC_PRT_LEAD`, `MC_PRT_DADOS_MERCADO`, `MC_PRT_DADOS_OPERACIONAIS`, `MC_PRT_DADOS_INSTALACAO`,
`MC_PRT_CONCORRENTES`, `MC_PRT_CAPEX`, `MC_PRT_FILIAL`, `MC_PRT_FORNECEDORES`,
`MC_PRT_IMPORTACAO`, `MC_PRT_PRINCIPAIS_CLIENTES`, `MC_PRT_PRINCIPAIS_PAISES`,
`MC_PRT_PRODUTO_GARANTIA`, `MC_PRT_PROSPECT_REJEITADO`, `MC_PRT_PLEITO` (+ `_BOLETO`,
`_GARANTIA`, `_PRODUTO`, `_PRODUTO_CONC`, `_PRODUTO_FLUXO`, `_PRODUTO_OPERACAO`),
`MC_PRT_PRIORIZACAO_PROPOSTA`, `MC_AGE_ACOMPANHAMENTO`, `MC_AGE_AGENDA_VISITA` (+
`_RELATORIO`), `MC_CAD_SACADO`. **Fora**: `MC_PRT_KYC`.

**2. Proposta (POC) — tudo** — tabela-âncora `MC_POC_PROPOSTA`. Copiar a proposta e todas as
tabelas satélite existentes: `MC_POC_ALAVANCAGEM`, `MC_POC_BACEN`, `MC_POC_BALANCO`,
`MC_POC_BENS_SOCIOS`, `MC_POC_COAF`, `MC_POC_COMPLIANCE`, `MC_POC_ENDIVIDAMENTO` (+
`_LANCAMENTO`), `MC_POC_FATURAMENTO`, `MC_POC_FROTA`, `MC_POC_FUNDO`, `MC_POC_GARANTIA_REGRA`,
`MC_POC_GRUPO_FATURAMENTO` (+ `_INTERCOMPANY`), `MC_POC_INCORP_*`, `MC_POC_LANDBANK`,
`MC_POC_MEIO_CIRCULANTE`, `MC_POC_PARAMETRO_CLAIM`, `MC_POC_PARAMETRO_SETOR`, `MC_POC_PLEITO`
(+ `_BOLETO`, `_GARANTIA`, `_PRODUTO`), `MC_POC_PRODUTO_GARANTIA_REGRA`,
`MC_POC_PROSPECT` (+ `_FATURAMENTO`, `_FATURAMENTO_INTERCOMPANY`), `MC_POC_RATING_*`,
`MC_POC_RENOVACAO`, `MC_POC_RESTRIT*` (todas as `MC_POC_RESTRITIVO_*`), `MC_POC_PROPOSTA_HIST`.

**3. Comitê — tudo** — `MC_CAD_COMITE` (cadastro/agenda), `MC_CAD_COMITE_PROPOSTA` (join com a
proposta), `MC_CAD_MODELO_ATA_COMITE`, `MC_POC_COMITE` (decisão), `MC_POC_COMITE_ATA` (+
`_HIST`), `MC_POC_COMITE_FUNDO`, `MC_POC_COMITE_GARANTIA`, `MC_POC_COMITE_LIMITE_BOLETO`,
`MC_POC_COMITE_LIMITE_GLOBAL`, `MC_POC_COMITE_LIMITE_PRODUTO`, `MC_POC_COMITE_PRODUTO_CONC`,
`MC_POC_COMITE_PRODUTO_FLUXO`, `MC_POC_COMITE_PRODUTO_GARANTIA`, `MC_POC_COMITE_PRODUTO_OPERACAO`,
`MC_POC_COMITE_VOTACAO` (+ `_PRODUTO`), `MC_PORTAL_COMITE_VOTACAO`.

**4. Cedente + configuração direta** — tabela-âncora `MC_CED_CEDENTE`. Copiar o cedente e as
tabelas de config ligadas por `idCedente` que **não** são documento/formalização/operação/
liquidação: `MC_CED_FILIAL`, `MC_CED_FUNDO`, `MC_CED_SEGMENTO`, `MC_CED_SITUACAO`,
`MC_CED_PRODUTO`, `MC_CED_CEDENTE_VINCULADO`, `MC_CED_GERENTE_FOCO` (+ `_HIST`, `_LOG`),
`MC_CED_GARANTIA` (+ `_HIST`, `_REGRA`), `MC_CED_FORMULARIO_GARANTIA`, `MC_CED_LOGIN`,
`MC_CED_PORTAL` (+ `_CONVENIO`), `MC_CED_CEDENTE_CONVENIO`, `MC_CAD_CONVENIO_PORTAL`,
`MC_CAD_CLASSIFICACAO_PORTAL`, `MC_CED_FIRMAS_PODERES_REGRA` (+ `_VALIDADE`),
`MC_CED_PARAMETRO_OPERACAO` (é parâmetro de configuração, não movimento — entra),
`MC_CED_SETUP` (+ `_EXC`), `MC_CED_COMPLIANCE`, `MC_CED_OBSERVACAO`,
`MC_CED_LOCAL_COBRANCA_NN`, `MC_ENT_DOCUMENTO_KIT` **fica de fora** (é documento, ver abaixo).

## Escopo — o que FICA DE FORA

- **Documentação e formalização inteira**: `MC_CED_CEDENTE_DOCUMENTO` (+ `_HIST`, `_SECAO`,
  `_SECAO_HIST`), `MC_CED_ANEXO`, `MC_CED_ATA`, `MC_ENT_DOCUMENTO_KIT`,
  `MC_CED_CEDENTE_CONTRATO` (+ `_HISTORICO`), `MC_CADASTRO_CEDENTE_FORMALIZACAO`,
  `MC_CADASTRO_CEDENTE_ADMINISTRADOR*` (toda a família), `MC_CED_FORMALIZACAO_IA` (+ `_DOCS`),
  `TB_BEYOND_FORMALIZACAO_CADASTRO_CEDENTE*` (toda a família — integração com plataforma externa
  "Beyond"). Campo `MC_CED_CEDENTE.idArquivoLogo` fica sem resolver (null) na cópia, pela mesma
  razão — é referência a arquivo/documento.
- **KYC do prospect**: `MC_PRT_KYC`, `MC_CAD_PERGUNTAS_KYC` (catálogo usado só por ela).
- **Log/auditoria técnica**: `LOG_ATUALIZA_CEDENTE_COMITE`, `LOG_ATUALIZA_PLEITO_COMITE`,
  `LOG_COPIA_PLEITO_CREDITO_COMITE`.
- **Backups pontuais**: qualquer tabela com sufixo `_BKP*` (ex.: `MC_CED_CEDENTE_CONVENIO_BKP20231020`,
  `MC_PRT_PROSPECTBKP1504`).
- **Compliance por CNPJ (bureau externo)**: toda a família `CPL_CEDENTE_*` (não tem FK pro
  cedente, é casada por `cnpj`/`codigoGrupo`, dado analítico recalculado, não cadastro).
- **Domínio inteiro de operação/liquidação/câmbio** (confirmado pelo Thiago: fora por completo,
  incluindo config de cobrança): `MC_MOP_OPERACAO`, `MC_MOP_PRE_OPERACAO` (+ `_BATCH`, `_EXC`,
  `_TITULO_EXC`), `MC_MOP_SIMULACAO`, `MC_MOP_TITULOS`, `MC_MOP_NOTA_XML`,
  `MC_MOP_ENTIDADE_ARQUIVO`, `MC_LIQ_INSTRUCAO` (+ `_LOTE`, `_LOTE_ARQUIVO_ITEM`),
  `MC_LIQ_ORDEM_PAGAMENTO`, `MC_CAMBIO_ORDEM_PAGAMENTO` (+ `_PRE`), `MC_CED_BOLETO`,
  `MC_CED_TARIFA`, `MC_CED_EVENTO_TARIFA`, `MC_PENDENCIA`, `MC_RECIBO_PENDENCIA`, `MC_RECOMPRA`,
  `MC_PROV_OPERACAO`, `MC_CHECAGEM_DIARIA` (+ `_HISTORICO`), `MC_BEYOND_INSTRUCAO_BAIXA_LOG`,
  `MC_BEYOND_PROTESTO_PROCESSO`, `MC_PORTAL_FORNECEDOR_ARQUIVO` (+ `_RETORNO`,
  `_PRE_CADASTRO`).

## Dependências de catálogo (MC_CAD_* genéricas) — reaproveitar padrão existente

Muitas tabelas incluídas no escopo têm colunas `idConsultoriaEspecializada`, `idPessoa`,
`idSituacao`, `idProduto`, `idAnalista`, `idFundo`, `idGrupoEconomico`, `idIndicador`,
`idSegmentoTarifador`, `idGerenteComercial`, `idConsultor`, `idConsultoria`, `idCanal`,
`idGarantiaCategoria`, `idFormulario`/`idFormularioCampo`, `idTipoProposta`, `idTipoProspect*`,
`idSegmentoTarifador`, `idBloqueio`, `idTipoInstalacao`, `idTipoInvestimento`,
`idFocoNegocio`, `idIndicadorEconomico`, `idModeloContrato`, `idVinculoEsteira` etc. —
essas são tabelas de **catálogo/domínio compartilhado** (`MC_CAD_PESSOA`,
`MC_CAD_CONSULTORIA_ESPECIALIZADA`, `MC_CAD_SITUACAO`, `MC_CAD_PRODUTO`, `MC_CAD_ANALISTA`,
`MC_CAD_FUNDO`, etc.), **não** dado que "pertence" ao cedente/proposta em si. Resolver pelo mesmo
padrão já implementado em `dependencias.js`/`estoque.js`/`sincronizacaoNivel.js` (busca em HML por
chave natural — descrição/nome —, cria se não existir, guarda no estoque de ids) em vez de tratar
como cópia profunda por tabela. `MC_CAD_ARQUIVO` fica fora desse mapeamento (só é referenciado por
tabelas de documento, que estão fora do escopo).

## Regra de match e "já existe → apaga e refaz"

- **Chave de match do cedente entre PROD e HML**: CNPJ/CPF (`document_number`/campo equivalente em
  `MC_CED_CEDENTE`) — confirmado pelo Thiago (2026-09-15). Não usar o `id` (é gerado por ambiente,
  não é estável entre PROD e HML).
- **Se já existir um cedente com esse CNPJ/CPF em HML**: apagar o cadastro inteiro dele em HML
  (todas as tabelas do escopo "o que ENTRA" listado acima, respeitando a ordem de dependência —
  filhas antes de pais, seguindo as mesmas foreign keys já mapeadas) e recriar do zero a partir dos
  dados atuais de PROD. Não é um "update" registro a registro — é apagar e recriar.
- **Nunca** apagar em lote sem confirmação explícita de qual cedente (parametrizado por CNPJ/CPF
  via `--env`, no mesmo padrão de `usuarioOrigem` da clonagem de usuário Keycloak). Um cedente por
  execução.
- **Pessoa (`MC_CAD_PESSOA`) e Prospect (`MC_PRT_PROSPECT`) são obrigatórios pra criação** —
  confirmado pelo Thiago: se não existir prospect de origem (ou a pessoa vinculada) em PROD pro
  CNPJ/CPF informado, é dúvida bloqueante, a automação não decide criar um cedente "solto" sem
  essas duas origens.

## Critérios de aceite

- Parametrizado por CNPJ/CPF do cedente de origem via `--env` (mesmo padrão dos outros domínios do
  repo).
- Clona prospect (básico, sem KYC) → tudo de proposta (POC) → tudo de comitê → cedente +
  configuração direta, na ordem correta de dependência.
- Documentação, formalização (incluindo Beyond), KYC, log, backup, CPL_CEDENTE_*, e todo o domínio
  de operação/liquidação/câmbio ficam de fora, conforme listado acima.
- Se o CNPJ/CPF já existir em HML: apaga o cadastro completo (escopo "ENTRA") e recria a partir de
  PROD.
- Se não existir prospect/pessoa de origem em PROD: dúvida bloqueante, nunca cria cedente sem essa
  origem.
- Tabelas de catálogo (`MC_CAD_*` genéricas) resolvidas pelo padrão de dependência já existente no
  repo, não duplicadas por tabela.
- `npm run lint` e `npm run test:safety` passam, cobrindo a lógica pura (classificação de tabelas,
  regra de match, decisão apaga-e-refaz vs. cria) com `node:test`.
- `README.md`/`CLAUDE.md` do repo documentam o novo domínio "Cedente" (mesmo padrão das seções já
  existentes de Usuários/Grupos e Permissões).

## Material de apoio

- Diagrama completo (ciclo de vida + tabelas + legenda): `mapa-cedente-diagrama.html`, raiz de
  `C:\Multiplica\claudeAgents\SupAutomacaoUteis` (também publicado como Artifact, ver
  `docs/conhecimento-geral.md` se precisar do link).
- Números de referência do levantamento (PROD, 2026-09-15): 174 tabelas distintas com alguma FK no
  grafo do cedente, 330 relações de FK mapeadas, 66 tabelas referenciam `idCedente` diretamente, 28
  referenciam `idProspect`, 51 referenciam `idProposta`.
- Decisões de escopo confirmadas pelo Thiago nesta refinamento (2026-09-15): documentação/
  formalização fora por completo (inclusive contrato e Beyond); operação/liquidação/câmbio fora por
  completo (inclusive boleto/tarifa); match por CNPJ/CPF; pessoa+prospect obrigatórios; apaga e
  refaz se já existir.
