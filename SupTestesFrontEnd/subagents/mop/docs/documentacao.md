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
   conversa.
3. Clicar "Olá" → assistente pergunta se mantém o produto da última operação ("Manter"/"Trocar" —
   o texto exibido tem um bug aparente, mostra literalmente a palavra "PRODUTO" em vez do nome real
   do produto anterior). Clicar **"Trocar"** pra escolher explicitamente em vez de confiar no texto
   ambíguo de "Manter".
4. "Trocar" abre uma cadeia de escolhas por botão, uma pergunta por vez, afunilando o produto —
   mapeado o caminho do roteiro de negócio (Aquisição → Antecipação de Duplicata → Duplicata →
   Serviço → Boleto):
   - "Qual o foco de negócio?" → botões incluem `AQUISICAO`, `AQUISICAO ANCORA`, `COBRANCA
     SIMPLES`, etc. — **usar `cy.contains('button', /^AQUISICAO$/)` (regex de match exato)**, não
     `cy.contains('button', 'AQUISICAO')`, porque várias outras opções contêm "AQUISICAO" como
     substring (AQUISICAO ANCORA, AQUISICAO FIDUCIARIA...). Clicar `AQUISICAO`.
   - "Qual o tipo de produto?" → botões incluem `ANTECIPACAO DE DUPLICATA`, `GARANTIA`, `NPL`,
     etc. Clicar `ANTECIPACAO DE DUPLICATA` (match exato).
   - "Qual sub categoria?" → botões `DUPLICATA`, `DUPLICATA INTERCOMPANY`, `DUPLICTA INTERCOMPANY`
     (**achado: há um botão com typo real no app, "DUPLICTA" sem o "A" — bug da aplicação, não da
     spec**). Clicar `DUPLICATA` (match exato).
   - Pergunta se repete (mesma sub categoria) com novos botões `PRODUTO` / `SERVICO`. Clicar
     `SERVICO` (match exato).
   - Nova leva: `BOLETO`, `ESCROW SEM TRAVA`, `ESCROW COM TRAVA`, `PRE-IMPRESSO`, `COMISSARIA`,
     `BOLETO ESPECIAL`. Clicar `BOLETO` (match exato).
   - Aparecem botões **"Voltar"** / **"Continuar"** — o cabeçalho da tela passa a mostrar o caminho
     completo escolhido (ex.: `AQUISICAO - ANTECIPACAO DE DUPLICATA - DUPLICATA - SERVICO -
     BOLETO`), confirmando a seleção. Clicar "Continuar" pra prosseguir.
   - **Pendente de investigação:** ao clicar "Continuar", o painel do chat pareceu duplicar
     visualmente e a lista de elementos coletada ficou idêntica à etapa anterior (sem avanço
     visível pro passo de seleção de conta) — ver `## Execução` da tarefa
     `20260915123730-criacao-operacao-servico` (estado mais recente) antes de repetir essa
     investigação do zero.
   - **Armadilha geral (útil pra qualquer botão de texto único nesse wizard):** os rótulos dos
     botões frequentemente têm outro botão cujo texto é um superconjunto (ex. "AQUISICAO" vs
     "AQUISICAO ANCORA"). Sempre usar `cy.contains('button', /^TEXTO_EXATO$/)` em vez de
     `cy.contains('button', 'TEXTO_EXATO')` nessas telas.
   - **BUG REAL DA APLICAÇÃO (2026-09-15, bloqueia o roteiro no passo 7):** ao clicar em
     "Continuar" depois de confirmar o produto (ex. BOLETO), a URL muda (`.../operation`,
     confirmando que o clique foi processado e o roteamento client-side avançou) e o cabeçalho
     confirma a escolha do produto completo, mas a tela **reinicia visualmente a conversa do
     wizard** desde a primeira mensagem ("Olá, eu sou o Beyond..."), com o painel "Nova Operação"
     aparecendo **duplicado verticalmente**, sem nunca chegar à pergunta de seleção de conta.
     Reproduzido de forma consistente (rodadas 44 e 46), confirmado com instrumentação de rede
     (nenhuma chamada nova específica após o clique — o endpoint de contas,
     `GET .../mc-api-gateway-ms/v1/contabancaria/search`, já tinha sido chamado antes, no
     carregamento inicial da tela) e screenshot de página inteira (`capture: 'fullPage'`, sem
     conteúdo adicional escondido). Ver `## Resultado` da tarefa
     `20260915123730-criacao-operacao-servico` para o detalhe completo. **Bloqueia qualquer
     tentativa de completar os passos 7-14 do roteiro (seleção de conta em diante) até a aplicação
     corrigir esse comportamento.**
   - **Achado colateral (bug menor):** a partir desse ponto travado, a aplicação passa a disparar
     repetidamente uma requisição para um asset de logo no **host errado** (domínio raiz
     `beyondbanking-hml` em vez do subdomínio `beyondbanking-ope-hml` onde a página está rodando),
     recebendo 404 todas as vezes — indício de algum componente remontando repetidamente na tela
     travada.

