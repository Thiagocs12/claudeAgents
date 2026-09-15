# Conhecimento acumulado do módulo mop (Sup TestesFrontEnd)

## Ponto de partida: conhecimento já mapeado pelo SupE2eAutomation

Ver `C:\Multiplica\claudeAgents\SupE2eAutomation\subagents\mop\docs\documentacao.md` (outro
Supervisor, mesma aplicação/módulo) para o que já está resolvido:
- Login (`cy.loginComoPerfil` / fluxo Keycloak) funcionando para o perfil `master` em HML.
- Navegação: Home logada → "Beyond BackOffice" (accordion) → "Comercial" → dashboard com cards
  "Operação Diária", "Operação Estruturada", "Operação Cessão", "Garantia".
- Bug do widget de menu (`mc-menu.js`) — já contornado aqui em `cypress/support/e2e.js`.
- Seletores do Monitor Diário (menu lateral por ícone/tooltip, tabela de resultados, inputs de
  data controlados por React que exigem o setter nativo, não jQuery `.val()`).

Isso cobre **login e navegação até o dashboard Comercial** — mas só dentro do **Beyond
BackOffice**. A **criação** de operação acontece em outro sistema (ver abaixo).

## Dois sistemas distintos (correção do Thiago, 2026-09-15)

Este módulo mexe com **dois sistemas diferentes**, não duas telas do mesmo app:

- **Beyond Banking** (`https://beyondbanking-hml.grupomultiplica.com.br/`) — onde a operação é
  **criada**: seleção de cedente, "Beyond Operação" → "Criar Operação", navegação até o serviço
  (ex. Aquisição → Antecipação de Duplicata → Duplicata → Serviço → Boleto), inclusão por
  digitação, Cad Pessoa (consulta de CPF pra usar como sacado), preenchimento e geração da
  operação, e o dashboard de Operações onde ela é avançada. **Território novo, nada mapeado ainda
  aqui.**
- **Beyond / Beyond BackOffice** (`beyond-hml.grupomultiplica.com.br`, confirmado pelo Thiago em
  2026-09-15) — onde se **verifica** o resultado: Monitor Diário, histórico da operação, etapa
  "Inclusão OPE". É o que o `SupE2eAutomation` já mapeou (login, navegação, seletores da tabela).
- Login (Keycloak, perfil `master`) é o mesmo mecanismo nos dois, segundo o Thiago — mas confirmar
  na prática antes de assumir que credenciais/sessão viajam entre os dois hosts sem novo login.

## Ambiente

HML nos dois sistemas. Credenciais em `.env` desta pasta (copiado do `.env` do
`SupE2eAutomation`, mesmas credenciais — nunca exibir/versionar o conteúdo). Esse `.env` tem URLs
do Beyond BackOffice/API/Keycloak já usadas pelo outro Supervisor — **não necessariamente cobre o
Beyond Banking**, que é sistema novo pra qualquer um dos dois Supervisores; se faltar alguma URL
de ambiente/config, registrar como aprendizado aqui assim que descoberta.

## Armadilha: `npx cypress run` sem timeout explícito pode ficar órfão (2026-09-15)

Num ciclo real, o subAgent chamou `npx cypress run` via Bash sem passar um `timeout` explícito;
o comando estourou o timeout implícito do Bash, foi movido pra background pela ferramenta, e o
subAgent tentou "esperar terminar depois" (chegou a chamar `ScheduleWakeup`, que não se aplica a
um ciclo `claude -p` de execução única — não existe próximo turno pra um wakeup disparar) e
encerrou o ciclo com o processo Cypress/Electron/node ainda rodando. Ficaram processos órfãos
vivos por mais de 2h até serem encontrados e encerrados manualmente pelo Supervisor.

- **Correção na regra (`AGENTE.md`, regra 5):** sempre passar `timeout: 300000` (5 min) ou mais ao
  chamar `npx cypress run` via Bash; nunca usar `ScheduleWakeup` neste contexto; nunca encerrar o
  ciclo com um processo Cypress/node ainda vivo.
- **Rede de segurança determinística (`run-cycle.ps1`):** no início e no fim de todo ciclo, mata
  qualquer processo cuja `CommandLine` referencie esta pasta e contenha "cypress" (raiz) mais toda
  a árvore de processos filhos (Electron/Cypress) — independe do LLM se comportar corretamente.
  Ver também `CONHECIMENTO-SUPERVISORES.md` (relevante pros outros dois Supervisores, que também
  chamam Cypress via ciclos `claude -p`).

URL do Beyond Banking (HML) adicionada ao `.env` local como `HML_BEYOND_BANKING_URL` (não
versionado, `.env` está no `.gitignore`).

## Login no Beyond Banking (mapeado em 2026-09-15)

`https://beyondbanking-hml.grupomultiplica.com.br/` redireciona para um Keycloak com **realm
próprio** (`beyondbanking-hml`, diferente do realm usado pelo Beyond BackOffice) e uma tela de
login com tema customizado "Beyond" (rótulos "Login/E-mail" / "Senha", botão "ENTRAR"). Apesar do
visual diferente, os seletores padrão do Keycloak continuam funcionando por baixo do tema:
`#username`, `#password`, `#kc-login`. O mesmo fluxo `cy.origin()` já usado para o Beyond
BackOffice funciona aqui sem alteração, usando o mesmo usuário/senha `master` do `.env`.

Após login, a Home mostra 3 cards: "Beyond Comex — Operações Exportação", "Beyond Operação
Interno — Operações Brasil", "Beyond Portal — Portal Fornecedores". Não há um card com o texto
exato "Beyond Operação" citado no roteiro de negócio — "Beyond Operação Interno" é a
interpretação mais provável (a confirmar durante a exploração).

## Armadilha: `cy.screenshot()` logo após `cy.visit()` quebra o runner (Cypress 15.20.1)

Tirar um `cy.screenshot()` muito cedo após um `cy.visit()`/redirect, numa tela com fundo animado
(ex.: gradiente/pontos em movimento da tela de login do Beyond Banking), derruba o teste inteiro
com `TypeError: Cannot destructure property 'duration' of 'props' as it is undefined` dentro do
próprio `cypress_runner.js` — não é um erro da aplicação testada. Reproduzido de forma consistente
em 2 tentativas seguidas; removendo esse screenshot específico (mantendo os demais, em telas sem
animação ou depois dela assentar) o teste passou normalmente. Se precisar de screenshot logo após
um `cy.visit()`, prefira aguardar a tela assentar (`cy.wait()` maior, ou aguardar um elemento
específico visível) antes de tirar o screenshot, ou evitar o screenshot nesse ponto específico.
