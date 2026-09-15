# Conhecimento acumulado do módulo keycloakUser

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

## Tarefa concluída: clonar usuário Keycloak PROD→HML (2026-09-14)

Implementado `cy.clonarUsuarioKeycloak({ usuarioOrigem, novoUsername, novaSenha })`
(`repo/cypress/support/commands/usuariosKeycloak.js`), lógica pura em
`repo/cypress/support/shared/clonagemUsuarioKeycloak.js` (coberta por `node:test`,
`repo/cypress/support/shared/__tests__/clonagemUsuarioKeycloak.test.js`), mapeamento em
`repo/cypress/utils/mapeamentoUsuarios.js`, feature/step `@keycloakUsuario`
(`gerenciamentoDeUsuarios.feature`/`.js`). Parametrizado a cada execução via
`cypress run --env usuarioOrigem=...,novoUsername=...,novaSenha=...`. `README.md`/`CLAUDE.md` do
repo atualizados (seção "Clonagem de Usuário (Keycloak)" em `CLAUDE.md`).

**Exemplo completo de invocação (cenário `@keycloakUsuario`, confirmado pelo Thiago em
2026-09-14):**
```
cypress run --env tags=@keycloakUsuario,usuarioOrigem=fulano,novoUsername=fulano.hml,novaSenha=SenhaForte123!
```
O `tags=@keycloakUsuario` é necessário pra rodar só esse cenário Cucumber isoladamente (padrão de
tag do projeto) — sem ele o Cypress roda todos os cenários. `usuarioOrigem`, `novoUsername` e
`novaSenha` seguem o mesmo padrão já documentado acima.

Decisões/aprendizados específicos deste módulo:
- A API de usuários do Keycloak suporta busca por nome exato nativamente
  (`?username=...&exact=true`, `?email=...&exact=true`) — diferente de grupos/roles
  (`?search=` parcial, precisa filtrar depois com `encontrarPorNomeExato`).
- `GET /users/{id}/role-mappings` já devolve `realmMappings` + `clientMappings` agrupados
  por client (todos os clients em que o usuário tem role, não só `KEYCLOAK_CLIENT_ID`) —
  não precisa iterar client por client como seria de se esperar.
- Confirmado por leitura de `ambiente.js` (não foi preciso perguntar): usuários de
  aplicação (`prod`/`hml`, login via client `autenticacao`) vivem no mesmo realm
  `multiplicacapital` usado pelos clients de automação (`keycloak`/`keycloakProd`) — os
  `urlToken` de `prod`/`hml` já apontam para `auth/realms/multiplicacapital/...`.
- Diferente de Grupos e Permissões (que cria role/grupo faltante), clonagem de usuário
  **nunca** cria role/grupo faltante em HML — só lança erro descritivo (é sempre rodado
  sob demanda por um humano, o erro já cumpre o papel de "dúvida bloqueante"). Mesmo
  tratamento para: usuário de origem não encontrado em PROD, e novo username/email já
  existente em HML.
- **Autoteste rodado**: `npm run lint` (0 erros) e `npm run test:safety` (27/27, incluindo
  as 10 novas para este recurso) — cobrem a lógica pura completa (payload de criação,
  extração de realm role + client role + grupo do usuário de origem). Não rodei o cenário
  `@keycloakUsuario` fim a fim contra o Keycloak real de PROD/HML: exigiria escolher um
  `usuarioOrigem` real de produção para testar, e a regra do módulo é nunca decidir sozinho
  qual usuário copiar — a validação fim a fim fica para o teste manual do Thiago (mesmo padrão de
  revisão humana de toda mudança integrada na `reviewAgents` deste projeto).

## Tarefa concluída: clonagem em lote de usuários Keycloak PROD→HML (2026-09-14)

Extensão da tarefa acima (`20260914174624-clonar-usuarios-em-lote.md`), complementando o modo de
execução única (mantido sem alteração de comportamento) com um modo em lote — sem duplicar a
lógica de clonagem, os dois modos compartilham a mesma checagem/clonagem interna:

