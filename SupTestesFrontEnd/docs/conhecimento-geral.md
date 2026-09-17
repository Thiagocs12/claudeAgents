# Conhecimento geral do sistema (leitura obrigatória para todo agente)

Este arquivo reúne aprendizados e convenções que atravessam módulos — todo subAgent deve ler este
arquivo INTEIRO antes de iniciar qualquer ciclo, além do `docs/documentacao.md` do próprio módulo.
Se você (agente) aprender algo que outro módulo também precisaria saber, registre aqui — não só no
seu `docs/documentacao.md` local.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização, para não
perder uma edição feita por outro agente rodando em paralelo (não há lock automático entre
ciclos).

## O que é diferente aqui (vs. SupE2eAutomation / SupAutomacaoUteis)

- Sem `repo/`, sem `agent-master/`, sem branch de integração. Cada subAgent bootstrap um projeto
  Cypress mínimo na própria pasta (`npm init` + `npm install cypress`) só como ferramenta de
  execução — não é uma suíte que persiste/cresce entre tarefas.
- Toda execução gera um vídeo (`videos/<id>.mp4`) e uma narrativa passo a passo dentro do próprio
  arquivo de tarefa (seção `## Execução`), não só um veredito final.
- Toda tarefa concluída fica em `tarefas/aguardando-aprovacao/` até o Thiago decidir — nunca vai
  direto para `concluidas/`. Só depois de aprovado é que vira uma tarefa nova no
  `SupE2eAutomation` (ver `CLAUDE.md`, seção 3.5) — hand-off nunca é automático.

## Aplicação testada e ambientes

Mesma aplicação (Beyond Banking / Multiplica) que o `SupE2eAutomation` automatiza — reaproveitar
o que já está mapeado lá quando fizer sentido (ex.: fluxo de login via Keycloak). Ambiente
principal: HML.

## Credenciais / `.env`

Se precisar de credenciais de login (HML), verificar primeiro se dá para reaproveitar as mesmas
já usadas pelo `SupE2eAutomation` (ver `.env` em
`C:\Multiplica\claudeAgents\SupE2eAutomation\agent-master\repo\.env` ou na pasta de teste manual
`C:\multiplica\cypress-e2e\.env`) em vez de pedir credenciais novas ao Thiago — mas nunca copiar
esse arquivo automaticamente sem confirmar com o Supervisor primeiro (aplicação diferente de
contexto — o subAgent aqui não tem repositório próprio para guardar um `.env`, então isso deve
ficar documentado como pendência/dúvida na primeira vez que um módulo precisar disso, não
resolvido sozinho).

## Contas de Claude Code por agente

Ver `CONHECIMENTO-SUPERVISORES.md` (raiz de `C:\Multiplica\claudeAgents`) para o registro
completo. Resumo (mudou em 2026-09-17, pedido explícito do Thiago): `contaB` é a conta padrão de
tudo (sessão interativa deste Supervisor, todo subAgent, Status Watcher) — `contaB` é a conta
pessoal dele. `contaA` só entra como fallback de rate-limit.

## Armadilha: `npx cypress run` sem timeout explícito vira processo órfão (2026-09-15)

Ver `subagents/mop/docs/documentacao.md` (seção de mesmo nome) e
`CONHECIMENTO-SUPERVISORES.md` para o detalhe completo. Resumo: todo `AGENTE.md` de módulo desta
pasta deve instruir a sempre passar `timeout: 300000`+ ao chamar `npx cypress run` via Bash, nunca
usar `ScheduleWakeup`/esperar processo em background, e todo `run-cycle.ps1` novo deve reaplicar a
função `Stop-ProcessosCypressOrfaos` (referência: `subagents/mop/run-cycle.ps1`) que mata, no
início e no fim do ciclo, qualquer processo Cypress/node remanescente daquela pasta.

## Armadilha: `cy.intercept()` não funciona dentro do callback do `cy.origin()` (2026-09-15)

Descoberto no módulo `mop`, mas vale pra qualquer módulo que use `cy.origin()` (fluxos com
subdomínios/origens distintas). Registrar um `cy.intercept(...)` **de dentro** do callback passado
a `cy.origin(...)` falha com `CypressError: cy.intercept() use is not supported in the cy.origin()
callback`. Solução: registrar o(s) `cy.intercept()` no escopo top-level do teste, **antes** de
qualquer `cy.origin()` — continua válido e captura requisições feitas depois, dentro das origens
visitadas via `cy.origin()` (não precisa re-registrar por origem). Pra ler o que foi capturado
depois de um bloco `cy.origin()`, não dá pra referenciar a variável externa de dentro do callback
(contexto serializado/isolado) — escreva o resultado só depois que o `cy.origin()` retornar, no
escopo top-level. Ver `subagents/mop/docs/documentacao.md` para o detalhe completo.