## Armadilha: `cy.intercept()` não funciona dentro do callback do `cy.origin()` (2026-09-15)

Registrar um `cy.intercept(...)` **de dentro** do callback passado a `cy.origin(...)` falha com
`CypressError: cy.intercept() use is not supported in the cy.origin() callback`. Solução: registrar
o(s) `cy.intercept()` no escopo top-level do teste, **antes** de qualquer `cy.origin()` — o
intercept registrado assim continua válido e captura também as requisições feitas depois, dentro
das origens visitadas via `cy.origin()` (não precisa re-registrar por origem). Se precisar ler o
que foi capturado a partir de dentro de um bloco `cy.origin()`, não dá pra referenciar a variável
externa diretamente (o callback roda em contexto serializado/isolado) — em vez disso, escreva o
resultado num `cy.then()` fora do `cy.origin()`, depois que ele retornar.

## Armadilha: ids `mui-NN` gerados por `useId()` não são estáveis entre execuções (2026-09-16)

Os inputs da tela "Adicionar Títulos" (Documento, Valor, Vencimento etc.) têm ids `mui-NN`
gerados pelo React (`useId`), cujo número depende de quantos outros componentes com id
auto-gerado já montaram antes na mesma sessão/execução — **muda de rodada pra rodada**. Um
hardcode como `#mui-29` funciona por coincidência em algumas execuções e quebra em outras (já
aconteceu). **Solução:** sempre resolver o id dinamicamente a partir do texto do `<label>`
associado: `cy.contains('label', 'Documento').invoke('attr', 'for').then((id) => cy.get('#' + id)...)`
— nunca hardcodar o id.

## Fluxo completo de criação de operação de serviço no Beyond Banking (mapeado em 2026-09-15/16)

Continuação do fluxo já mapeado acima (login → wizard de produto → conta pré-selecionada). A
partir da confirmação da conta (`Continuar` no par de botões mais recente, usando o padrão
`cy.get('button').filter(':visible').contains(regex)` — ver armadilha de painel duplicado acima):

1. Chat pergunta o tipo de entrada: botões **Voltar / Upload de arquivo / Digitação**. Clicar
   `Digitação` (não upload) leva a um **formulário tradicional** "Adicionar Títulos" (dentro do
   painel "Nova Operação"), substituindo o wizard de chat.
