---
id: 20260915123730-criacao-operacao-servico
modulo: mop
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-15
---

## Objetivo

Criar uma operação de serviço no **Beyond Banking** e confirmar que ela avança corretamente até
aparecer concluída no Monitor Diário do **Beyond** (sistema diferente, ver seção "Ambiente"
abaixo). Este é o teste piloto do Sup TestesFrontEnd.

Roteiro de negócio (passo a passo dado pelo Thiago — a exploração real de seletores/telas é
trabalho do subAgent, isto aqui é o roteiro funcional a seguir):

1. Acessar o Beyond Banking (HML).
2. Selecionar o cedente **kenerson**.
3. Usar o **cadastro de cedente master** desse cedente (não outro cadastro/perfil que ele possa
   ter).
4. Acessar "Beyond Operação".
5. Clicar em **"Criar Operação"**.
6. Navegar até o serviço: **AQUISIÇÃO → ANTECIPAÇÃO DE DUPLICATA → DUPLICATA → SERVIÇO → BOLETO**.
7. Selecionar **qualquer conta**, aleatoriamente.
8. Incluir a operação **"por digitação"** (não por importação de arquivo).
9. Em **Cad Pessoa**, consultar **qualquer CPF** e usar essa pessoa como **sacado**.
10. Preencher os demais campos necessários (usar valores plausíveis/de teste onde não houver
    orientação específica — registrar na narrativa qualquer campo cujo valor não seja óbvio).
11. **Salvar** e **gerar a operação**.
12. Acessar o **dashboard de Operações** e **avançar a operação**.
13. Acessar o **Monitor Diário via `beyond.grupomultiplica.com.br`** (Beyond BackOffice, ver
    "Ambiente" — confirmar que caiu no ambiente HML antes de prosseguir, não em produção).
14. Verificar que a operação aparece lá, e que o **histórico mostra a etapa "Inclusão OPE" como
    concluída**.

## Critérios de aceite

- Operação criada com sucesso no Beyond Banking (sem erro bloqueante em nenhum passo 1-11).
- Operação avançada com sucesso a partir do dashboard de Operações (passo 12).
- Operação localizada no Monitor Diário do Beyond (passo 13).
- Histórico da operação no Monitor Diário mostra a etapa "Inclusão OPE" com status concluída.
- Toda tentativa (inclusive as que não deram certo de primeira) narrada passo a passo na seção
  `## Execução` deste arquivo, incluindo qualquer campo preenchido com valor não óbvio (registrar
  qual valor foi usado, para reprodutibilidade — nunca dado sensível real).

## Ambiente / perfil de login

- **Beyond Banking** (criação da operação): `https://beyondbanking-hml.grupomultiplica.com.br/`
  — HML. Login: mesmo SSO/Keycloak já mapeado (perfil `master`) — confirmar que funciona igual
  aqui; se pedir algo diferente, registrar dúvida em vez de assumir.
- **Beyond / Beyond BackOffice** (checagem no Monitor Diário): `beyond-hml.grupomultiplica.com.br`
  — HML (confirmado pelo Thiago em 2026-09-15; a menção sem `-hml` foi só um esquecimento de
  digitação, mesmo host já documentado pelo `SupE2eAutomation`).

## Material de apoio

- `docs/documentacao.md` deste módulo — login/navegação já mapeados pelo `SupE2eAutomation` no
  Beyond BackOffice (Monitor Diário), útil pro passo 13-14. Os passos 1-12 (Beyond Banking) são
  território totalmente novo, sem mapeamento prévio.

## Execução

Retomada em 2026-09-15 (novo ciclo): a tarefa duplicada em `tarefas/aguardando-resposta/` (versão
antiga, que explorava "Nova Operação" dentro do Beyond BackOffice — app errado) foi descartada por
decisão do Thiago (ver `duvidas.md`). Reiniciando do zero seguindo o roteiro de 14 passos desta
versão, app correto: Beyond Banking (`beyondbanking-hml.grupomultiplica.com.br`).

