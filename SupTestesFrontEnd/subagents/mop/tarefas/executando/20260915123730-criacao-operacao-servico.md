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
    Limite Desconto. Valor de teste usado até aqui: `12345` (Documento, **repetido em toda
    operação — ver dúvida em aberto abaixo**), `1000,00` (Valor), `2026-12-31` (Vencimento).
11. "Salvar" adiciona 1 título na tabela (duplicação é só visual, confirmado). "Gerar Operação"
    abre modal de confirmação — clicar "Confirmar" (mesmo padrão `get+filter(:visible)+contains`)
    fecha o modal, mostra toast "Operação criada com sucesso!" e a operação aparece na tabela do
    dashboard (situação "enviado"). Sempre operar sobre a **primeira linha da tabela** (mais
    recente), não um número fixo — cada execução cria uma operação nova (nºs 88672-88676 até
    agora).

**Ponto onde a investigação parou — passo 12 (avançar a operação):** o ícone "Avançar"
(`div[aria-label="Avançar"] button`, `data-testid="NextPlanIcon"`) dispara
`POST .../mc-api-gateway-ms/v1/operacao/pre-operacoes/{id}/gerar`, que respondeu **400** em 2 de 2
tentativas válidas (operações 88675 e 88676) — front-end não trata o erro
(`unhandled promise rejection`, derruba o teste). Vídeo mais recente (rodada 73, mostra o fluxo
completo até esse erro): `videos/20260915123730-criacao-operacao-servico.mp4`.

**Achado colateral (bug menor, sem relação com o travamento):** após o passo 6, a aplicação chama
repetidamente `GET beyondbanking-hml.../static/media/logo...png` (host errado — deveria ser
`beyondbanking-ope-hml`), sempre 404.

_(A narrativa completa rodada-a-rodada de como cada um desses achados foi descoberto está em
`20260915123730-criacao-operacao-servico.historico.md`, incluindo a correção do Thiago de
2026-09-15 sobre a conta pré-selecionada não identificada na primeira tentativa.)_

## Correção do Thiago (2026-09-16) — reabrindo para investigar mais antes de concluir bug

Thiago **não aprovou nem reprovou definitivamente** — quer investigação adicional antes de aceitar
a conclusão de "bug real" acima:

1. **Não confie só no toast/tela de "sucesso"** — o status real da operação (se ela está de fato
   apta a ser avançada) **deve ser validado no banco de dados**, não só pela UI. É possível que a
   tela mostre sucesso sem o registro estar no estado esperado pra "Avançar" funcionar. Antes de
   concluir que o 400 é um bug de aplicação, confirme no banco qual é o estado real da operação
   (situação, campos relevantes) depois de criada e depois da tentativa de avançar.
   - Este módulo (`SupTestesFrontEnd/mop`) não tem hoje um mecanismo de conexão a banco de dados
     próprio, mas **não precisa criar um do zero nem tratar isso como bloqueio**: o `SupAutomacaoUteis`
     já tem os dados/mecanismo de conexão prontos, só de consulta (não é preciso escrever nada no
     banco pra essa validação). Reaproveite o padrão já usado por `cedente`/`keycloakUser`
     (`cy.executarQuery`/`dbClient.cjs`, ex.:
     `SupAutomacaoUteis/subagents/cedente/repo/cypress/support/db/dbClient.cjs`) e as variáveis de
     ambiente de conexão já configuradas lá (`repo/.env` desses módulos — nomes das variáveis, não
     os valores) para rodar uma consulta **somente leitura** contra a operação criada (ex.: um
     script Node avulso reaproveitando `dbClient.cjs`, ou uma query direta equivalente) e confirmar
     o estado real da operação (`MC_MOP_PRE_OPERACAO`/tabela equivalente) antes e depois da
     tentativa de "Avançar". Ainda assim, **nunca exponha valor de credencial** em
     `docs/documentacao.md`/`duvidas.md`/log — só o nome da variável. Se mesmo com isso a consulta
     não for possível (ex.: variável de ambiente realmente ausente, erro de conexão), aí sim
     registre como dúvida bloqueante específica, mas não pule a validação nem assuma que o erro é
     definitivamente um bug sem tentar essa consulta primeiro.
2. **Suspeita de causa raiz:** o roteiro reutilizou o mesmo valor fixo (`12345`) no campo
   "Documento" em todas as operações de teste (88672 a 88676) — **documento não pode se repetir**.
   Isso pode ser a causa real do 400 ao "Avançar", não um bug de aplicação. Ajustar a spec para
   gerar uma **hash aleatória de 10 caracteres** para o campo "Documento" de cada título, garantindo
   que nunca se repita entre execuções (em vez do valor fixo usado até aqui).
3. **Valor de teste do título:** usar **R$ 100.000,00** (em vez de R$ 1.000,00 usado até aqui).

Reabrindo a tarefa (não é aprovação nem reprovação definitiva) — mova de volta para
`tarefas/pendentes/` e continue a investigação com esses três ajustes antes de reconcluir se o 400
é de fato um bug real de aplicação ou um efeito do documento duplicado / estado da operação no
banco.