## Armadilha: ids `mui-NN` (React `useId()`) não são estáveis entre execuções (2026-09-16)

Descoberto no módulo `mop`, mas vale pra qualquer módulo cujo app use Material UI (MUI): quando um
input não tem `name`/`placeholder`/`aria-label` nativo e só um `<label for="mui-XX">` flutuante, o
número `XX` é gerado pelo React (`useId()`) e depende de quantos outros componentes com id
auto-gerado já montaram antes na mesma execução — **muda de rodada pra rodada**, não é estável.
Hardcodar `#mui-29` funciona por coincidência em algumas execuções e quebra em outras. Solução:
sempre resolver o id dinamicamente a partir do texto do label associado
(`cy.contains('label', 'TEXTO').invoke('attr', 'for').then((id) => cy.get('#' + id)...)`), nunca
hardcodar o id. Ver `subagents/mop/docs/documentacao.md` para o caso completo.

## Armadilha: hostname do Keycloak pode variar entre execuções — detectar por path, não por host (2026-09-16)

Descoberto no módulo `mop`, mas vale pra qualquer módulo que detecte "caiu no Keycloak?" comparando
a URL contra um hostname fixo (`Cypress.env('HML_KEYCLOAK_URL')` ou similar). Numa execução real, o
login de uma das aplicações foi servido por um host Keycloak **diferente** do esperado (mesmo
padrão de URL, `/auth/realms/.../protocol/openid-connect/auth`, hostname trocado) — a comparação
por hostname fixo não reconheceu o host novo e pulou o login inteiro. **Solução:** detectar
Keycloak pelo padrão do **path** da URL (`new URL(url).pathname.includes('/auth/realms/')`), não
por hostname fixo, e usar a origin de fato observada (`new URL(url).origin`) no `cy.origin()` em
vez de um valor fixo de `.env`. Ver `subagents/mop/docs/documentacao.md` para o caso completo
(inclusive um erro `Parâmetro inválido: redirect_uri` visto num desses hosts alternativos, ainda
não confirmado como bug real reproduzível ou só um estado transitório).

## Padrão: validação em banco de dados (somente leitura) a partir de um subAgent (2026-09-16)

Descoberto no módulo `mop`, mas vale pra qualquer módulo deste Supervisor que precise confirmar em
banco o estado real de algo testado (não confiar só em toast/UI). Reaproveitar o padrão de conexão
já validado em `SupAutomacaoUteis/subagents/cedente/repo/cypress/support/db/dbClient.cjs`
(`mssql/msnodesqlv8`, `trustedConnection: true` — usa a identidade Windows do processo, não precisa
de usuário/senha nas config). Passos: `npm install mssql msnodesqlv8` no módulo, copiar do `.env` do
módulo doador as variáveis de host/nome do banco/porta relevantes (nunca os valores de
usuário/senha, que nem são usados por `trustedConnection`), e escrever um script Node avulso
(fora da spec Cypress descartável) que primeiro consulta `INFORMATION_SCHEMA.TABLES`/`COLUMNS` pra
confirmar o nome real da tabela antes de assumir um nome — nomes de tabela citados numa tarefa
podem não bater exatamente com o schema real. Ver `subagents/mop/docs/documentacao.md` para o caso
completo (tabelas `MC_MOP_PRE_OPERACAO`/`MC_MOP_OPERACAO`).

## Scheduled Tasks (Windows Task Scheduler)

- `SupTestesFrontEnd-SubAgent-<modulo>`: a cada 5 minutos.
- `SupTestesFrontEnd-StatusWatcher`: a cada 15 minutos.
- Sem Agent Master — não existe uma 3ª task de integração aqui.
- Mesmos padrões de infraestrutura dos outros dois Supervisores (prompt via stdin, log em
  `stream-json`, pré-checagem em PowerShell antes de chamar `claude -p`) — ver
  `CONHECIMENTO-SUPERVISORES.md` para o detalhe e o código de referência em qualquer
  `run-cycle.ps1` já existente.