- Tentei acessar `https://beyondbanking-hml.grupomultiplica.com.br/` → redirecionou para um
  Keycloak com realm próprio (`beyondbanking-hml`, distinto do realm usado pelo Beyond BackOffice),
  com tela de login customizada (visual "Beyond", campos "Login/E-mail" e "Senha", botão "ENTRAR")
  — mas os seletores padrão do Keycloak (`#username`, `#password`, `#kc-login`) continuam
  funcionando por baixo do tema customizado, então o mesmo fluxo de login via `cy.origin()` já
  usado para o Beyond BackOffice funcionou aqui também, sem precisar de tratamento diferente.
- Tentei tirar um screenshot (`cy.screenshot()`) logo após o `cy.visit()` inicial, antes do
  redirect pro Keycloak assentar → o runner do Cypress quebrou com
  `TypeError: Cannot destructure property 'duration' of 'props' as it is undefined` (erro interno
  do `cypress_runner.js`, não da aplicação testada — reproduzido de forma consistente em 2
   tentativas). Retirando esse `cy.screenshot()` específico (mantendo os outros) o teste passou
  normal — parece ser um bug do runner do Cypress 15.20.1 ao tirar screenshot muito cedo numa tela
  com fundo animado (gradiente/pontos em movimento) logo após a navegação. Registrado em
  `docs/documentacao.md` como armadilha a evitar.
- Após login, a Home do Beyond Banking mostra 3 cards: "Beyond Comex — Operações Exportação",
  "Beyond Operação Interno — Operações Brasil", "Beyond Portal — Portal Fornecedores". Nenhum
  card chamado exatamente "Beyond Operação" (passo 4 do roteiro) — o mais próximo é "Beyond
  Operação Interno". Vou seguir por ele como a interpretação mais provável do passo 4 e continuar a
  exploração; se não for o caminho certo, volto e registro aqui.
- Tentei clicar no card "Beyond Operação Interno" → navegou para um **subdomínio diferente**
  (`https://beyondbanking-ope-hml.grupomultiplica.com.br/`, origem distinta pro Cypress — precisou
  de `cy.origin()` a partir daqui, senão o comando seguinte falha com "command was expected to run
  against origin X but the application is at origin Y"). Caiu direto numa tela "Operações" com
  filtros, cards de resumo (Operações/Títulos/Valor a Receber) e um botão **"Criar Operação"**
  visível — bate com o passo 5 do roteiro. Cedente mostrado no topo da tela: **"SO LARANJA
  COMERCIO DE CITR..."** (nome truncado) — não é o cedente "kenerson" pedido no passo 2. Existe um
  ícone de "casa"/home ao lado do nome do cedente no topo, ainda não explorado — hipótese: é o
  seletor pra trocar de cedente. Próximo passo: explorar esse seletor antes de clicar em "Criar
  Operação", pra resolver os passos 2-3 do roteiro (selecionar cedente kenerson, cadastro
  master) antes de avançar.
- Tentei clicar no ícone de "casa" ao lado do nome do cedente (hipótese de seletor de cedente) →
  navegou de volta pro domínio raiz, para `https://beyondbanking-hml.grupomultiplica.com.br/clients`
  (rota `/clients` — provável tela de seleção de cedentes, bate com os passos 2-3 do roteiro).
  Confirmado via aba de rede do Cypress (`GET /clients` 200), mas o `cy.screenshot()` logo em
  seguida (ainda dentro da mesma origem cross-origin anterior, tela em branco com o logo/spinner
  animado do Beyond carregando) **reproduziu de novo a armadilha já documentada**
  (`TypeError: Cannot destructure property 'duration' of 'props'...`) — confirma que o gatilho é
  genérico (qualquer tela com logo/spinner animado logo após navegação, não só a tela de login).
