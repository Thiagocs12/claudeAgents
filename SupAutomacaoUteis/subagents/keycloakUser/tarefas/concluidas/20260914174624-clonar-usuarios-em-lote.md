---
id: 20260914174624-clonar-usuarios-em-lote
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-14
---

## Descrição

Extensão da automação de clonagem de usuário Keycloak PROD→HML (tarefa original
`20260914115110-clonar-usuario-keycloak-prod-hml`, já concluída e mergeada). Hoje o recurso só roda
para **um usuário por execução**, via `cypress --env` (`usuarioOrigem`, `novoUsername`,
`novaSenha`). Esta tarefa **complementa** esse modo (não substitui) com um **modo em lote**: uma
lista de usuários definida no próprio código, processada numa única execução do Cypress.

### Formato da lista

Fixture JSON (ex.: `cypress/fixtures/usuariosParaClonar.json`), como um **mapa** de
`usuarioProd: usuarioHml` — chave é o username de origem em PROD, valor é o novo username a criar
em HML. Exemplo de formato (valores fictícios):

```json
{
  "joao.silva": "joao.silva.hml",
  "maria.souza": "maria.souza.hml"
}
```

### Senha de cada usuário criado pela lista

Sempre a senha temporária fixa **`Automacao@123`**, criada como credencial `temporary: true` no
Keycloak (mecanismo padrão dele para forçar troca de senha) — o usuário é obrigado a trocar a senha
no primeiro login. Não gerar senha aleatória, não pedir senha por item da lista.

Isso vale **só para o modo em lote**. O modo de execução único via `--env` continua exatamente como
está hoje (não mudar o comportamento de senha desse modo).

### Execução

Novo cenário/tag Cucumber (ex. `@clonarUsuariosEmLote`) que lê o fixture inteiro e clona todos os
usuários listados numa única execução — reaproveitando integralmente a lógica de clonagem já
implementada (`cypress/support/shared/clonagemUsuarioKeycloak.js` e o que mais já existir da tarefa
original), só iterando sobre a lista. Não duplicar a lógica de clonagem.

### Comportamento por item da lista (dúvida bloqueante é por item, não trava o lote inteiro)

Se um item específico da lista cair em um dos casos que a tarefa original já trata como dúvida
bloqueante (usuário de origem não encontrado em PROD, role/grupo sem correspondente em HML,
username/email já existente em HML) — registrar a dúvida referenciando qual `usuarioProd`/
`usuarioHml` especificamente, e **continuar processando o restante da lista** na mesma execução, em
vez de abortar o lote inteiro por causa de um item problemático.

## Critérios de aceite

- Rodar a tag `@clonarUsuariosEmLote` (ou nome equivalente) com o fixture populado clona, numa
  única execução, todos os usuários da lista — cada um com login válido em HML, senha temporária
  `Automacao@123` marcada para troca obrigatória no primeiro login, e as mesmas roles/grupos/
  atributos do usuário original (mesmos critérios já validados na tarefa original).
- Um item problemático da lista vira dúvida bloqueante referenciando esse item específico, sem
  impedir o processamento dos demais itens da mesma execução.
- O modo de execução único via `--env` (`usuarioOrigem`/`novoUsername`/`novaSenha`) continua
  funcionando sem alteração de comportamento.
- Autoteste cobre pelo menos: fixture com 2+ usuários, incluindo um caso de sucesso e um caso que
  deveria gerar dúvida (ex. usuário de origem inexistente), confirmando que o caso de sucesso é
  processado mesmo com o outro item falhando.
- `README.md`/`CLAUDE.md` do repositório atualizados documentando o novo modo em lote, seguindo o
  padrão de documentação já usado para o modo de execução única.

## Material de apoio

- Tarefa original (já concluída): `../concluidas/20260914115110-clonar-usuario-keycloak-prod-hml.md`
  — reaproveitar toda a lógica de clonagem já implementada por ela, não reimplementar.
- Mecanismo de senha temporária/forçar troca: endpoint de criação/reset de credencial do Keycloak
  aceita a credencial com `temporary: true` — usar o padrão nativo do Keycloak para isso, não
  implementar verificação de troca de senha na aplicação.