2. Campo **CNPJ/CPF** (Cad Pessoa): os inputs dessa tela não têm `name`/`placeholder`/`aria-label`
   nativos — são rótulos MUI flutuantes (`<label for="mui-XX">`). Localizar pelo texto do label
   (`cy.contains('label', 'CNPJ/CPF').invoke('attr', 'for')` → `cy.get('#' + id)`), digitar um CPF
   de teste conhecido (ex. `11144477735`, formata automaticamente). Botão de busca: ícone
   `svg[data-testid="SearchIcon"]` dentro de um `MuiInputAdornment` irmão do input — usar
   `.closest('button')` a partir do svg. A busca preenche automaticamente Nome/Email/CEP/
   Logradouro/Bairro/Cidade/UF a partir do CPF (Telefone pode ficar vazio se o cadastro de teste
   não tiver).
3. Campos do título (Documento, Chave NF-e, Valor, Vencimento, Desconto, Data Limite Desconto):
   mesma técnica de label→for (ver armadilha de `mui-NN` acima, nunca hardcodar). Vencimento é
   `input[type=date]`, precisa de `{ force: true }` no `.type()`. Botão **Salvar** adiciona o
   título a uma tabela real (não duplica dado, só a renderização do painel aparece duplicada
   verticalmente — ver armadilha de painel duplicado documentada acima).
4. Botão **Gerar Operação** (habilita só depois de salvar ao menos 1 título) abre um **modal de
   confirmação** ("Confirma a geração da operação para os títulos digitados? Cancelar/Confirmar").
   Clicar **Confirmar** fecha o modal, volta pro dashboard "Operações" (raiz do subdomínio
   `beyondbanking-ope-hml...`) e mostra um toast verde "Operação criada com sucesso!", com uma
   nova linha na tabela (número sequencial novo por operação, ex. 88672, 88673, ...; Situação
   inicial "enviado").
5. **Tabela do dashboard "Operações"**: a operação recém-criada aparece sempre na **primeira
   linha** (mais recente primeiro) — não fixar um número de operação numa spec, sempre pegar
   `cy.get('table tbody tr').first()` para agir sobre a que acabou de ser criada.
6. **Coluna "Ações" da tabela** (mapeada via dump de `outerHTML`, os ícones não têm texto/
   aria-label consistente — necessário para achar sem clicar às cegas): 5 ícones, cada um dentro
   de um `<div aria-label="...">` que envolve o `<button>` (exceto "Editar", que tem o
   `aria-label` direto no próprio `<button>`, inconsistência de padrão entre os ícones):
   - **"Documentos"**
   - **"Arquivo Aceite"** — aparece com classe `Mui-disabled` (desabilitado) logo após a criação.
   - **"Avançar"** (`data-testid="NextPlanIcon"`) — habilitado logo após a criação. Seletor:
     `div[aria-label="Avançar"] button`.
   - **"Editar"** — `aria-label` direto no `<button>` (não no div pai).
   - **"Excluir"**

## BUG REAL DA APLICAÇÃO (2026-09-16): ícone "Avançar" do dashboard de Operações retorna 400

Clicar no ícone **"Avançar"** (`div[aria-label="Avançar"] button`) de uma operação recém-criada
dispara `POST https://beyond-hml.grupomultiplica.com.br/mc-api-gateway-ms/v1/operacao/pre-operacoes/{id}/gerar`,
que responde **400**. O front-end não trata esse erro (`unhandled promise rejection`, derruba
qualquer teste Cypress que não esteja ignorando exceções da aplicação; na UI aparece um indicador
vermelho de erro). **Reproduzido em 2 de 2 tentativas válidas**, em operações diferentes (nº 88675
e 88676) — não é falha pontual de uma operação específica. Bloqueia qualquer tentativa de avançar
a operação (e, por consequência, de chegar ao Monitor Diário / etapa "Inclusão OPE") a partir do
estado em que a operação é criada (Situação "enviado"). Hipótese não confirmada: o endpoint
`pre-operacoes/{id}/gerar` pode esperar um estado diferente da operação antes de poder ser chamado
por essa ação — não investigado a fundo, ver `## Resultado` da tarefa
`20260915123730-criacao-operacao-servico` para o detalhe completo e a recomendação ao Thiago.