- **Novo ciclo (retomada 2026-09-15, tarde):** ao rodar de novo do zero (login limpo, sem sessão
  anterior), a aplicação **redirecionou direto para `/clients` logo após o login** — sem passar
  pela Home com os 3 cards nem precisar clicar em "Beyond Operação Interno"/ícone de casa. A tela
  é "Seleção de cliente" ("Automacao, Qual cliente deseja acessar?"), com um dropdown "Selecione
  aqui" e botão "Avançar" (screenshot `02-apos-tentativa-login.png`). **Isso resolve os passos 2-3
  do roteiro diretamente e de forma mais simples** — parece que o app só mostra a Home/cards depois
  que um cliente já foi selecionado na sessão; o caminho anterior (Home → card → ícone de casa →
  `/clients`) era uma volta desnecessária só porque a sessão de exploração anterior já tinha um
  cliente pré-selecionado. Reescrevi a spec para focar direto neste fluxo: abrir o dropdown e
  localizar "kenerson". Próximo passo: rodar e ver as opções do dropdown.
- **Retomada 2026-09-15, noite:** ao iniciar o ciclo, encontrei processos `Cypress.exe`/`node.exe`
  órfãos desta pasta ainda vivos (rodada anterior parece ter sido interrompida sem esperar o
  `npx cypress run` terminar — o log da rodada anterior, `cypress-run-29.log`, estava incompleto).
  Matei os processos manualmente antes de continuar (regra 5 do `AGENTE.md`).
