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

**Recorrência (rodadas 94-95, 2026-09-17):** o mesmo erro derrubou o teste em mais dois pontos —
`02-apos-tentativa-login` (redirect pós-login do Beyond Banking, tela de seleção de cliente/Home,
mesmo fundo com padrão de pontos) e `27-apos-submeter-login-beyond-backoffice` (redirect pós-login
do Beyond BackOffice, Home "Ecossistema Beyond", mesmo padrão de fundo animado). Confirmado nos
dois casos que o **login em si funcionava** (a screenshot de falha automática do Cypress mostrava a
próxima tela já carregada) — só o screenshot manual diagnóstico é que quebrava o runner. Ambos
removidos (eram só diagnóstico, não essenciais ao relatório final); o dump de texto bruto do body
(sem risco) e as screenshots mais adiante, tiradas só depois da tela assentar de fato, continuam
documentando esses trechos. **Regra geral reforçada**: qualquer screenshot nos primeiros segundos
após um redirect/login em qualquer uma das telas com fundo animado (Beyond Banking e Beyond
BackOffice/Beyond) é candidato a essa quebra — preferir não tirar screenshot ali, ou só depois de
uma espera/checagem de estabilização bem maior que alguns segundos.

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
   - **Armadilha geral (útil pra qualquer botão de texto único nesse wizard):** os rótulos dos
     botões frequentemente têm outro botão cujo texto é um superconjunto (ex. "AQUISICAO" vs
     "AQUISICAO ANCORA"). Sempre usar `cy.contains('button', /^TEXTO_EXATO$/)` em vez de
     `cy.contains('button', 'TEXTO_EXATO')` nessas telas.
   - (Uma investigação antiga concluiu, incorretamente, que "Continuar" travava aqui um bug real —
     corrigido: era só o chat acumulando mensagens, ver seção "Fluxo completo" abaixo para o
     caminho certo já validado. Detalhe arquivado em `documentacao-historico.md`.)

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

## CORREÇÃO (2026-09-16): o 400 do "Avançar" NÃO era bug — era Documento duplicado

**A conclusão abaixo (BUG REAL) está SUPERADA.** O Thiago suspeitou (2026-09-16) que o 400 era
causado por reusar o mesmo valor fixo (`12345`) no campo "Documento" em todas as operações de
teste (88672-88676) — Documento não pode se repetir. Confirmado: trocando o Documento por uma
hash aleatória de 10 caracteres por execução (`Math.random().toString(36).slice(2, 12)`) e o Valor
para R$ 100.000,00, o mesmo fluxo de "Avançar" passou a responder **200**
(`{"id":88681,"dataOperacao":"..."}`), com a situação da operação mudando de "enviado" para
"sucesso" (confirmado por uma chamada de API separada, `GET .../pre-operacoes/cliente/painelLazy`,
não só pelo toast local "Operação encaminhada!"). **Passo 12 do roteiro (avançar a operação) fica
concluído com sucesso** — não é mais um bloqueio. Ver `## Execução` (rodadas 74-89) da tarefa
`20260915123730-criacao-operacao-servico` para o detalhe completo.

## Armadilha: host do Keycloak do realm `multiplicacapital` (Beyond BackOffice) varia entre execuções (2026-09-16)

A detecção antiga de "caiu no Keycloak?" comparava a URL contra um hostname fixo
(`ambiente.keycloakUrl`, resolvido de `HML_KEYCLOAK_URL` = `keycloak-new-2.grupomultiplica.com.br`).
Numa execução real, o login do Beyond BackOffice (realm `multiplicacapital`) foi servido por um
host **diferente**: `lgni.grupomultiplica.com.br` (mesmo padrão de URL Keycloak,
`/auth/realms/.../protocol/openid-connect/auth`) — a comparação por hostname fixo não reconheceu
esse host, pulou o bloco de login inteiro, e o teste travou depois tentando rodar comandos contra
o app já tendo "passado direto" pela tela de login sem logar
(`expected to run against origin beyond-hml but the application is at origin lgni...`).
**Solução:** detectar Keycloak pelo padrão do **path** da URL (`/auth/realms/`), não por hostname
fixo, e usar a origin de fato observada (`new URL(url).origin`) no `cy.origin()` em vez de sempre
`ambiente.keycloakUrl`.