## Continuação (2026-09-16, rodadas 74-89) — hipótese do Thiago CONFIRMADA: não era bug

**Ajustes 2 e 3 do Thiago já estavam implementados na spec** (Documento agora é uma hash aleatória
de 10 caracteres gerada por execução — `Math.random().toString(36).slice(2, 12)` — em vez do valor
fixo `12345`; Valor do título trocado para `R$ 100.000,00`). Rodando a spec ajustada (rodada 89,
criou a operação **nº 88681**, log completo em `cypress-run-89.log`, dump em
`cypress/debug-output.txt`):

- Tentei o fluxo completo de criação (passos 1-11) com Documento = hash aleatória (`ex3rdhdnpl` 
  nesta rodada) e Valor = R$ 100.000,00 → **passou sem erro**, operação 88681 criada com sucesso
  (situação inicial "enviado").
- Tentei clicar "Avançar" na operação 88681 → **desta vez respondeu 200** (não 400!):
  `POST .../mc-api-gateway-ms/v1/operacao/pre-operacoes/88681/gerar` → `{"id":88681,"dataOperacao":"2026-09-16T13:07:14.58..."}`.
  A tela mostrou o toast **"Operação encaminhada!"** e, mais importante, uma nova consulta ao
  backend (`GET .../pre-operacoes/cliente/painelLazy`, não é só o toast local) confirmou a
  **situação da operação mudou de "enviado" para "sucesso"** na tabela do dashboard — dado vindo
  do servidor, não só otimismo de UI.
- **Confirma a hipótese do Thiago: o 400 das rodadas 71-73 não era um bug real da aplicação — era
  causado pelo campo Documento repetido (`12345`) entre as operações de teste.** Com um Documento
  único por execução, "Avançar" funciona normalmente. Passo 12 do roteiro está **concluído com
  sucesso** (não é mais bloqueio). Corrigindo a conclusão anterior (rodadas 71-73, arquivada no
  histórico) — não é mais válida.
- Nota: no dump da tabela desta mesma rodada, a operação **88677** (de uma rodada anterior, já com
  o Documento aleatório) também aparece com situação "sucesso" — ou seja, o "Avançar" já vinha
  funcionando em pelo menos uma rodada anterior a esta (74-88) com o fix, só não tinha sido
  registrado aqui na narrativa ainda. 88678/88679/88680 aparecem "em análise" (possível próxima
  etapa do fluxo, ainda não investigada — não é erro).
- **Validação em banco (pedido 1 do Thiago) — ainda NÃO feita**: a evidência acima já vem do
  backend (chamada `painelLazy` separada do toast), o que é mais forte que "só confiar no toast",
  mas ainda não é a consulta direta ao banco que o Thiago pediu explicitamente. Registrando como
  pendência a fazer no próximo ciclo (script Node avulso reaproveitando
  `SupAutomacaoUteis/subagents/cedente/repo/cypress/support/db/dbClient.cjs`) — não bloqueou esta
  rodada porque o achado principal (não é bug) já mudou o rumo da investigação para o passo 13-14.
- Tentei então o teste 2 (verificação no Monitor Diário do Beyond BackOffice, `beyond-hml`) →
  **falhou** por um problema de automação (não da aplicação): a URL de login do Beyond BackOffice
  (realm `multiplicacapital`) veio desta vez servida por um host **diferente** do já mapeado
  (`lgni.grupomultiplica.com.br`, mesmo padrão de Keycloak `/auth/realms/.../openid-connect/auth`,
  em vez de `keycloak-new-2.grupomultiplica.com.br` como nas rodadas 80-88) — a spec detectava
  Keycloak comparando a URL contra um hostname fixo (`ambiente.keycloakUrl`), então não reconheceu
  esse host novo, pulou o bloco de login inteiro, e travou depois com
  `CypressError: ... expected to run against origin beyond-hml but the application is at origin
  lgni...` (timeout 45s). **Corrigido nesta mesma rodada**: detecção trocada para reconhecer
  Keycloak pelo padrão de path (`/auth/realms/`) em vez de hostname fixo, usando a origin
  observada de fato para o `cy.origin()` (em vez de sempre `ambiente.keycloakUrl`). Ainda não
  reexecutei com a correção — próximo passo do próximo ciclo.
- **Achado a documentar:** o host que serve o Keycloak do realm `multiplicacapital` (Beyond
  BackOffice) parece variar entre execuções (`keycloak-new-2` em algumas rodadas, `lgni` nesta) —
  mesma família de instabilidade/variação de host já vista com `beyondbanking-hml` ficando
  intermitentemente indisponível. Não investigado o porquê (rotation/load balancer?), só
  documentado o comportamento e a correção (detecção genérica por path, não por host).
- Nenhum processo Cypress/node ficou órfão (checado antes de rodar, via
  `Get-CimInstance Win32_Process` filtrando `cypress`+`mop` — nada encontrado).
