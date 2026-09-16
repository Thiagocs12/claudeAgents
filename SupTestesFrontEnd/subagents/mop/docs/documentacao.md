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

Após login, a aplicação redireciona para `/clients` — tela "Seleção de cliente" ("Automacao, Qual
cliente deseja acessar?"), dropdown-autocomplete "Selecione aqui" (assíncrono, mostra "Loading..."
logo após abrir — digitar o termo de busca antes de checar as opções) e botão "Avançar". Buscando
"kenerson" aparece uma única opção ("07.019.231/0001-96 - KENERSON INDUSTRIA E COMERCIO DE
PRODUTOS OPTICOS LTDA") — não há escolha explícita de "cadastro master" nessa tela; parece que o
usuário `automacao` só tem um cadastro associado a esse cedente. Depois de selecionar e clicar
"Avançar", volta para a Home (`/`) mostrando os mesmos 3 cards, agora com o cedente selecionado
no topo.

A Home mostra 3 cards: "Beyond Comex — Operações Exportação", "Beyond Operação
Interno — Operações Brasil", "Beyond Portal — Portal Fornecedores". Não há um card com o texto
exato "Beyond Operação" citado no roteiro de negócio — "Beyond Operação Interno" é a
interpretação mais provável (a confirmar durante a exploração). Clicar nesse card navega pra um
subdomínio diferente (`beyondbanking-ope-hml.grupomultiplica.com.br`, origem distinta pro
Cypress — precisa de `cy.origin()`), tela "Operações" com botão "Criar Operação" visível.

## Armadilha: `cy.screenshot()` logo após `cy.visit()` quebra o runner (Cypress 15.20.1)

Tirar um `cy.screenshot()` muito cedo após um `cy.visit()`/redirect, numa tela com fundo animado
(ex.: gradiente/pontos em movimento da tela de login do Beyond Banking), derruba o teste inteiro
com `TypeError: Cannot destructure property 'duration' of 'props' as it is undefined` dentro do
próprio `cypress_runner.js` — não é um erro da aplicação testada. Reproduzido de forma consistente
em 2 tentativas seguidas; removendo esse screenshot específico (mantendo os demais, em telas sem
animação ou depois dela assentar) o teste passou normalmente. Se precisar de screenshot logo após
um `cy.visit()`, prefira aguardar a tela assentar (`cy.wait()` maior, ou aguardar um elemento
específico visível) antes de tirar o screenshot, ou evitar o screenshot nesse ponto específico.

## Armadilha: `beyondbanking-hml` fica intermitentemente indisponível (observado 2026-09-15)

Numa mesma sessão de exploração, o host `beyondbanking-hml.grupomultiplica.com.br` respondeu
normalmente numa rodada e, poucos minutos depois, passou a falhar com `ESOCKETTIMEDOUT` logo no
`cy.visit()` inicial — confirmado fora do Cypress com `curl` direto (múltiplas tentativas ao longo
de ~2 min, todas `HTTP_CODE=000`/timeout de conexão), enquanto o Keycloak (`keycloak-new-2...`)
respondia normalmente no mesmo intervalo — ou seja, não é problema de rede geral, é o host
`beyondbanking-hml` especificamente. Se um ciclo futuro tomar `ESOCKETTIMEDOUT` no `cy.visit()`
inicial: (1) confirmar com `curl --max-time 20` direto no host antes de assumir bug de spec; (2)
se confirmado que o host não responde, isso **não é dúvida bloqueante** (não precisa de decisão do
Thiago) nem resultado final (objetivo não foi tentado por completo) — deixar a tarefa em
`executando/` com a narrativa atualizada e deixar o próximo ciclo (5 min depois) tentar de novo.

## Armadilha: `cy.contains(seletor, texto)` quebra com texto de múltiplas palavras (2026-09-15)

`cy.contains(seletor, texto)` — com QUALQUER seletor (`.MuiCard-root`, `div`, etc.) — gera
internamente um seletor de fallback `[type='submit'][value~='TEXTO']` (pra também cobrir
`<input type=submit>`). O operador `~=` do jQuery/Sizzle só casa uma palavra isolada dentro de um
atributo separado por espaços — quando `TEXTO` tem múltiplas palavras (ex.: `'Beyond Operação
Interno'`), a expressão gerada é inválida e todo o comando falha com
`Error: Syntax error, unrecognized expression: ...`, independente de qual seletor foi passado.
**Solução:** ao clicar em algo pelo texto (múltiplas palavras), use `cy.contains(texto)` **sem
seletor** em vez de `cy.contains(seletor, texto)`.

## Fluxo de criação de operação no Beyond Banking (mapeado em 2026-09-15)

Depois do login (`beyondbanking-hml`) e seleção do cedente (ver seção acima), o fluxo pra criar
operação é:

1. Home (3 cards) → clicar **"Beyond Operação Interno"** (via `cy.contains(texto)`, sem seletor —
   ver armadilha acima) → navega para subdomínio `beyondbanking-ope-hml.grupomultiplica.com.br`
   (origem distinta, precisa `cy.origin()`), tela "Operações" com menu lateral (Dashboard, Recibo
   Pêndencia, Recibo Recompra, Importar XML, Consulta de Títulos, Instrução Bancária Lote,
   Instruções Bancárias, Emissão de Boletos, Ordem Pagamento, Tour Virtual, Faq, Logout) e botão
   **"Criar Operação"**.
2. Clicar "Criar Operação" → tela **"Nova Operação"** — **não é um formulário tradicional, é um
   wizard conversacional** ("Beyond, assistente virtual do Grupo Multiplica"), com mensagem inicial
   "Olá, eu sou o Beyond... Vamos começar sua nova operação?" e um botão **"Olá"** pra iniciar a
   conversa. Os passos seguintes do roteiro de negócio (navegar até o serviço
   Aquisição → Antecipação de Duplicata → Duplicata → Serviço → Boleto, escolher conta, incluir
   por digitação, Cad Pessoa) provavelmente acontecem por essa interface de chat — ainda a mapear
   em detalhe (ver `## Execução` da tarefa `20260915123730-criacao-operacao-servico` para o estado
   mais atual).