**Achado adicional, ainda não confirmado como reproduzível:** numa execução em que o host `lgni`
foi usado, a própria tela do Keycloak (antes até de mostrar o formulário de login) respondeu com
o erro **"Parâmetro inválido: redirect_uri"** — sugere que o client `autenticacao` do realm
`multiplicacapital` pode não ter `https://beyond-hml.grupomultiplica.com.br/` cadastrado como
`redirect_uri` válido nesse host específico (`lgni`), diferente de `keycloak-new-2` (onde o mesmo
fluxo funcionou em rodadas anteriores, 80-88). Não confirmado se é uma falha de configuração
persistente de `lgni` ou um estado transitório (2 tentativas seguintes falharam antes de chegar
nessa tela, por flakiness já conhecida do `cy.origin()` — ver armadilha abaixo — sem re-observar o
erro de `redirect_uri` nem confirmá-lo como ausente). Se reaparecer em execuções futuras,
considerar RESULTADO (bug/config real, bloqueia passos 13-14), não dúvida.

(Texto original, mais detalhado, do bug do 400 antes desta correção — arquivado em
`documentacao-historico.md`.)

## Validação em banco de dados (mapeado em 2026-09-16, pedido do Thiago)

Este módulo agora consegue consultar o banco HML (`beyondhml`) em modo **somente leitura**,
reaproveitando o padrão de `SupAutomacaoUteis/subagents/cedente/repo/cypress/support/db/dbClient.cjs`
(`mssql/msnodesqlv8`, `trustedConnection: true` — usa a identidade Windows do processo, não precisa
de usuário/senha). Dependências `mssql`+`msnodesqlv8` instaladas em `package.json` deste módulo;
variáveis `HOMOLOG_DB_HOST`/`HOMOLOG_DB_NAME`/`HOMOLOG_DB_PORT` adicionadas ao `.env` local (mesmos
valores já usados pelo `SupAutomacaoUteis`/cedente — nunca expor o valor aqui, só o nome da
variável).

**Tabelas relevantes pro fluxo de criação/avanço de operação de serviço** (schema real, confirmado
via `INFORMATION_SCHEMA`, não documentação externa):
- `MC_MOP_PRE_OPERACAO`: uma linha por operação criada no Beyond Banking. Coluna `id` = número
  mostrado na tela (ex. 88681). Colunas relevantes: `situacao` (varchar, ex. `VALIDADO` — vocabulário
  próprio do banco, não bate literalmente com os textos "enviado"/"sucesso" mostrados na tela),
  `indVirouOperacao` (bit — `true` só quando o "Avançar" de fato converteu a pré-operação em
  operação real), `dataVirouOperacao`, `indExcluida`, `indRejeitada`.
- `MC_MOP_OPERACAO`: só ganha uma linha quando uma pré-operação "vira operação" de fato. Vínculo
  via `idPreOperacao`. Tem seu próprio `situacao` (valor `CRIADO` observado nas operações
  confirmadas). Ausência de linha aqui para um `idPreOperacao` = a operação nunca foi confirmada
  no backend, independente do que a UI mostrou.
- Scripts avulsos de consulta (somente leitura, nunca escrevem no banco) na raiz deste módulo:
  `investigar-schema-mop.cjs` (descoberta de tabelas/colunas via `INFORMATION_SCHEMA`) e
  `validar-operacao-db.cjs <id...>` (consulta pontual de uma ou mais pré-operações/operações por
  id). Não fazem parte da spec Cypress descartável — são ferramenta de diagnóstico reaproveitável
  entre tarefas futuras que precisem validar estado real de operação em banco.

**Achado importante:** confirmado que `indVirouOperacao=true` + linha em `MC_MOP_OPERACAO` é o
sinal confiável de que "Avançar" funcionou de verdade (validado para 3 operações com Documento
único: 88681, 88682, 88683) — mais forte que o toast da UI ou até a chamada `painelLazy`. Também
confirmado que as operações com Documento duplicado (88675, 88676, erro 400) realmente nunca
viraram operação no banco. **Mas há um caso não resolvido**: a operação 88677 foi observada numa
rodada anterior com "situação sucesso" na tela do dashboard, porém a consulta em banco (rodada 93)
mostra `indVirouOperacao=false` e nenhuma linha em `MC_MOP_OPERACAO` — divergência entre UI e banco
ainda não explicada (pode ter sido erro de leitura da tela naquela rodada, ou um cenário real de UI
mostrando sucesso sem confirmação real no backend). Ver task `20260915123730-criacao-operacao-servico`
para o detalhe.
