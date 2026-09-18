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

## Execução — resumo da rodada 107-108 (2026-09-17, histórico completo arquivado em 2026-09-18)

> Narrativa completa (rodada 107-108) arquivada, verbatim, em
> `20260915123730-criacao-operacao-servico.historico.md` (mesma pasta).

- Corrigida de novo a mesma inconsistência de sincronização das rodadas 98-103 (tarefa presa em
  `pendentes/`), registrada como pendência recorrente pro Supervisor.
- **Achado 1 (Franquia): RESOLVIDO** pela correção do Thiago (`idFranquia` preenchido no Keycloak)
  — fluxo completo de criação (1-11) voltou a funcionar de ponta a ponta.
- **Achado NOVO**: operação recém-criada (88684, 88685) não aparecia na listagem "Operações" do
  Beyond Banking, apesar de confirmada em banco (`MC_MOP_PRE_OPERACAO`). Causa raiz não
  investigada a fundo nesta rodada.
- **Achado 2 (login `multiplicacapital`)**: persistia, 4ª rodada seguida.

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

### Resultado anterior (rodadas 107-108, superado)

Resumo: cumprido parcialmente — Achado 1 (Franquia) confirmado resolvido; Achado 2 (login
`multiplicacapital`) persistia pela 4ª rodada seguida, bloqueando totalmente os passos 13-14 (nem
chegaram a ser tentados); achado novo (operação recém-criada não aparecia na listagem "Operações"
do Beyond Banking, apesar de existir em banco) registrado sem causa raiz confirmada. Detalhe
completo arquivado em `20260915123730-criacao-operacao-servico.historico.md`. Achado 2 confirmado
resolvido na rodada 109-112 (ver `## Resultado` abaixo); achado da listagem "Operações" **restrito**
ao Beyond Banking — não afeta o Monitor Diário do Beyond BackOffice (ver achado extra abaixo).

## Resultado (atualizado, rodada 109-112, 2026-09-18, 3ª reabertura)

**Veredito: CUMPRIDO, sem ressalva — passos 13-14 do roteiro concluídos usando uma operação já
confirmada em banco (88683), evitando recriar uma operação nova (autorizado pelo Thiago na 3ª
reabertura).**

**Esclarecimento do Thiago (2026-09-18)**: a ressalva abaixo não procede — o critério de aceite do
passo 14 nunca foi "a UI mostrar a palavra literal 'concluída'". Quando a operação avança, o sistema
pula direto de "Inclusão OPE" para "Middle" — **a confirmação de que "Inclusão OPE" foi concluída é
justamente a operação aparecer na etapa "Middle"**. Não existe (nem deveria existir) uma tela de
histórico/linha do tempo separada para checar isso. Critério satisfeito como está.

- **Achado 2 (login do Beyond BackOffice, realm `multiplicacapital`): CONFIRMADO RESOLVIDO** pela
  correção do Thiago. O login submeteu e redirecionou para `beyond-hml.grupomultiplica.com.br` já
  autenticado como "Automacao" (confirmado por screenshot), sem a mensagem "Usuário ou senha
  inválidos" que persistia desde a rodada 105. A falha inicial desta rodada (`cypress-run-109.log`)
  foi só uma corrida de spec (diagnóstico tentando rodar dentro do `cy.origin()` depois que o
  browser já tinha navegado pra fora dele, porque o login ficou mais rápido) — corrigida removendo
  o bloco de diagnóstico não essencial; ver `## Execução` acima para o detalhe.
- **Passo 13 (localizar a operação no Monitor Diário): CONCLUÍDO.** Operação 88683 (uma das
  confirmadas em banco nas rodadas 74-93, `indVirouOperacao=true`) localizada com sucesso após
  ampliar a janela de busca para 29 dias (a janela padrão de "hoje" não cobre uma operação de
  16/09) — `cypress-run-110.log`/`112.log`, screenshot `30-linha-da-operacao-no-monitor-diario`.
