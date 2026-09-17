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