- Tentei digitar "kenerson" no dropdown de seleção de cliente e escolher a opção → apareceu **só
  uma opção**: "07.019.231/0001-96 - KENERSON INDUSTRIA E COMERCIO DE PRODUTOS OPTICOS LTDA". Não
  existe uma escolha explícita de "cadastro master" nessa tela — parece que o cedente kenerson só
  tem um cadastro/CNPJ associado ao usuário `automacao`, então o passo 3 do roteiro ("cadastro
  master") não exige ação adicional aqui; a tela oferece um único caminho.
- Tentei clicar em "Avançar" após selecionar kenerson → voltou para a Home (`/`, mesmo domínio
  raiz) mostrando os mesmos 3 cards de antes ("Beyond Comex", "Beyond Operação Interno", "Beyond
  Portal"), agora com "KENERSON INDUSTRIA E COME..." no topo confirmando o cedente selecionado
  (screenshot `04-apos-selecionar-kenerson-avancar.png`). Confirma a hipótese anterior: a Home só
  mostra os cards depois de um cedente selecionado.
- Escrevi o próximo trecho da spec: clicar no card "Beyond Operação Interno" (interpretação mais
  provável do passo 4 "Beyond Operação" do roteiro — não existe card com esse texto exato), usar
  `cy.origin()` pro subdomínio `beyondbanking-ope-hml...` e localizar/clicar em "Criar Operação"
  (passo 5), mapeando os elementos da tela em cada etapa.
- Tentei rodar essa versão da spec (2x seguidas) → **falhou logo no primeiro `cy.visit()`** (antes
  de chegar no trecho novo) com `ESOCKETTIMEDOUT` — o host `beyondbanking-hml.grupomultiplica.com.br`
  parou de responder. Investiguei fora do Cypress com `curl` direto: 4 tentativas ao longo de
  ~2 minutos (incluindo com `--retry`/backoff de 15s) deram todas `HTTP_CODE=000` (timeout de
  conexão, sem resposta alguma), enquanto o Keycloak (`keycloak-new-2...`) respondeu normalmente
  (403 em <1s) no mesmo intervalo — ou seja, não é problema de rede/DNS geral daqui, é
  especificamente o host `beyondbanking-hml` que parou de responder.
- **Importante:** a rodada anterior (run-30, poucos minutos antes) tinha funcionado normalmente até
  a Home pós-seleção de cedente (screenshot `04-apos-selecionar-kenerson-avancar.png`) — ou seja,
  o ambiente caiu **entre** essa rodada e as tentativas seguintes, não é um problema permanente
  nem ligado à spec nova. Não travei em dúvida (não precisa de decisão do Thiago, só de o ambiente
  voltar) nem é resultado final do teste (objetivo não foi tentado por completo) — deixando a
  tarefa em `executando/` com a narrativa atualizada para o próximo ciclo (5 min) retomar
  rodando a spec já escrita (trecho do passo 4-5 ainda não validado) assim que o host responder de
  novo. Nenhum processo Cypress/node ficou órfão desta vez (rodadas 31 e 32 terminaram sozinhas,
  falha capturada pelo próprio Cypress).
- **Novo ciclo (2026-09-15, continuação):** antes de tentar `npx cypress run` de novo, confirmei
  fora do Cypress se o host já tinha voltado — 3 tentativas de `curl --max-time 20` seguidas
  (~45s de intervalo total) contra `beyondbanking-hml.grupomultiplica.com.br` deram todas
  `HTTP_CODE=000` (timeout de conexão), enquanto o Keycloak (`keycloak-new-2...`) respondeu
  normalmente (403 em <1s) nas mesmas condições — confirma que o host específico ainda está fora
  do ar, mesma armadilha já documentada em `docs/documentacao.md`. Não rodei `npx cypress run`
  desta vez (sem sentido gastar o ciclo contra um host confirmadamente down). Verifiquei também se
  havia processo Cypress/node órfão desta pasta (regra 5 do `AGENTE.md`) — havia um `node.exe`
  vivo na máquina, mas sua `CommandLine` (`investigar-schema-comite.cjs`) não pertence a este
  módulo/pasta, então não foi tocado. Isso não é dúvida bloqueante nem resultado final — deixando a
  tarefa em `executando/` para o próximo ciclo (5 min) tentar de novo, sem alterar a spec já escrita
  (trecho do passo 4-5 do roteiro, ainda não validado).
- **Novo ciclo (2026-09-15, continuação):** antes de rodar `npx cypress run`, confirmei de novo fora
  do Cypress se o host já tinha voltado — 3 tentativas de `curl --max-time 20` seguidas contra
  `beyondbanking-hml.grupomultiplica.com.br` deram novamente todas `HTTP_CODE=000` (timeout de
  conexão, ~20s cada). Não rodei `npx cypress run` — sem sentido gastar o ciclo contra um host ainda
  confirmadamente down. Checagem de processo órfão (regra 5): só encontrado um `node.exe`
  (`investigar-schema-comite.cjs`), que não pertence a este módulo/pasta — nada para matar. Não é
  dúvida bloqueante nem resultado final — deixando a tarefa em `executando/` para o próximo ciclo
  (5 min) tentar de novo, sem alterar a spec já escrita (trecho do passo 4-5 do roteiro, ainda não
  validado).
- **Novo ciclo (2026-09-15, continuação):** checagem de processo órfão (regra 5) via
  `Get-CimInstance Win32_Process` filtrando `CommandLine` por `cypress`+`mop` — nenhum processo
  encontrado, nada para matar. Confirmei de novo fora do Cypress se o host já tinha voltado:
  `curl -v --max-time 20` contra `beyondbanking-hml.grupomultiplica.com.br` resolveu o IP
  (`10.101.10.254`) mas deu `Connection timed out after 20008 milliseconds` (mesma falha das
  tentativas anteriores — DNS ok, TCP não conecta). Como controle, testei o host do Keycloak
  (`HML_KEYCLOAK_URL` do `.env`, sem expor valor completo/credencial) — respondeu `403` em 0.06s,
  confirmando que a rede geral e o Keycloak estão OK, é o host `beyondbanking-hml` especificamente
  que segue fora do ar (mesma armadilha documentada em `docs/documentacao.md`). Conectividade geral
  também confirmada OK via `https://www.google.com` (200). Não rodei `npx cypress run` — sem
  sentido gastar o ciclo contra um host ainda confirmadamente down. Não é dúvida bloqueante nem
  resultado final — deixando a tarefa em `executando/` para o próximo ciclo (5 min) tentar de novo,
  sem alterar a spec já escrita (trecho do passo 4-5 do roteiro, ainda não validado).