- `cy.clonarUsuariosKeycloakEmLote(mapaUsuarios)` (`repo/cypress/support/commands/usuariosKeycloak.js`),
  feature/step `@clonarUsuariosEmLote` (`gerenciamentoDeUsuarios.feature`/`.js`), fixture
  `repo/cypress/fixtures/usuariosParaClonar.json` (mapa `usuarioProd: usuarioHml`, versionado como
  template vazio `{}` — nunca populado com usuário real de PROD por mim; decidir "qual usuário
  copiar" continua sendo uma decisão do Thiago, nunca da automação).
- Todo usuário criado pelo lote recebe senha temporária fixa `Automacao@123` com `temporary: true`
  (força troca no primeiro login, mecanismo nativo do Keycloak) — nunca senha aleatória nem pedida
  por item.
- Refatorei o núcleo interno de `usuariosKeycloak.js` (`resolverRolesRealmEmHml`,
  `resolverRolesClienteEmHml`, `resolverGruposEmHml`, e um novo `executarClonagem` que substitui a
  lógica antes embutida direto em `cy.clonarUsuarioKeycloak`) para devolver `{ ok, motivo?, valor? }`
  em vez de lançar erro diretamente nos casos de "dúvida bloqueante" (usuário de origem não
  encontrado, role/grupo sem correspondente em HML, conflito de username/email). O modo único
  (`cy.clonarUsuarioKeycloak`) converte `ok: false` em `throw`, preservando o comportamento
  original; o modo em lote não lança — cada item vira um resultado na lista final e o
  processamento segue para o próximo. A orquestração do lote em si
  (`clonarUsuariosEmLote`, em `repo/cypress/support/shared/clonagemUsuarioKeycloak.js`) é pura
  (recebe a função de clonagem por injeção), coberta por `node:test` sem depender do Cypress.
- **Por que não dava para usar `try/catch`/`.catch()` em volta do comando de clonagem de cada
  item**: Cypress não permite. Uma vez que um comando lança erro dentro de uma cadeia de comandos,
  a fila de comandos do teste é interrompida (mesmo com `cy.once('fail', ...)`, que só suprime a
  falha do teste, não permite retomar comandos seguintes na mesma cadeia) — "continuar após uma
  falha esperada" só funciona se o próprio código nunca lançar erro para os casos que devem
  permitir continuação. Daí o formato `{ ok, motivo?, valor? }` em vez de exceção.
- **Armadilha real encontrada ao rodar o cenário em lote de verdade contra o Keycloak** (ver
  `../../docs/conhecimento-geral.md` — vale para qualquer módulo que fizer algo parecido):
  1. Nunca misture uma `Promise` nativa com comandos `cy.` invocados de dentro dela — o Cypress
     detecta e falha explicitamente ("Cypress detected that you returned a promise from a command
     while also invoking one or more cy commands in that promise"). Minha primeira tentativa de
     `clonarUsuariosEmLote` usava `Promise.resolve(clonarUmUsuario(...))` internamente — funcionava
     no `node:test` (Promise nativa pura) mas quebrava no Cypress real, porque lá `clonarUmUsuario`
     devolve um `Cypress.Chainable`, não uma Promise nativa. Corrigido recebendo o acumulador
     inicial (`valorInicial`) como parâmetro — no Cypress passa-se `cy.wrap([], { log: false })`,
     mantendo toda a cadeia dentro do sistema de comandos do Cypress; nos testes, o padrão
     `Promise.resolve([])` continua funcionando porque lá `clonarUmUsuario` só devolve Promises
     nativas.
  2. Nunca invoque um comando `cy.` (ex.: `cy.logExecucao(...)`) dentro de um `.then()` sem
     retornar/encadear esse comando, se o `.then()` também for terminar retornando um valor
     síncrono — o Cypress falha com "you invoked 1 or more cy commands but then returned a
     synchronous value". Encontrei esse mesmo padrão quebrado também no comando de execução única
     original (`cy.logExecucao(...)` solto seguido de `return criado`) — bug pré-existente da
     tarefa anterior, nunca pego porque o cenário `@keycloakUsuario` nunca tinha sido executado de
     verdade contra o Keycloak real (só a lógica pura tinha autoteste). Corrigi nos dois modos:
     `return cy.logExecucao(...).then(() => valor)`.
  3. Numa clonagem em ambiente novo, `cypress/temp/tokens.json` (gitignored) ainda não existe na
     primeira execução — isso por si só não quebra nada (`cy.readFile`/`.then(sucesso, erro)` em
     `ambiente.js`/`utils.js` tentam tratar `ENOENT`, mas essa forma de dois argumentos no
     `cy.then()` não existe na API do Cypress — o segundo argumento é ignorado silenciosamente, e
     um arquivo ausente vira uma falha "dura" do comando via retry/timeout, não uma rejeição que
     esse `.then()` consiga capturar). **Não mexi nisso** (arquivo compartilhado por todos os
     domínios do projeto, fora do escopo desta tarefa) — só contornei localmente criando o arquivo
     vazio (`{}`) antes de rodar, para poder validar meu próprio recurso. Registrado em
     `../../docs/conhecimento-geral.md` para quem for mexer em `ambiente.js`/`utils.js` — a
     correção real preferida seria via `cy.task` (checar existência no Node, sem depender do
     `readFile` "assertivo" do Cypress para arquivo opcional).
- **Autoteste rodado para o modo em lote**: `npm run lint` (0 erros), `npm run test:safety`
  (31/31, incluindo os 2 novos cobrindo `clonarUsuariosEmLote`: sucesso de um item mesmo com outro
  falhando, e mapa vazio) — **e desta vez também rodei o cenário fim a fim contra o Keycloak real**
  (`npx cypress run --env tags=@clonarUsuariosEmLote`), usando um fixture temporário (nunca
  commitado) com um único item cujo `usuarioProd` claramente não existe em PROD
  (`usuario-inexistente-teste-autoteste-agente`) — só GETs, nada escrito em lugar nenhum, nenhum
  usuário real de PROD envolvido. Passou: resultado agregado `0/1 sucesso, 1 dúvida bloqueante`,
  motivo correto. Também revalidei o modo único com o mesmo usuário fictício
  (`npx cypress run --env tags=@keycloakUsuario,usuarioOrigem=...,novoUsername=...,novaSenha=...`)
  — falhou como esperado, com a mesma mensagem de erro, confirmando que a refatoração não mudou o
  comportamento do modo único. Fixture commitado ficou de volta como template vazio (`{}`).

## Correção: nunca copiar email do usuário original (2026-09-14)

Tarefa `20260914180911-nao-copiar-email-usar-invalido-unico`: copiar o email do usuário de origem
para o novo usuário em HML causava conflito de criação sempre que o mesmo email já existisse em
HML (era uma das "dúvidas bloqueantes" das duas tarefas acima). Corrigido nos dois modos (único e
em lote), aplicado diretamente na branch `keycloakUser/clonar-usuarios-em-lote` (ainda não mergeada
na `reviewAgents` quando esta tarefa foi pega — por já conter o modo único refatorado, corrigir ali
resolve os dois modos de uma vez, em vez de duas branches/correções separadas).

- Nova função pura `gerarEmailInvalidoUnico(novoUsername)`
  (`cypress/support/shared/clonagemUsuarioKeycloak.js`): `{novoUsername}.{sufixo}@invalido.multiplica.local`,
  sufixo de 8 hex chars via `crypto.randomUUID()` (global, disponível tanto em Node quanto no
  browser do Cypress — não precisou de import). `montarPayloadNovoUsuario` passou a chamar essa
  função em vez de copiar `usuarioOrigem.email`.
- Removida a checagem de conflito de email em HML (`buscarUsuarioKeycloakPorEmail` e o bloco
  `verificarEmail`/`conflitoEmail` em `executarClonagem`, `usuariosKeycloak.js`) — deixou de fazer
  sentido, já que o email nunca mais vem do usuário original, não tem mais como colidir. O comando
  `buscarUsuarioKeycloakPorEmail` foi removido inteiramente (não tinha mais nenhum uso).
- `README.md`/`CLAUDE.md` do repo atualizados (seção "Clonagem de Usuário (Keycloak)" do
  `CLAUDE.md`, bullet do domínio Usuários no `README.md`) refletindo que email não é mais copiado.
- **Autoteste**: `npm run lint` (0 erros), `npm run test:safety` (34/34, incluindo os 3 novos —
  `gerarEmailInvalidoUnico` nunca repete/nunca é o email de origem, `montarPayloadNovoUsuario`
  nunca copia o email de origem e gera emails diferentes em chamadas seguidas). Rodei de novo os
  dois cenários fim a fim contra o Keycloak real (mesmo usuário fictício inexistente em PROD dos
  autotestes anteriores) — comportamento inalterado nesse caminho (falha antes de chegar a gerar
  email, por causa da checagem de usuário de origem/username). Não testei o caminho de sucesso
  (criação real com o email novo) fim a fim, pelo mesmo motivo de sempre: exigiria escolher um
  usuário real de PROD, decisão que não é da automação.

## Correção: normalizar username para minúsculas em toda a clonagem (2026-09-15)

Tarefa `20260915100931-normalizar-case-usuario-minusculas`, branch
`keycloakUser/normalizar-case-usuario-minusculas` (aguardando merge do Agent Master na
`reviewAgents`). Bug relatado pelo Thiago: usuário informado com maiúscula (ex.:
`formalizacao.Automacao`) fazia o `expect` do cenário `@keycloakUsuario` falhar, porque o
Keycloak sempre grava/retorna o username já normalizado para minúsculas
(`formalizacao.automacao`) — o teste comparava o valor original (com maiúscula) contra o
valor retornado (minúsculo), uma divergência de case, não de dado real.

- Nova função pura `normalizarUsername(username)` em `clonagemUsuarioKeycloak.js`
  (`(username ?? '').toLowerCase()`), coberta por `node:test` com o cenário exato do bug
  relatado (`formalizacao.Automacao` → `formalizacao.automacao`) e casos de entrada
  vazia/ausente.
- Aplicada em três pontos, cobrindo os dois modos (único e em lote) de uma vez, já que ambos
  compartilham a mesma lógica interna (`executarClonagem`):
  1. `montarPayloadNovoUsuario` — normaliza o `username` do payload de criação, e também o
     valor passado para `gerarEmailInvalidoUnico` (email gerado a partir do username já
     normalizado, por consistência — não afeta a estrutura do email, só o prefixo).
  2. `executarClonagem` (`usuariosKeycloak.js`) — `usuarioOrigem`/`novoUsername` normalizados
     logo na entrada da função (únicas variáveis usadas daí em diante: busca de origem em
     PROD, busca de conflito de username em HML, mensagens de dúvida bloqueante, e o valor
     passado para `criarUsuarioEAtribuir`).
  3. Step definition (`gerenciamentoDeUsuarios.js`) — o `expect(usuarioClonado.username)`
     agora compara contra `normalizarUsername(Cypress.env('novoUsername'))` em vez do valor
     bruto vindo do `--env`.
- **Decisão de design**: normalizar no ponto de entrada de `executarClonagem` (em vez de
  normalizar dentro de cada comando/helper que usa username, ex. `buscarUsuarioKeycloakPorUsername`)
  porque esse é o único choke point por onde os dois modos (único e em lote) já passam — evita
  duplicar a normalização em múltiplos call sites sem ganhar robustez adicional (todos os
  chamadores internos desses helpers já passam pelo `executarClonagem` primeiro).
- **Autoteste**: `npm run lint` (0 erros), `npm run test:safety` (38/38, 4 novos). Rodei de novo
  o cenário `@keycloakUsuario` contra o Keycloak real com o mesmo usuário de origem fictício
  (inexistente em PROD) dos autotestes anteriores deste módulo, agora com um `novoUsername` em
  case misto (`Teste.Case.NORMALIZACAO`) — passou (falha esperada antes de chegar a criar
  qualquer coisa, sem crash na refatoração). Não testei o caminho de sucesso completo (criação
  real confirmando que o username fica salvo/comparado em minúsculas) pelo mesmo motivo de
  sempre: exigiria escolher um `usuarioOrigem` real de PROD, decisão que não é da automação — a
  normalização em si já está coberta de forma direta e determinística pelo `node:test`.

## Correção: fixture de lote "consome" usuários clonados; fixture vazia deixa de ser erro (2026-09-15)

Tarefa `20260915111027-remover-clonados-fixture-lote-e-fixture-vazia-nao-quebra`, branch
`keycloakUser/remover-clonados-fixture-lote-e-fixture-vazia-nao-quebra` (aguardando merge do Agent
Master na `reviewAgents`). Pedido do Thiago: rodar o cenário `@clonarUsuariosEmLote` repetidamente
tentava reclonar os mesmos usuários já clonados numa execução anterior, e a fixture vazia (estado
normal depois de consumida) lançava erro em vez de simplesmente não fazer nada.

- Nova função pura `removerUsuariosClonadosComSucesso(mapaUsuarios, resultados)`
  (`clonagemUsuarioKeycloak.js`): recebe o mapa original `usuarioProd: usuarioHml` e a lista de
  resultados de `clonarUsuariosEmLote`, devolve um novo mapa sem as entradas cujo `usuarioProd`
  teve `ok: true`. Coberta por `node:test` (remoção parcial, nenhuma remoção quando tudo falhou,
  remoção total quando tudo teve sucesso, mapa/resultados vazios/ausentes).
- `cy.clonarUsuariosKeycloakEmLote` (`usuariosKeycloak.js`), ao final do processamento: se houve
  pelo menos 1 sucesso, grava de volta em `cypress/fixtures/usuariosParaClonar.json` (via
  `cy.writeFile`, mesmo padrão já usado no repo — ver `commands/estoque.js`/`arquivos.js`) o mapa
  já sem os clonados com sucesso; se não houve nenhum sucesso, não escreve nada (evita I/O
  desnecessário e mantém a fixture bit-a-bit igual quando nada mudou).
- **Fixture vazia deixou de ser erro**: `cy.clonarUsuariosKeycloakEmLote` lançava
  `Error('Fixture de usuários para clonar em lote está vazia...')` quando o mapa vinha vazio — era
  um guard-rail intencional da tarefa anterior (documentado acima, seção "clonagem em lote"). Com
  a remoção automática, esvaziar a fixture passou a ser o resultado esperado de um lote
  bem-sucedido, não uma configuração incompleta — trocado por `cy.logExecucao(...)` + retorno de
  lista vazia. O step `Then` do cenário (`gerenciamentoDeUsuarios.js`) também foi ajustado: antes
  assertava `resultadosLote.length > 0` (falharia com lista vazia), agora trata lista vazia como
  sucesso do cenário (loga e retorna, sem assertar mais nada).
- Modo único (`cy.clonarUsuarioKeycloak`, `@keycloakUsuario`) não foi tocado — comportamento
  inalterado, reconfirmado no autoteste.
- **Autoteste rodado**: `npm run lint` (0 erros), `npm run test:safety` (42/42, 4 novos). Rodei o
  cenário `@clonarUsuariosEmLote` fim a fim contra o Keycloak real em dois casos: (1) fixture já
  vazia (`{}`, estado commitado) — passou, log informativo confirmado, fixture permaneceu `{}`;
  (2) fixture com um único usuário fictício inexistente em PROD (mesmo padrão de autotestes
  anteriores deste módulo) — passou (0/1 sucesso, dúvida bloqueante), fixture permaneceu
  inalterada ao final (confirma que só sucesso aciona a escrita). Reconfirmei também o modo único
  com o mesmo usuário fictício — falhou como esperado, comportamento inalterado. **Não testei e2e
  o caminho de sucesso completo** (remoção real da fixture após clonagem bem-sucedida) pelo mesmo
  motivo de sempre neste módulo: exigiria escolher um usuário real de PROD, decisão que não é da
  automação — a remoção em si está coberta de forma direta e determinística pelo `node:test`.
  Fixture commitada permanece como template vazio (`{}`).