- **Passo 14 (etapa "Inclusão OPE" concluída): CONCLUÍDO.** A operação 88683 mostra Etapa atual
  **"Middle"** (detalhe via `title` do chip: "Middle - Middle OPE -  Analisar Operação") — ou seja,
  avançou para além da etapa "Inclusão OPE". **Confirmado pelo Thiago que esse é exatamente o
  critério correto**: o sistema pula direto de "Inclusão OPE" para "Middle", então a operação
  aparecer em "Middle" **é** a confirmação de que "Inclusão OPE" foi concluída — não existe (nem
  deveria existir) status literal "concluída" nem tela de histórico separada para checar. Achado de
  apoio: operações mais novas (88684, 88685, criadas 17/09) aparecem nessa mesma tela com o chip
  **"Inclusão OPE"** como etapa corrente, confirmando que é uma etapa real, nomeada exatamente como
  o roteiro espera, e que 88683 já passou por ela.
- **Achado extra (contraste com o achado das rodadas 107-108)**: o achado "operação recém-criada
  não aparece na listagem Operações" é **restrito ao Beyond Banking** (app de criação) — as mesmas
  operações 88684/88685 aparecem normalmente no Monitor Diário do Beyond BackOffice. Reduz a
  hipótese de ser um problema de propagação/`idFranquia` afetando o sistema como um todo; aponta
  mais para algo específico da query/filtro da listagem "Operações" do Beyond Banking.
- **Relatório em PDF**: `relatorios/20260915123730-criacao-operacao-servico.pdf` (screenshots desta
  rodada mostram o login bem-sucedido no Beyond BackOffice, a navegação até o Monitor Diário, a
  busca ampliada, e a linha da operação 88683 com etapa "Middle").
- **Achado que precisa de ação fora do escopo deste subAgent**: investigar por que a operação
  recém-criada não aparece na listagem "Operações" do Beyond Banking mesmo existindo no banco e
  aparecendo normalmente no Monitor Diário — pendência mantida das rodadas 107-108, escopo restrito
  à listagem do Beyond Banking (não afeta o Monitor Diário/passos 13-14, já esclarecidos e
  concluídos).
- **Próximo passo**: nenhum pendente nesta tarefa — passos 13-14 concluídos e critério esclarecido
  pelo Thiago. Achado da listagem "Operações" do Beyond Banking segue como pendência separada, fora
  do escopo desta tarefa.

## Execução — rodada 109-110 (2026-09-18, 3ª reabertura: correção do Achado 2 pelo Thiago)

- Ao iniciar o ciclo, encontrei de novo a mesma classe de inconsistência de sincronização já
  registrada nas rodadas 98-108: a tarefa estava em `tarefas/pendentes/` (reaberta pelo Supervisor)
  e o `.historico.md` companheiro preso em `tarefas/aguardando-aprovacao/`, em vez de ambos em
  `tarefas/executando/`. Corrigi manualmente movendo os dois antes de retomar (mesma pendência já
  registrada pro Supervisor revisar o `run-cycle.ps1`, ver `docs/documentacao.md`).
- Tentei validar em banco quais operações confirmadas (88681-88683) ainda estão com
  `indVirouOperacao=true` antes de escolher qual usar para os passos 13-14 (evitar recriar uma
  operação nova, conforme autorizado pelo Thiago na 3ª reabertura) → `validar-operacao-db.cjs`
  confirmou 88681/88682/88683 com `indVirouOperacao=true` e linha em `MC_MOP_OPERACAO`; 88684/88685
  (criadas nas rodadas 107-108) continuam com `indVirouOperacao=false`, consistente com o achado já
  registrado (não aparecem na listagem "Operações" pra serem avançadas). `cypress/ultima-operacao.json`
  já apontava para `88683` (deixado da rodada 108) — mantive esse valor.
- Tentei rodar só o teste 2 (Monitor Diário), usando `it.only` temporário na spec pra não recriar
  operação nova (o teste 1 recriaria e esbarraria de novo no achado não resolvido da listagem, que é
  irrelevante pros passos 13-14 quando já se tem uma operação confirmada em banco) → rodou em ~26s
  (`cypress-run-109.log`) e **falhou**, mas de um jeito NOVO e bom sinal: `CypressError: ... expected
  to run against origin keycloak-new-2 but the application is at origin beyond-hml` — ou seja, o
  login **funcionou** (fez o POST de submit e o app já tinha redirecionado pra `beyond-hml` de
  verdade) e só quebrou porque um bloco de diagnóstico (`cy.wait(3000)` + `cy.get('body')` pra dump
  de texto, ainda dentro do callback do `cy.origin(keycloak-new-2...)`) rodou tarde demais, depois
  que o browser já tinha saído da origem do Keycloak. Confirmei visualmente pela screenshot de falha
  automática do Cypress: a tela mostrava a Home do Beyond (`beyond-hml.grupomultiplica.com.br`) já
  carregada, logada como "Automacao" — **Achado 2 (login "Usuário ou senha inválidos" no realm
  `multiplicacapital`) está CONFIRMADO RESOLVIDO** pela correção do Thiago.
