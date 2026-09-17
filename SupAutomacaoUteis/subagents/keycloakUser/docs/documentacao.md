# Conhecimento acumulado do módulo keycloakUser

> Histórico completo (narrativa de cada tarefa, autotestes rodados, bugs corrigidos) arquivado em
> `documentacao-historico.md` — aqui fica só o que ainda é operacionalmente relevante.

## Escopo deste módulo

Automações relacionadas a gestão de usuários no Keycloak do projeto (realm `multiplicacapital`):
clonagem de usuário de PROD para HML com novo username/senha, e futuras automações relacionadas a
usuários/identidade que forem surgindo. Reaproveita a infraestrutura já existente no repositório
para autenticação (`cy.definirAmbiente`, `cy.obterToken`, ambientes `keycloak`/`keycloakProd`) e
para localizar grupos/roles por nome exato (`cypress/support/shared/keycloakHelpers.js`,
`encontrarPorNomeExato`) — não reimplementar essas partes, só reaproveitar.

Diferente do domínio "Grupos e Permissões" já existente no repo (que sincroniza grupos/roles em
si, sem criar usuários), este módulo lida com usuários individuais e é sempre uma ação sob demanda
(não uma sincronização automática recorrente).

## Estado atual (implementado)

- **Modo único**: `cy.clonarUsuarioKeycloak({ usuarioOrigem, novoUsername, novaSenha })`
  (`repo/cypress/support/commands/usuariosKeycloak.js`), feature/step `@keycloakUsuario`
  (`gerenciamentoDeUsuarios.feature`/`.js`). Exemplo de invocação:
  ```
  cypress run --env tags=@keycloakUsuario,usuarioOrigem=fulano,novoUsername=fulano.hml,novaSenha=SenhaForte123!
  ```
  (o `tags=@keycloakUsuario` é obrigatório para rodar só esse cenário isoladamente).
- **Modo em lote**: `cy.clonarUsuariosKeycloakEmLote(mapaUsuarios)`, feature/step
  `@clonarUsuariosEmLote`, fixture `repo/cypress/fixtures/usuariosParaClonar.json` (mapa
  `usuarioProd: usuarioHml`, commitado sempre como template vazio `{}` — nunca populado com
  usuário real de PROD pela automação; decidir "qual usuário copiar" é sempre decisão do Thiago).
- Lógica pura compartilhada pelos dois modos: `repo/cypress/support/shared/clonagemUsuarioKeycloak.js`
  (coberta por `node:test`, `__tests__/clonagemUsuarioKeycloak.test.js`), com o núcleo interno
  `executarClonagem` (`usuariosKeycloak.js`) devolvendo `{ ok, motivo?, valor? }` — modo único
  converte `ok: false` em `throw`, modo lote não lança e cada item vira um resultado na lista.
  Mapeamento auxiliar em `repo/cypress/utils/mapeamentoUsuarios.js`.

## Decisões e comportamentos vigentes

- **Nunca cria role/grupo faltante em HML** (diferente do domínio Grupos e Permissões) — lança
  erro/dúvida bloqueante. Mesmo tratamento para usuário de origem não encontrado em PROD e
  conflito de username em HML.
- **Email nunca é copiado** do usuário de origem — gerado por `gerarEmailInvalidoUnico(novoUsername)`
  no padrão `{novoUsername}.{sufixo-8-hex}@invalido.multiplica.local` (`crypto.randomUUID()`,
  global, sem import). Evita conflito de criação por email já existente em HML.
- **Username sempre normalizado para minúsculas** via `normalizarUsername(username)`, aplicado no
  choke point `executarClonagem` (único ponto por onde os dois modos passam) — decisão de design:
  normalizar só ali, não em cada helper individual, para não duplicar a normalização em múltiplos
  call sites.
- **Senha temporária fixa `Automacao@123`** (`temporary: true`, força troca no primeiro login) para
  todo usuário criado pelo modo em lote — nunca senha aleatória nem pedida por item.
- **Fixture de lote "consome" usuários clonados com sucesso**: ao final do processamento, se houve
  pelo menos 1 sucesso, `cy.clonarUsuariosKeycloakEmLote` reescreve a fixture sem essas entradas
  (via `cy.writeFile`); sem nenhum sucesso, não escreve nada. Fixture vazia deixou de ser erro —
  só loga e retorna lista vazia.
- **Parâmetros ausentes no modo único** (ex.: rodar a suíte completa sem `tags=@keycloakUsuario`)
  não quebram mais a execução — loga `MENSAGEM_PARAMETROS_CLONAGEM_UNICA_AUSENTES` e pula a
  clonagem (flag de módulo `clonagemUnicaPulada` sinaliza o `Then` a não assertar).
- API de usuários do Keycloak suporta busca exata nativamente (`?username=...&exact=true`,
  `?email=...&exact=true`) — diferente de grupos/roles (`?search=` parcial + `encontrarPorNomeExato`).
- `GET /users/{id}/role-mappings` já devolve `realmMappings` + `clientMappings` agrupados por
  client — não precisa iterar client por client.
- Usuários de aplicação (`prod`/`hml`, login via client `autenticacao`) vivem no mesmo realm
  `multiplicacapital` usado pelos clients de automação (`keycloak`/`keycloakProd`).
- **Gotcha Cypress (Promise nativa vs `cy.` commands, e comando `cy.` solto dentro de `.then()`
  terminando em valor síncrono)**: já corrigido nos dois modos; detalhe completo e aplicável a
  qualquer módulo em `../../docs/conhecimento-geral.md` (e narrativa original em
  `documentacao-historico.md`).

## Validação end-to-end

A automação nunca escolhe um usuário real de PROD para testar o caminho de sucesso completo —
sempre usa um `usuarioOrigem` fictício inexistente em PROD para validar as dúvidas bloqueantes.
Confirmar o caminho de sucesso real (criação de fato em HML) fica sempre para o teste manual do
Thiago.
