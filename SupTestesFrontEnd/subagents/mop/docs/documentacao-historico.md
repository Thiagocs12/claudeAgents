# Histórico arquivado de docs/documentacao.md (módulo mop)

> Arquivado em 2026-09-16 para manter `docs/documentacao.md` (relido INTEIRO a cada ciclo) abaixo
> de ~250 linhas. Conteúdo movido aqui, verbatim, por estar **superado** por correções
> posteriores já registradas no arquivo principal — só abra este arquivo se precisar reconstituir
> o "porquê" de uma investigação já resolvida.

## Investigação superada: "Continuar" parecia travar o wizard após escolher o produto (2026-09-15)

Registrado originalmente dentro de "Fluxo de criação de operação no Beyond Banking", como
"Pendente de investigação" e depois "BUG REAL DA APLICAÇÃO" — **ambos superados**: não era
travamento nem bug, era o chat acumulando mensagens no histórico (painel "duplicado
verticalmente" era renderização de 2 montagens do mesmo componente, não uma cópia congelada) e a
mensagem de confirmação de conta não estava sendo capturada pelo scraper por tag. Ver seção "Fluxo
completo de criação de operação de serviço no Beyond Banking" no arquivo principal para o fluxo já
corrigido e validado.

- **Pendente de investigação (texto original):** ao clicar "Continuar", o painel do chat pareceu
  duplicar visualmente e a lista de elementos coletada ficou idêntica à etapa anterior (sem avanço
  visível pro passo de seleção de conta).
- **Armadilha geral (útil pra qualquer botão de texto único nesse wizard):** os rótulos dos botões
  frequentemente têm outro botão cujo texto é um superconjunto (ex. "AQUISICAO" vs "AQUISICAO
  ANCORA"). Sempre usar `cy.contains('button', /^TEXTO_EXATO$/)` em vez de
  `cy.contains('button', 'TEXTO_EXATO')` nessas telas. (Esta parte não é superada — segue válida,
  só duplicada aqui porque estava no mesmo bloco arquivado.)
- **BUG REAL DA APLICAÇÃO (2026-09-15, texto original, bloqueia o roteiro no passo 7):** ao clicar
  em "Continuar" depois de confirmar o produto (ex. BOLETO), a URL muda (`.../operation`,
  confirmando que o clique foi processado e o roteamento client-side avançou) e o cabeçalho
  confirma a escolha do produto completo, mas a tela **reinicia visualmente a conversa do
  wizard** desde a primeira mensagem ("Olá, eu sou o Beyond..."), com o painel "Nova Operação"
  aparecendo **duplicado verticalmente**, sem nunca chegar à pergunta de seleção de conta.
  Reproduzido de forma consistente (rodadas 44 e 46), confirmado com instrumentação de rede
  (nenhuma chamada nova específica após o clique) e screenshot de página inteira (sem conteúdo
  adicional escondido). **Bloqueia qualquer tentativa de completar os passos 7-14 do roteiro**
  (texto da época — corrigido depois: não bloqueava de fato, ver acima).
- **Achado colateral (bug menor, ainda válido/observado):** a partir desse ponto, a aplicação passa
  a disparar repetidamente uma requisição para um asset de logo no **host errado** (domínio raiz
  `beyondbanking-hml` em vez do subdomínio `beyondbanking-ope-hml` onde a página está rodando),
  recebendo 404 todas as vezes.

## Bug do 400 no "Avançar" — texto original antes da correção (2026-09-16)

Substituído por uma versão mais curta no arquivo principal ("CORREÇÃO (2026-09-16): o 400 do
'Avançar' NÃO era bug"). Texto original completo, preservado aqui:

Clicar no ícone **"Avançar"** (`div[aria-label="Avançar"] button`) de uma operação recém-criada
dispara `POST https://beyond-hml.grupomultiplica.com.br/mc-api-gateway-ms/v1/operacao/pre-operacoes/{id}/gerar`,
que respondia **400**. O front-end não trata esse erro (`unhandled promise rejection`, derruba
qualquer teste Cypress que não esteja ignorando exceções da aplicação; na UI aparece um indicador
vermelho de erro). Reproduzido em 2 de 2 tentativas válidas na época (operações 88675 e 88676) —
causa real identificada depois: campo "Documento" repetido entre as operações de teste, não um bug
de aplicação.

## Narrativa original: processos órfãos de `npx cypress run` sem timeout (2026-09-15)

Movido do arquivo principal em 2026-09-17 (a armadilha continua ativa — a regra compacta ficou lá;
esta é a narrativa completa do incidente que originou a regra).

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

## Narrativa original: possível erro de `redirect_uri` no host `lgni` (2026-09-16, nunca mais reobservado)

Movido do arquivo principal em 2026-09-17 (achado especulativo, nunca reproduzido de novo — as
sessões seguintes sempre usaram o host `keycloak-new-2`, nunca mais `lgni`).

Numa execução em que o realm `multiplicacapital` (Beyond BackOffice) foi servido pelo host `lgni`
(em vez de `keycloak-new-2`), a própria tela do Keycloak (antes até de mostrar o formulário de
login) respondeu com o erro **"Parâmetro inválido: redirect_uri"** — sugeria que o client
`autenticacao` do realm `multiplicacapital` pudesse não ter
`https://beyond-hml.grupomultiplica.com.br/` cadastrado como `redirect_uri` válido nesse host
específico, diferente de `keycloak-new-2` (onde o mesmo fluxo funcionou em rodadas anteriores,
80-88). Não confirmado se era uma falha de configuração persistente de `lgni` ou um estado
transitório (2 tentativas seguintes falharam antes de chegar nessa tela, por flakiness já conhecida
do `cy.origin()`, sem re-observar o erro nem confirmá-lo como ausente).

## Narrativa original: recorrência do bug de screenshot pós-redirect (rodadas 94-95, 2026-09-17)

Movido do arquivo principal em 2026-09-17 (regra compacta ficou lá; esta é a narrativa completa da
recorrência que a reforçou).

O mesmo erro (`TypeError: Cannot destructure property 'duration' of 'props'...`) derrubou o teste
em mais dois pontos — `02-apos-tentativa-login` (redirect pós-login do Beyond Banking, tela de
seleção de cliente/Home, fundo com padrão de pontos) e `27-apos-submeter-login-beyond-backoffice`
(redirect pós-login do Beyond BackOffice, Home "Ecossistema Beyond", mesmo padrão de fundo
animado). Confirmado nos dois casos que o login em si funcionava (a screenshot de falha automática
do Cypress mostrava a próxima tela já carregada) — só o screenshot manual diagnóstico é que
quebrava o runner. Ambos removidos (eram só diagnóstico, não essenciais ao relatório final); o dump
de texto bruto do body (sem risco) e as screenshots mais adiante, tiradas só depois da tela
assentar de fato, continuam documentando esses trechos.

## Narrativa original: falha de login "Usuário ou senha inválidos" reproduzível nos dois realms (2026-09-17, rodadas 96-104) — SUPERADA

Movido do arquivo principal em 2026-09-17 (rodadas 105-106 trouxeram achado novo que supera esta
conclusão — ver "Armadilha: falha de login ... agora isolada ao realm `multiplicacapital`" no
arquivo principal).

A partir da rodada 96 desta sessão (2026-09-17), o login via Keycloak (`keycloak-new-2...`) passou
a rejeitar a credencial `master` (usuário `automacao`, mesma usada desde 2026-09-15) com a
mensagem real da tela **"Usuário ou senha inválidos"**, em **ambos os realms**
(`beyondbanking-hml` e `multiplicacapital`) — não é a flakiness intermitente antiga do
`cy.origin()`/spec bridge (essa é uma classe de erro diferente, sem mensagem de credencial
inválida). O login funcionava normalmente até a rodada 94 desta mesma sessão e ao longo de toda a
sessão anterior (rodadas 74-93, 2026-09-16, com operações reais criadas/avançadas). Consultado o
Thiago (rodada 97, dúvida bloqueante) se seria rotação/expiração de senha ou bloqueio de conta por
força bruta (efeito colateral de tentativas repetidas) — autorizou tentar de novo (rodada 104), mas
a falha se repetiu de forma idêntica e imediata nos dois realms. Registrado então como RESULTADO da
tarefa (credencial precisaria de ação de quem administra o Keycloak/HML). **Superado pela rodada
105-106**: depois da correção do espaço em branco no `.env` (achada pelo Thiago), o login voltou a
funcionar normalmente no realm `beyondbanking-hml`, mas continuou falhando especificamente no realm
`multiplicacapital` — indicando que o problema nunca foi (ou deixou de ser) uma credencial errada de
forma geral, e sim algo isolado a esse realm (provável bloqueio de conta por força bruta,
concentrado pelas várias tentativas de login mal-sucedidas contra `multiplicacapital` nas rodadas
96, 97 e 104).

## Narrativa original: `beyondbanking-hml` fica intermitentemente indisponível (observado 2026-09-15)

Movido do arquivo principal em 2026-09-17 (achado antigo, baixa recorrência desde então — a
sessão de 2026-09-17, rodadas 94-106, não reproduziu este sintoma específico).

Numa mesma sessão de exploração, o host `beyondbanking-hml.grupomultiplica.com.br` respondeu
normalmente numa rodada e, poucos minutos depois, passou a falhar com `ESOCKETTIMEDOUT` logo no
`cy.visit()` inicial — confirmado fora do Cypress com `curl` direto (múltiplas tentativas ao longo
de ~2 min, todas `HTTP_CODE=000`/timeout de conexão), enquanto o Keycloak (`keycloak-new-2...`)
respondia normalmente no mesmo intervalo — ou seja, não era problema de rede geral, era o host
`beyondbanking-hml` especificamente. Se reaparecer num ciclo futuro: (1) confirmar com
`curl --max-time 20` direto no host antes de assumir bug de spec; (2) se confirmado que o host não
responde, isso não é dúvida bloqueante (não precisa de decisão do Thiago) nem resultado final —
deixar a tarefa em `executando/` com a narrativa atualizada e deixar o próximo ciclo tentar de novo.

## Narrativa original: dúvida errada casada por prefixo de id na pré-sincronização (2026-09-17)

Movido do arquivo principal em 2026-09-17 (a armadilha continua ativa — a regra compacta e a
pendência pro Supervisor ficaram lá; esta é a narrativa completa do caso que originou o registro).

Esta tarefa teve **duas** dúvidas registradas ao longo do tempo sob o mesmo id base
(`20260915123730-criacao-operacao-servico`, sem sufixo, e `... (2)`, mais recente). A primeira foi
respondida e resolvida ainda em 2026-09-15; a segunda (sobre o login falhando com "Usuário ou senha
inválidos", rodadas 96-97) ficou pendente. Mesmo assim, a pré-sincronização determinística do
`run-cycle.ps1` devolveu a tarefa de `tarefas/aguardando-resposta/` pra `tarefas/executando/` no
ciclo seguinte — aparentemente casando pelo prefixo do id e enxergando a dúvida **antiga**
(`respondida`) em vez da mais recente (`(2)`, ainda `pendente`), que é a que de fato bloqueia a
continuação. Corrigido manualmente pelo subAgent (rodada 98): tarefa devolvida pra
`aguardando-resposta/` sem retomar tentativas de login (que repetiriam o risco de aprofundar um
possível bloqueio de conta).