- Corrigi a spec: removido o bloco de diagnóstico (`cy.wait(3000)` + dump de texto) de dentro do
  callback do `cy.origin()` pós-submit de login (não era essencial, só diagnóstico; screenshots e
  checagens de URL feitas fora do `cy.origin()`, mais adiante na spec, já cobrem o resultado do
  login) — evita a corrida entre o redirect (agora mais rápido, login funcionando de primeira) e o
  comando de diagnóstico.
- Rodei de novo (`cypress-run-110.log`, `it.only` temporário mantido) → **PASSOU** (55s). A operação
  88683 foi localizada no Monitor Diário (precisou ampliar a janela pra 29 dias — a janela padrão de
  hoje não a cobre, esperado pra uma operação de 16/09), com Etapa "Middle". **Passo 13 do roteiro
  CONCLUÍDO.**
- Tentei confirmar explicitamente o texto "Inclusão OPE" como "concluída" (redação literal do
  critério de aceite) → cliquei no chip da Etapa pra ver se abria um histórico/detalhe
  (`cypress-run-111.log`) → **falhou**: `cy.click() can only be called on a single element (2
  elements)` — a linha tem DOIS elementos `.mop-MuiChip-label` (um na célula "Etapa", outro na
  célula "Tempo" logo em seguida, ambas usam a mesma classe de chip). Aproveitei o `outerHTML`
  completo da linha (já dumpado antes do clique falhar) pra investigar sem clicar às cegas de novo.
- **Achado**: o chip da Etapa tem um atributo `title` mais detalhado que o texto visível — formato
  `"<Etapa> - <Sub-etapa> - <Descrição>"` (ex., pra 88683: `"Middle - Middle OPE -  Analisar
  Operação"`). Não existe a palavra literal "concluída" em lugar nenhum da linha/tabela — o Monitor
  Diário parece expor só a etapa CORRENTE (com sub-etapa/descrição), não um histórico de etapas
  passadas marcadas como concluídas. **Dado indireto forte**: a captura da tela (screenshot 30)
  mostra que operações mais novas (88684, 88685, criadas 17/09) aparecem com o chip "Inclusão OPE"
  (cinza, com ícone de "atualizar" ao lado) como etapa CORRENTE — confirma que "Inclusão OPE" é uma
  etapa real e nomeada exatamente como o roteiro espera. A 88683 (mais antiga, 16/09) já não mostra
  mais esse chip, mostra "Middle" — consistente com "Inclusão OPE" já ter sido concluída e a
  operação ter avançado além dela, mas sem uma confirmação textual explícita de "concluída" em
  lugar nenhum da UI encontrado até agora.
- Corrigi a spec pra ler a Etapa (e o `title` detalhado) da célula certa (índice 12 das `<td>`, não
  `.mop-MuiChip-label` solto na linha inteira) e rodei de novo pra confirmar
  (`cypress-run-112.log`) → **PASSOU** (55s), texto capturado: `Etapa: Middle | Detalhe (title):
  Middle - Middle OPE -  Analisar Operação`.
- **Achado extra relevante (contraste com o achado das rodadas 107-108)**: as operações 88684/88685
  (que não apareciam na listagem "Operações" do **Beyond Banking**, achado ainda não resolvido) **SIM
  aparecem normalmente no Monitor Diário do Beyond BackOffice** (visíveis na screenshot 30, chip
  "Inclusão OPE"). Isso restringe o achado anterior: o problema de visibilidade é específico da
  listagem "Operações" do app de criação (Beyond Banking), não um problema de propagação pro sistema
  de acompanhamento (Beyond BackOffice/Monitor Diário) — reduz a hipótese de ser algo relacionado ao
  `idFranquia` bloqueando a operação de "existir" no sistema como um todo.
- Reverti o `it.only` temporário (voltou a `it(...)` normal) — spec fica pronta pra rodar os dois
  testes numa retomada futura que precise recriar uma operação nova.
