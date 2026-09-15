---
id: 20260914174624-clonar-usuarios-em-lote, 20260914180911-nao-copiar-email-usar-invalido-unico
modulo: keycloakUser
branch: keycloakUser/clonar-usuarios-em-lote
---

## Resumo

Modo em lote de clonagem de usuário Keycloak PROD→HML (`cy.clonarUsuariosKeycloakEmLote`, tag
`@clonarUsuariosEmLote`), complementando o modo único já mergeado (`keycloakUser/clonar-usuario-prod-hml`).
Detalhes completos em `../../subagents/keycloakUser/docs/documentacao.md` (seção "Tarefa concluída:
clonagem em lote de usuários Keycloak PROD→HML").

**Atualização (tarefa `20260914180911-nao-copiar-email-usar-invalido-unico`, commit adicional
`f489b47` na mesma branch, ainda não mergeada):** correção pedida pelo Thiago — o email do novo
usuário em HML **nunca mais é copiado do usuário de origem** (nos dois modos, único e em lote);
agora é sempre um email gerado, inválido/não-real e único (`gerarEmailInvalidoUnico`, formato
`{novoUsername}.{sufixo}@invalido.multiplica.local`). Isso elimina por completo o caso de "dúvida
bloqueante" de conflito de email em HML (não tem mais como colidir). Detalhes completos em
`../../subagents/keycloakUser/docs/documentacao.md` (seção "Correção: nunca copiar email do
usuário original").

## Autoteste já rodado pelo subAgent

- `npm run lint`: 0 erros.
- `npm run test:safety`: 31/31 (17 relacionados a este recurso).
- `npx cypress run --env tags=@clonarUsuariosEmLote` rodado de verdade contra o Keycloak real
  (PROD/HML), com um fixture temporário (não commitado) contendo um único usuário de origem
  inexistente — passou, resultado agregado `0/1 sucesso, 1 dúvida bloqueante` com o motivo
  correto. Modo único (`@keycloakUsuario`) revalidado com o mesmo usuário fictício, comportamento
  inalterado (lança erro, como antes da refatoração).
- Fixture commitado (`cypress/fixtures/usuariosParaClonar.json`) é um template vazio (`{}`) — não
  populado com usuário real de PROD (decisão de "qual usuário copiar" não é da automação).

## Observação para o Agent Master rodar os testes de novo antes de mesclar

Antes de rodar `npx cypress run --env tags=...` de verdade, `cypress/temp/tokens.json` precisa
existir (mesmo vazio, `{}`) — na primeira execução num clone novo ele não existe, e há um bug
pré-existente (não corrigido, fora do escopo desta tarefa — ver
`../../docs/conhecimento-geral.md`, seção "Cypress + node:test/Promises nativas...", item 4) que
faz isso falhar "duro" em vez de ser tratado. Contorno: `mkdir -p cypress/temp && echo '{}' >
cypress/temp/tokens.json` antes de rodar pela primeira vez naquele clone (gitignored, não precisa
reverter).

## Nenhuma variável de `.env` nova

Esta tarefa não introduziu nenhuma variável de ambiente nova.

## Autoteste da correção de email (commit `f489b47`)

- `npm run lint`: 0 erros (mesmos 4 warnings pré-existentes, em arquivos não tocados por esta
  correção).
- `npm run test:safety`: 34/34 (3 novos, cobrindo `gerarEmailInvalidoUnico` e
  `montarPayloadNovoUsuario` nunca copiando o email de origem, sempre gerando emails diferentes
  entre chamadas).
- `npx cypress run --env tags=@clonarUsuariosEmLote` e depois `--env tags=@keycloakUsuario,...`
  rodados de novo contra o Keycloak real (PROD/HML), com o mesmo usuário de origem fictício
  (inexistente em PROD) usado no autoteste original — ambos falham exatamente com a mesma mensagem
  de "usuário de origem não encontrado" de antes da mudança (a checagem de username, que roda antes
  da geração de email, é o que barra esse caso; comportamento inalterado). Não foi possível testar
  fim a fim o caminho de sucesso (criação real com o novo email gerado) sem escolher um usuário real
  de PROD — decisão que não cabe à automação; a cobertura de `gerarEmailInvalidoUnico`/
  `montarPayloadNovoUsuario` via `node:test` cobre a lógica de geração em si.
