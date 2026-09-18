---
id: 20260915130215-clonar-cedente-completo-prod-hml
modulo: cedente
branch: cedente/clonar-cedente-completo-prod-hml
data: 2026-09-17
---

## Resumo

Primeira automação do módulo `cedente`: clona um cedente inteiro de PROD para HML,
percorrendo o ciclo de vida completo — prospect (básico, sem KYC) → proposta (POC, tudo) →
comitê (tudo) → cedente + configuração direta — a partir do CNPJ/CPF informado via `--env
documentoOrigem=...`. Documentação, formalização (com uma exceção pontual, ver abaixo), KYC,
log/auditoria, backups, compliance por CNPJ (`CPL_CEDENTE_*`) e todo o domínio de
operação/liquidação/câmbio ficam de fora. Se o CNPJ/CPF já existir em HML, apaga o cadastro
completo (na ordem certa de FK) e recria a partir de PROD; se faltar pessoa/prospect de
origem em PROD, bloqueia (só loga, nenhuma escrita). Tarefa grande, levou 21 ciclos —
histórico completo em `../../subagents/cedente/docs/documentacao.md` +
`../../subagents/cedente/docs/documentacao-historico.md`.

## O que foi feito (arquitetura completa)

- `cypress/utils/mapeamentoCedente.js` — grafo de dependência real (FK investigada contra
  PROD via `INFORMATION_SCHEMA`/`sys.foreign_keys`) das 122 tabelas do domínio, unificado em
  `MAPEAMENTO_CEDENTE_UNIFICADO`.
- `cypress/support/shared/clonagemCedente.js` — lógica pura/testável: classificação de
  tabela por fase/escopo, construção e ordenação do grafo estrutural (INSERT e a ordem
  inversa para DELETE), decisão de estratégia (`bloqueado-sem-origem`/`criar`/`apagar-e-recriar`)
  e de ação de orquestração, valores fixos de auditoria/votação, `montarInsertCatalogo`/
  `montarInsertEstrutural`/`montarDeleteEmLote`, detecção de ciclo da dependência `cascata`.
- `cypress/support/commands/catalogoCedente.js` — resolvedor genérico de dependência de
  catálogo (`MC_CAD_*` + duas exceções fora do padrão, busca por chave natural em HML, cria
  cópia se faltar).
- `cypress/support/commands/estruturaCedente.js` — INSERT/DELETE estrutural linha a linha
  (dependências `catalogo`/`participante-fixo`/`estrutural`/`cascata` resolvidas por linha),
  orquestração do grafo completo a partir de múltiplas sementes (prospect/POC/comitê).
- `cypress/support/commands/cedente.js` — `cy.resolverEstrategiaClonagemCedente` (leitura),
  `cy.apagarCedenteEmHml`/`cy.inserirGrafoCompletoCedenteEmHml`/`cy.clonarCedenteCompleto`
  (orquestrador completo), `cy.resolverIdCedenteCascataEmHml` (clonagem em cascata do
  cedente vinculado, ou reaproveita o id já existente em HML sem tocar nele).
- `cypress/e2e/features/gerenciamentoDoCedente.feature` +
  `cypress/support/step_definitions/gerenciamentoDoCedente.js` — feature/steps `@cedente`.
- `README.md`/`CLAUDE.md` do repo atualizados (seção "Clonagem de Cedente" completa).

## Decisões de negócio confirmadas pelo Thiago ao longo da tarefa (via Supervisor, `duvidas.md`)

- Tabelas `MC_RAT_RATING_INDICADOR(_ITEM)` tratadas como catálogo fora do padrão `MC_CAD_*`.
- Votante de comitê/ata nunca é o real de PROD — sempre um participante fixo (o próprio
  Thiago, `MC_CAD_ANALISTA`), com todo comitê/ata clonado marcado como votado e aprovado.
- `MC_CED_CEDENTE_VINCULADO.idCedenteVinculado`: clonar em cascata se ausente em HML (nunca
  apagar/recriar um vinculado já existente como efeito colateral).
- `MC_CED_LOGIN` excluída inteira (dado sensível/credencial).
- `MC_CED_ATA`/`MC_CED_ATA_VOTACAO`: exceção pontual à exclusão de documentação, só para
  viabilizar a votação da ata (conteúdo copiado inline, não é arquivo externo).
- Colunas de auditoria NOT NULL em todo INSERT SQL direto: `usuarioCadastro`/
  `usuarioUltimaAlteracao` = `'sistema'` (precedente real nos dados de PROD).

## Autoteste já rodado pelo subAgent

- `npm run lint`: 0 erros (4 warnings pré-existentes, não relacionados a este módulo).
- `npm run test:safety`: 126/126 (toda a lógica pura do domínio — classificação de tabela,
  grafo/ordenação, decisão de estratégia/ação, montagem de INSERT/DELETE, detecção de ciclo
  da cascata).
- `cy.resolverIdCatalogoEmHml` foi testado fim a fim contra PROD/HML reais nos ciclos 14-15
  (`MC_CAD_SITUACAO` criado de verdade em HML) — o restante do pipeline estrutural (INSERT/
  DELETE/orquestrador/cascata) só tem cobertura de lógica pura, por decisão deliberada de não
  criar dado estrutural de teste em HML sem necessidade (ver docs do módulo).

## Não rodado pelo subAgent (fica para a validação do Agent Master / teste manual)

- **`npx cypress run` não roda nesta máquina desde o Ciclo 20**: `cypress verify` reporta "No
  version of Cypress is installed" — o binário baixa mas o unzip nunca termina
  (`Cypress.exe` nunca é extraído), sintoma reconfirmado no Ciclo 21. Parece um problema de
  ambiente/IO local, não de código. Recomendo o Agent Master tentar `npx cypress install
  --force` (ou verificar se o ambiente dele tem o mesmo problema) antes de decidir se isso
  também bloqueia a validação automatizada dele, já que a regra do módulo é o Agent Master não
  re-rodar os testes que o subAgent já rodou — mas aqui o `cypress run` nunca chegou a rodar de
  fato neste ciclo, então não há um resultado de teste fim a fim para reaproveitar.
- **Teste manual real (fim a fim, escrevendo em HML) nunca foi executado** — nem para o
  caminho `criar`, nem `apagar-e-recriar`, nem a cascata de `MC_CED_CEDENTE_VINCULADO`.
  Recomendo ao Thiago escolher um CNPJ/CPF real de PROD (idealmente um cedente pequeno, com
  poucas tabelas satélite, e se possível com um `idCedenteVinculado` preenchido para exercitar
  a cascata) para o primeiro teste manual contra HML.

## Nenhuma variável de `.env` nova

Esta tarefa reaproveita as credenciais de PROD/HML/SQL Server já existentes — nenhuma
variável nova em `.env.example`.
