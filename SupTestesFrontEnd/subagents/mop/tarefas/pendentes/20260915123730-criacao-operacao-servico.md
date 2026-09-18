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

## Execução — resumo (histórico completo arquivado em economia de tokens, 2026-09-16)

> O relato passo a passo original (rodadas 1-73) está arquivado, verbatim e sem perda de
> informação, em `20260915123730-criacao-operacao-servico.historico.md` (mesma pasta) — só abra
> esse arquivo se precisar reconstituir o "porquê" de alguma decisão já tomada. Este resumo abaixo
> é suficiente para qualquer ciclo retomar a tarefa a partir daqui.

**Fluxo provado e reprodutível (passos 1-11 do roteiro), com seletores/padrões validados:**

1. Login no Beyond Banking via Keycloak (`cy.origin()`, mesmo mecanismo do Beyond BackOffice,
   realm próprio `beyondbanking-hml`) — às vezes falha intermitentemente com
   `cy.origin() failed to create a spec bridge...` (ambiental, não é regressão na spec — só rodar
   de novo).
2-3. Cedente **kenerson** (CNPJ 07.019.231/0001-96) tem um único cadastro associado ao usuário
   `automacao` — não existe escolha explícita de "cadastro master" na tela de seleção de cliente
   (`/clients`); a sessão pode pular essa tela se já houver cliente selecionado (aceitar os dois
   cenários na spec).
