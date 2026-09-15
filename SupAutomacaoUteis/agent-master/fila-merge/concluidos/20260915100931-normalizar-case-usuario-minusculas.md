---
id: 20260915100931-normalizar-case-usuario-minusculas
modulo: keycloakUser
branch: keycloakUser/normalizar-case-usuario-minusculas
---

## Resumo

Correção de bug de case reportado pelo Thiago: o `username` informado (ex.:
`formalizacao.Automacao`) não era normalizado para minúsculas antes de ser usado no
Keycloak, que sempre grava/retorna o username já em minúsculas (`formalizacao.automacao`).
Isso fazia o `expect` do cenário `@keycloakUsuario` falhar comparando o valor original
(com maiúscula) contra o valor retornado (minúsculo) — não era uma divergência de dado
real, só de case.

Nova função pura `normalizarUsername` (`cypress/support/shared/clonagemUsuarioKeycloak.js`),
aplicada em três pontos, cobrindo os dois modos (único e em lote, que compartilham a mesma
lógica interna):
- `montarPayloadNovoUsuario`: `username` do payload de criação (e o username usado para gerar
  o email inválido/único) sempre normalizado.
- `executarClonagem` (`cypress/support/commands/usuariosKeycloak.js`): `usuarioOrigem` e
  `novoUsername` normalizados logo na entrada — usados daí em diante (busca de origem em PROD,
  busca de conflito em HML, mensagens de dúvida bloqueante, criação) sempre já normalizados.
- Step definition (`gerenciamentoDeUsuarios.js`): o `expect` que comparava
  `usuarioClonado.username` com `Cypress.env('novoUsername')` agora normaliza o lado direito
  antes de comparar.

Detalhes completos em `../../subagents/keycloakUser/docs/documentacao.md`.

## Autoteste já rodado pelo subAgent

- `npm run lint`: 0 erros (mesmos 4 warnings pré-existentes, em arquivos não tocados).
- `npm run test:safety`: 38/38 (4 novos, cobrindo `normalizarUsername` diretamente com o
  cenário exato do bug relatado — `formalizacao.Automacao` → `formalizacao.automacao` — e a
  normalização dentro de `montarPayloadNovoUsuario`, inclusive do email gerado a partir do
  username já normalizado).
- `npx cypress run --env tags=@keycloakUsuario,usuarioOrigem=usuario-inexistente-teste-autoteste-agente,novoUsername=Teste.Case.NORMALIZACAO,novaSenha=...`
  rodado contra o Keycloak real (PROD/HML) com o mesmo usuário de origem fictício (inexistente
  em PROD) já usado nos autotestes anteriores deste módulo — passou (falha esperada, "usuário de
  origem não encontrado", sem crash algum na refatoração). **Não foi possível validar fim a fim o
  caminho de sucesso** (criação real de um usuário com `novoUsername` em maiúsculas, confirmando
  que fica salvo/comparado em minúsculas) sem escolher um `usuarioOrigem` real de PROD — decisão
  que não cabe à automação (mesma limitação documentada nos autotestes anteriores deste módulo); a
  cobertura via `node:test` valida a normalização em si de forma direta e determinística.

## Nenhuma variável de `.env` nova

Esta tarefa não introduziu nenhuma variável de ambiente nova.

## `README.md`/`CLAUDE.md` do repo

Não precisaram de atualização — a mudança é uma correção de bug interna (normalização de
case), não altera o comportamento documentado nem a arquitetura do domínio "Clonagem de
Usuário (Keycloak)".