4-5. Card correto é **"Beyond Operação Interno"** (não existe card com o texto exato "Beyond
   Operação"). Leva pro subdomínio `beyondbanking-ope-hml.grupomultiplica.com.br` (precisa de novo
   `cy.origin()`). Botão "Criar Operação" abre um **wizard conversacional** (chat "Beyond,
   assistente virtual"), não um formulário tradicional.
6. Navegação do produto pelo chat: clicar exatamente (regex `/^TEXTO$/`, nunca substring) em
   AQUISICAO → ANTECIPACAO DE DUPLICATA → DUPLICATA (cuidado: existe uma opção com typo real no
   app, "DUPLICTA", não confundir) → SERVICO → BOLETO → "Continuar".
7. Depois de confirmar o produto, o chat **acumula mensagens** (não substitui) e já mostra a conta
   pré-selecionada (ITAU, Agência 6200, Conta 01013-7) — satisfaz "conta qualquer" do passo 7. O
   painel aparece **duplicado verticalmente no DOM** (2 cópias reais do componente, é só
   renderização — mesmo estado por baixo, confirmado preenchendo campos e vendo os dois lados
   atualizarem juntos). Por causa disso, **nunca usar `cy.contains(seletor, texto)` puro nem
   `.last()`/`.filter(':visible')` encadeado depois de um `cy.contains` que já colapsou pra 1
   elemento** — o padrão que funciona é
   `cy.get(tag).filter(':visible').contains(regex)` (filtra visibilidade ANTES de localizar pelo
   texto).
8. Clicar "Digitação" (não "Upload de arquivo") → vira formulário tradicional "Adicionar Títulos".
9. Campo CNPJ/CPF não tem `placeholder`/`name` (rótulo MUI flutuante) — localizar via
   `cy.contains('label', 'CNPJ/CPF').invoke('attr', 'for')` → `cy.get('#' + id)`. Digitar CPF de
   teste `11144477735` e clicar a lupa (`svg[data-testid="SearchIcon"]` → `closest('button')`) —
   preenche automaticamente Nome/Email/CEP/Logradouro/Bairro/Cidade/UF (Telefone fica vazio).
10. Campos de título por `label[for]` (ids variam por sessão, remapear se preciso): Documento,
    Chave NF-e, Valor, Vencimento (`input[type=date]`, precisa `{ force: true }`), Desconto, Data
    Limite Desconto. **Documento deve ser gerado como hash aleatória por execução**
    (`Math.random().toString(36).slice(2, 12)`) — nunca reusar um valor fixo entre operações
    (documento não pode se repetir, causa 400 no "Avançar" — ver seção abaixo). Valor de teste:
    `100000,00` (R$ 100.000,00). Vencimento: `2026-12-31`.
11. "Salvar" adiciona 1 título na tabela (duplicação é só visual, confirmado). "Gerar Operação"
    abre modal de confirmação — clicar "Confirmar" (mesmo padrão `get+filter(:visible)+contains`)
    fecha o modal, mostra toast "Operação criada com sucesso!" e a operação aparece na tabela do
    dashboard (situação "enviado"). Sempre operar sobre a **primeira linha da tabela** (mais
    recente), não um número fixo — cada execução cria uma operação nova.
12. Ícone "Avançar" (`div[aria-label="Avançar"] button`, `data-testid="NextPlanIcon"`) dispara
    `POST .../mc-api-gateway-ms/v1/operacao/pre-operacoes/{id}/gerar` → **200** de forma
    reprodutível **desde que o Documento do título seja único** (ver achado abaixo). Confirmado em
    banco (não só toast), ver seção seguinte.

_(A narrativa completa rodada-a-rodada de como cada um desses achados foi descoberto está em
`20260915123730-criacao-operacao-servico.historico.md`, incluindo a correção do Thiago de
2026-09-15 sobre a conta pré-selecionada não identificada na primeira tentativa.)_

## Execução — resumo da reabertura (rodadas 74-93, histórico completo arquivado 2026-09-16)

> O relato passo a passo desta reabertura (rodadas 74-93, incluindo o texto integral do pedido do
> Thiago que a motivou) está arquivado, verbatim e sem perda de informação, em
> `20260915123730-criacao-operacao-servico.historico.md` (mesma pasta, seção "rodadas 74-93"). Só
> abra esse arquivo se precisar reconstituir o "porquê" de alguma decisão já tomada — o resumo
> abaixo já é suficiente pra qualquer ciclo retomar a partir daqui.

**Pedido do Thiago que motivou a reabertura (2026-09-16):** não confiar só no toast/UI pra concluir
que o 400 do "Avançar" era bug — validar em banco; suspeita de causa raiz era o campo Documento
repetido (`12345`) entre operações de teste; ajustar Valor de teste pra R$ 100.000,00.

**Confirmado (rodadas 74-93):**
- **Hipótese do Thiago CONFIRMADA**: o 400 era mesmo efeito do Documento duplicado, não bug de
  aplicação. Com Documento único (hash aleatória de 10 caracteres por execução) e Valor R$
  100.000,00, "Avançar" responde 200 de forma reprodutível (confirmado em 3 operações: 88681,
  88682, 88683). **Passo 12 do roteiro está concluído com sucesso** — corrige a conclusão antiga
  (bug real), que não é mais válida.
- **Validação em banco (pedido 1 do Thiago) FEITA** (rodada 93): módulo agora consulta o banco HML
  (somente leitura, `mssql`/`msnodesqlv8`, reaproveitando o padrão do `SupAutomacaoUteis`/cedente —
  ver `docs/documentacao.md`, seção "Validação em banco de dados"). Tabelas `MC_MOP_PRE_OPERACAO`/
  `MC_MOP_OPERACAO` confirmam em banco (não só toast) que: (a) 88675/88676 (Documento duplicado)
  nunca viraram operação de fato; (b) 88681/88682/88683 (Documento único) viraram operação de fato,
  com linha criada em `MC_MOP_OPERACAO`.
- **Achado ainda não resolvido**: a operação 88677 tinha sido registrada (rodada 89) como
  aparentando "situação sucesso" na tela, mas a validação em banco (rodada 93) mostra que ela
  **não** virou operação de fato (`indVirouOperacao=false`, sem linha em `MC_MOP_OPERACAO`, mais
  de 3h depois da criação). Divergência UI-vs-banco não explicada — pode ter sido leitura
  equivocada da tela na rodada 89, ou um cenário real de sucesso aparente sem confirmação no
  backend. Não bloqueia a tarefa, mas é uma pendência a esclarecer antes de considerar o passo 12
  100% validado (ver histórico, rodada 93, pra detalhe).
- **Passos 13-14 (Monitor Diário do Beyond BackOffice) ainda NÃO concluídos**: bloqueados por uma
  combinação de (a) flakiness intermitente já conhecida do `cy.origin()` (spec bridge) — 3
  tentativas seguidas (91, 92, 93) falharam por isso antes de conseguir chegar na tela de login —
  e (b) um erro visto uma vez (rodada 90), ainda não confirmado como reproduzível: o Keycloak do
  realm `multiplicacapital`, quando servido pelo host `lgni.grupomultiplica.com.br` (em vez de
  `keycloak-new-2...`), rejeitou a tentativa de login com "Parâmetro inválido: redirect_uri" antes
  de mostrar o formulário. A detecção de Keycloak já foi corrigida pra reconhecer qualquer host
  (por padrão de path, não hostname fixo) — falta confirmar se o erro de `redirect_uri` é
  reproduzível de forma consistente ou foi um estado transitório.
- **Próximo passo:** continuar tentando o teste 2 (Monitor Diário) nos próximos ciclos — não é
  dúvida bloqueante (é a mesma armadilha de instabilidade de `cy.origin()` já documentada, não uma
  decisão que dependa do Thiago). Se o erro de `redirect_uri` reaparecer de forma consistente numa
  tentativa que realmente chegue na tela de login, tratar como RESULTADO (bug/config real
  bloqueando passos 13-14) em vez de continuar tentando indefinidamente.

## Execução — resumo das rodadas 94-104 (2026-09-17, histórico completo arquivado nesta data)

> Narrativa passo a passo completa (rodadas 94-104) arquivada, verbatim, em
> `20260915123730-criacao-operacao-servico.historico.md` (mesma pasta) — só abra se precisar
> reconstituir o "porquê" de alguma decisão específica. Resumo suficiente para qualquer ciclo
> retomar a partir daqui.

- Rodadas 94-97: instabilidade recorrente do `cy.screenshot()` logo após redirect em telas com
  fundo animado (armadilha já documentada, corrigida removendo os screenshots diagnósticos
  específicos); depois disso, login passou a falhar com "Usuário ou senha inválidos" nos dois
  realms (`beyondbanking-hml` e `multiplicacapital`) de forma cada vez mais frequente.
- Rodadas 98-103: dúvida bloqueante registrada (risco de aprofundar bloqueio de conta por força
  bruta insistindo no login) — tarefa ficou em `aguardando-resposta/`. **Achado sobre o script de
  sincronização**: quando há mais de uma dúvida sob o mesmo id, a pré-sincronização do
  `run-cycle.ps1` pode casar pela dúvida antiga já respondida em vez da mais recente ainda
  pendente, devolvendo a tarefa pra `executando/` incorretamente (aconteceu 6 vezes seguidas,
  rodadas 98-103) — pendência registrada em `docs/documentacao.md` e
  `CONHECIMENTO-SUPERVISORES.md` para o Supervisor corrigir o script.
- Rodada 104: Thiago autorizou nova tentativa de login ("Pode tentar de novo agora") — falhou de
  novo, AMBOS os realms, mesmo sintoma. Tratado como **RESULTADO** (não mais dúvida): credencial
  parecia rotacionada/expirada ou conta bloqueada de forma persistente, fora do escopo do
  subAgent. Veredito daquela rodada: cumprido parcialmente (passos 1-12 validados em banco nas
  rodadas 74-93; passos 13-14 bloqueados pela falha de login). Ver `## Reabertura` abaixo para a
  causa raiz real encontrada pelo Thiago (espaço em branco no `.env`).

## Reabertura (2026-09-17, decisão do Thiago)

**Causa raiz da falha de login encontrada e corrigida pelo Thiago**: havia um espaço em branco no
início do valor de `HML_MASTER_PASSWORD` no `.env` deste módulo (erro de digitação dele mesmo ao
editar o arquivo) — não é rotação/expiração de senha nem bloqueio de conta por força bruta, as duas
hipóteses levantadas na dúvida `(2)`. Corrigido diretamente no `.env`. Reabrindo a tarefa **só para
os passos 13-14** (Monitor Diário do Beyond BackOffice) — passos 1-12 continuam validados, não
refazer. Se o login voltar a falhar mesmo assim, é um problema novo, não mais este.

## 2ª Reabertura (2026-09-17, à noite, decisão do Thiago)

**Achado 1 (Franquia) corrigido pelo Thiago**: ele preencheu o `idFranquia` do usuário `automacao`
no Keycloak (raiz do achado — ver `docs/documentacao.md`, seção "Home do Beyond Banking passou a
mostrar tela de Franquia": esse campo é um claim do token JWT, lido via `SegurancaService.getValue
("idFranquia")` nos backends `mc-operacao-ms`/`mc-cedente-ms`/`mc-operacao-backoffice-ms` — sem ele
a tela de cards não aparece). Expectativa do Thiago: o fluxo normal do Beyond Banking (cards "Beyond
Comex"/"Beyond Operação Interno"/"Beyond Portal") deve voltar a aparecer. **Reabrindo só para
confirmar isso e retomar os passos 13-14.**

**Atenção — achado 2 (login "Usuário ou senha inválidos" isolado ao realm `multiplicacapital`,
Beyond BackOffice) segue SEM correção conhecida** — não foi mencionado pelo Thiago nesta reabertura.
Se o teste 2 (Monitor Diário/Beyond BackOffice) travar de novo nesse mesmo ponto, registre como
resultado (não dúvida, já é achado conhecido) e não insista tentando de novo sozinho — só o achado 1
(Franquia) tem confirmação de correção até agora.

## Execução — resumo da rodada 105-106 (2026-09-17, histórico completo arquivado nesta data)

> Narrativa completa (rodada 105-106) arquivada, verbatim, em
> `20260915123730-criacao-operacao-servico.historico.md` (mesma pasta).

- Após a correção do espaço em branco no `.env` (ver `## Reabertura` acima), retomei os passos
  13-14: estendi a spec para cobrir o Monitor Diário do Beyond BackOffice (seletores reaproveitados
  do `SupE2eAutomation`). Ao rodar (2/2 tentativas, `cypress-run-105.log`/`106.log`), apareceram
  **dois achados novos e reproduzíveis**, diferentes do problema já corrigido:
  - **Achado 1 (NOVO nesta rodada, depois corrigido pelo Thiago — ver `## 2ª Reabertura` acima)**:
    a Home do Beyond Banking parou de mostrar os 3 cards normais e passou a mostrar uma tela
    "Bem-vindo ao Beyond Banking" / "Nenhuma franquia disponível para o seu usuário" — bloqueando
    todo o fluxo de criação. Causa raiz identificada pelo Thiago: faltava o `idFranquia` do usuário
    `automacao` no Keycloak.
  - **Achado 2 (login do Beyond BackOffice, realm `multiplicacapital`, "Usuário ou senha
    inválidos")**: passou a acontecer só nesse realm (não mais nos dois), com o realm
    `beyondbanking-hml` aceitando a mesma credencial sem erro — sugerindo bloqueio isolado a esse
    realm (possível proteção de força bruta), não mais o espaço em branco do `.env` (já corrigido e
    confirmado ausente). **Ainda sem correção conhecida quando a rodada 107-108 abaixo rodou de
    novo.**
- Tratado como RESULTADO (não dúvida): veredito cumprido parcialmente, passos 13-14 continuavam
  bloqueados. Ver `## 2ª Reabertura` acima para a decisão do Thiago sobre o Achado 1.

## Execução — rodada 107-108 (2026-09-17, retomada após correção do Thiago no `idFranquia`)

- Ao iniciar o ciclo, encontrei a tarefa em `tarefas/pendentes/` (não em `executando/` como o
  ciclo esperava — mesma classe de inconsistência de sincronização já registrada nas rodadas
  98-103, desta vez a tarefa nem chegou a ser devolvida por dúvida, só não foi promovida de
  `pendentes/` para `executando/` pela pré-sincronização). Corrigi manualmente: movi o arquivo
  principal e o `.historico.md` companheiro (que também estava "preso" em
  `tarefas/aguardando-aprovacao/`, mesmo sintoma da rodada 100-101) para `tarefas/executando/`
  antes de retomar. Registrando como pendência pro Supervisor revisar o `run-cycle.ps1`.
- Tentei rodar a spec completa (`npx cypress run`) pela primeira vez após a 2ª reabertura do
  Thiago (correção do `idFranquia` no Keycloak) → **na primeira tentativa (síncrona) o comando
  ultrapassou o timeout implícito do Bash (120s) e foi movido pra segundo plano sozinho** — a
  mesma armadilha documentada na regra 5 do `AGENTE.md`, desta vez porque não passei o `timeout`
  explícito de 300000ms na chamada. Corrigi: matei a task em segundo plano, confirmei (via
  PowerShell `Get-Process`) que não sobrou nenhum processo `Cypress`/`node`/`Electron` órfão da
  pasta, e rodei de novo de forma síncrona com `timeout: 300000` — dessa vez terminou normalmente
  em ~2m28s (`cypress-run-107.log`).
- **Achado 1 (Franquia): RESOLVIDO pela correção do Thiago.** Desta vez a Home do Beyond Banking
  voltou a mostrar os 3 cards normais (confirmado pelo fluxo completo passar por "Beyond Operação
  Interno" → wizard de produto → conta pré-selecionada → Digitação → Cad Pessoa → título → Salvar
  → Gerar Operação → Confirmar, chegando até a screenshot `23-tabela-operacoes-viewport-largo`) —
  não apareceu mais a tela "Nenhuma franquia disponível para o seu usuário". O preenchimento do
  `idFranquia` no Keycloak resolveu de fato esse bloqueio.
- **Achado NOVO (bloqueia o passo 12 desta vez): a operação recém-criada não aparece na tabela
  "Operações" do Beyond Banking, apesar do toast "Operação criada com sucesso!" e de a operação
  existir de verdade no banco.** A spec seguiu o padrão já validado (`cy.get('table tbody
  tr').first()` pra pegar a operação "recém-criada"), mas a tabela continuou mostrando as mesmas 7
  operações antigas de 16/09/2026 (88677-88683) como as únicas 7 linhas (`"1-7 de 7"` no rodapé de
  paginação) — a operação criada nesta execução não está entre elas. Isso fez a spec clicar
  "Avançar" na linha errada (88683, uma operação antiga já em situação "em análise", com o ícone
  "Avançar" desabilitado — `Mui-disabled`) e falhar com `cy.click() failed because this element is
  disabled`.
  - **Confirmado em banco (não só suposição de timing/UI)**: consultei `MC_MOP_PRE_OPERACAO`
    (`SELECT TOP N ... ORDER BY id DESC`) logo após cada execução. A operação **88684**
    (`dataCadastro: 2026-09-17T18:56:09`, batendo com o horário da rodada 107) e a operação
    **88685** (`dataCadastro: 2026-09-17T19:01:08`, batendo com a rodada 108) **existem de fato no
    banco**, com `situacao=VALIDADO` e `indVirouOperacao=false` — ou seja, a pré-operação foi
    criada com sucesso no backend (o toast não mentiu), mas **nunca apareceu na listagem da tela
    "Operações"** em nenhuma das duas tentativas.
  - **Reproduzido de forma idêntica em 2/2 tentativas** (`cypress-run-107.log`,
    `cypress-run-108.log`, screenshot `23-tabela-operacoes-viewport-largo.png` idêntica nas duas
    rodadas, sempre com 88683 como primeira linha).
  - Não sei ainda se é (a) uma consequência colateral do `idFranquia` recém-configurado (ex.: a
    listagem de operações agora filtra por franquia e a operação nova ficou associada a uma
    franquia que a lista de "Operações" não está consultando), (b) um atraso de propagação maior
    que os ~5s de espera já usados (mas que sempre bastaram nas rodadas 74-93, antes do
    `idFranquia` existir), ou (c) alguma outra mudança recente do app — registrando como achado
    sem especular a causa raiz além do que os dados confirmam.
- **Achado 2 (login do Beyond BackOffice, realm `multiplicacapital`): PERSISTE, reproduzido pela
  4ª rodada seguida** (105, 106, 107, 108) desde a correção do `.env`, sempre com a mesma mensagem
  real da tela "Usuário ou senha inválidos" (confirmada no texto bruto capturado do body dentro do
  `cy.origin()`) e a URL travada em `/login-actions/authenticate`. Sem novidade em relação ao já
  documentado — não é dúvida, é o mesmo achado conhecido se repetindo.
- **Decisão**: tratando como **RESULTADO** (regra 6 do `AGENTE.md`) — o achado 1 (Franquia) foi
  resolvido de fato pela correção do Thiago (progresso real), mas um problema novo (operação
  criada não aparece na listagem) e o achado 2 (login Beyond BackOffice) já conhecido continuam
  impedindo concluir os passos 12-14. Gerando o PDF e encerrando esta rodada.

### Resultado anterior (rodadas 105-106, superado)

Histórico completo arquivado em `20260915123730-criacao-operacao-servico.historico.md` — ver
"## Resultado" no fim deste arquivo para o veredito atual.

Resumo: cumprido parcialmente — Achado 1 (Franquia) e Achado 2 (login `multiplicacapital`) bloqueando
passos 13-14, antes da 2ª reabertura do Thiago (correção do `idFranquia`). Achado 1 confirmado
resolvido na rodada 107-108 (ver `## Resultado` abaixo); Achado 2 persistiu.


## 3ª Reabertura (2026-09-17, à noite, decisão do Thiago)

**Achado 2 (login "Usuário ou senha inválidos", realm `multiplicacapital`) corrigido pelo Thiago.**
Reabrindo para retomar os passos 13-14 (Monitor Diário do Beyond BackOffice) usando qualquer
operação já confirmada em banco (88681-88683 ou as novas 88684/88685, se a listagem estiver
visível). O achado da listagem "Operações" não mostrar a operação nova (possível relação com
`idFranquia`) segue sem confirmação — se ainda bloquear o passo 12, registrar como achado
persistente, não repetir investigação do zero.

## Resultado (atualizado, rodadas 107-108, 2026-09-17)

**Veredito: cumprido parcialmente — progresso real (Achado 1 resolvido pela correção do Thiago),
mas um achado novo e o Achado 2 (já conhecido) continuam bloqueando os passos 12-14.**

- **Achado 1 (Franquia): CONFIRMADO RESOLVIDO.** A correção do Thiago (preencher `idFranquia` do
  usuário `automacao` no Keycloak) funcionou — a Home do Beyond Banking voltou a mostrar os cards
  normais ("Beyond Comex", "Beyond Operação Interno", "Beyond Portal"), e o fluxo completo de
  criação (login → seleção do cedente → wizard de produto → conta → Digitação → Cad Pessoa →
  título → Salvar → Gerar Operação → Confirmar) voltou a funcionar de ponta a ponta, com toast de
  sucesso, em 2/2 tentativas (rodadas 107 e 108).
- **Achado NOVO (bloqueia o passo 12): operação recém-criada não aparece na listagem "Operações"
  do Beyond Banking, apesar de existir de fato no banco.** Confirmado em 2/2 tentativas via consulta
  direta a `MC_MOP_PRE_OPERACAO` (não só suposição): as pré-operações **88684** e **88685** foram
  criadas com sucesso (`situacao=VALIDADO`, `dataCadastro` batendo com o horário de cada rodada),
  mas a tabela "Operações" da UI continuou mostrando só as mesmas 7 operações antigas de 16/09
  (88677-88683, "1-7 de 7" na paginação) nas duas execuções — a operação nova nunca apareceu como
  primeira linha nem em nenhuma linha visível. Isso fez a spec (que opera sobre a primeira linha da
  tabela, padrão validado nas rodadas 74-93) agir sobre uma operação antiga (88683, já "em análise"),
  cujo ícone "Avançar" está desabilitado — daí a falha `cy.click() failed because this element is
  disabled`. Causa raiz não investigada a fundo (pode ser relacionada à franquia recém-configurada
  filtrando a listagem, atraso de propagação maior que antes, ou outra mudança do app) — registrando
  só o sintoma confirmado, sem especular além disso.
- **Achado 2 (login do Beyond BackOffice, realm `multiplicacapital`): PERSISTE**, reproduzido pela
  4ª rodada consecutiva (105, 106, 107, 108) desde a correção do `.env`, sempre "Usuário ou senha
  inválidos", isolado a esse realm (o realm `beyondbanking-hml` continua aceitando a mesma
  credencial sem erro). Nenhuma novidade em relação ao já documentado.
- **Passos 13-14 (Monitor Diário): NÃO CONCLUÍDOS** — nem chegaram a ser tentados nesta rodada,
  bloqueados antes pelo Achado 2 (mesmo padrão das rodadas anteriores).
- **Relatório em PDF**: `relatorios/20260915123730-criacao-operacao-servico.pdf` (screenshots desta
  rodada mostram o fluxo completo de criação funcionando até a tela "Operações" com a operação nova
  ausente da lista, e a tela de login do Beyond BackOffice com "Usuário ou senha inválidos").
- **Achados que precisam de ação fora do escopo deste subAgent**:
  1. Confirmar com quem administra o Keycloak se o usuário `automacao` está bloqueado
     especificamente no realm `multiplicacapital` (proteção de força bruta) — mesma pendência já
     levantada nas rodadas 105-106, ainda sem confirmação/correção.
  2. Investigar por que a operação recém-criada não aparece na listagem "Operações" do Beyond
     Banking mesmo existindo no banco (`MC_MOP_PRE_OPERACAO`) — possivelmente relacionado à
     configuração de `idFranquia` recém-adicionada ao usuário `automacao`, mas precisa de alguém
     com acesso ao backend/config da aplicação para confirmar.
- **Próximo passo recomendado**: assim que o Achado 2 (login) for resolvido, os passos 13-14 podem
  ser tentados usando qualquer operação já confirmada em banco (88681-88683, indVirouOperacao=true).
  Separadamente, o achado novo (operação não aparece na listagem) merece confirmação de alguém com
  acesso a banco/backend antes de decidir se bloqueia definitivamente o passo 12 daqui pra frente ou
  foi uma instabilidade pontual das rodadas 107-108.
