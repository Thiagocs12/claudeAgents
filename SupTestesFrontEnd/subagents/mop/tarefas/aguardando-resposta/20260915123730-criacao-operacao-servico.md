---
id: 20260915123730-criacao-operacao-servico
modulo: mop
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-15
---

## Objetivo

Criar uma **operação de serviço** no Beyond Banking, do início ao fim do fluxo de criação, e
verificar se ela avança corretamente para a próxima etapa do processo. Este é o teste piloto do
Sup TestesFrontEnd — território novo (a tela de criação em si ainda não foi mapeada por ninguém,
ver `docs/documentacao.md`).

## Critérios de aceite

- A operação de serviço é criada com sucesso (sem erro bloqueante durante o preenchimento/submissão).
- Após a criação, a operação aparece avançada para a próxima etapa esperada do processo no Beyond
  (não basta ter sido criada — precisa confirmar visualmente/via tela que o avanço de fato
  aconteceu).
- Toda tentativa (inclusive as que não deram certo de primeira) é narrada passo a passo na seção
  `## Execução` deste arquivo.

## Ambiente / perfil de login

HML, perfil `master` (mesmo perfil já usado pelo `SupE2eAutomation` neste módulo).

## Material de apoio

- `docs/documentacao.md` deste módulo — ponto de partida (login, navegação até o dashboard
  Comercial) já mapeado pelo `SupE2eAutomation`.
- Dashboard Comercial tem cards "Operação Diária", "Operação Estruturada", "Operação Cessão",
  "Garantia" — nenhum confirmado ainda como o ponto de entrada para "operação de serviço"; parte
  da exploração desta tarefa é descobrir isso.

## Execução

- Tentei logar (`master`, HML) e navegar Home → "Beyond BackOffice" → "Comercial" → dashboard
  Comercial → sucesso de primeira, sem erro de `cy.origin()` (login funcionou de ponta a ponta).
  Screenshot `dashboard-comercial.png` confirma: cards "Operação Diária" (0), "Operação
  Estruturada" (1), "Operação Cessão" (0), "Garantia" (0) — nenhum chamado "Operação de Serviço"
  visível no dashboard em si.
- Tentei listar todo texto de botões/links/cards da tela via seletor jQuery combinado
  (`button, a, [role="button"], .MuiCard-root, [class*="card" i]`) → erro de sintaxe: o engine
  jQuery do Cypress não aceita o modificador `i` (case-insensitive) dentro de `[class*="..." i]`
  neste contexto. Corrigido removendo esse trecho do seletor combinado.
- Tentei expandir o menu lateral (ícone `LoopIcon`) → sucesso: revelou seção "Operação" com itens
  Monitor Diário, Monitor Estruturada, Monitor Cessão Fundo, Monitor XML, Monitor de Inclusão,
  **Nova Operação**, Operação Ativo, Planilha Operacional, Simular Operação. "Nova Operação" é o
  candidato mais provável ao ponto de entrada de criação.
- Tentei clicar em "Nova Operação" → navegou para `/operacao/criar`, mas o conteúdo (`<main>`)
  ficou visualmente vazio (só o watermark de loading/infinito) por ~5s. Cheguei a suspeitar de bug
  real (tela em branco), mas era só carregamento mais lento que o normal do micro-frontend: com
  ~13s de espera total a tela renderizou corretamente — "Nova Operação" / "Selecione o cedente
  para criar a operação." com um dropdown "Cedente". Nenhum erro JS (`window.onerror`/
  `unhandledrejection`) nem chamada HTTP com status ≥400 da aplicação nesse trecho (só um 404
  esperado/benigno do Keycloak em `3p-cookies/step1.html`, parte do fluxo padrão de iframe check,
  não relacionado).
- Tentei abrir o dropdown "Cedente" → sucesso: lista com ~20+ cedentes reais de HML (nomes de
  empresas/CPFs), mais um `Cliente Teste Automacao - 17.681.300/0001-86` (dedicado a testes).
  Selecionei este último para evitar usar dado de cedente real.
- Tentei prosseguir após selecionar o cedente de teste → em vez de formulário, a tela mostra um
  assistente virtual conversacional ("Beyond") num painel de chat. Cliquei no botão "Olá" para
  iniciar.
- Tentei iniciar a conversa com "Olá" (cedente = Cliente Teste Automacao) → o assistente respondeu
  bloqueando: "Nenhuma conta bancária cadastrada. Solicite o cadastro através do email:
  formalizacao@grupomultiplica.com.br". Ainda não sei se é uma limitação específica desse cedente
  de teste (sem conta bancária cadastrada em HML) ou um bloqueio geral — próximo passo é tentar
  com outro cedente da lista (um real de HML) para diferenciar as duas hipóteses antes de
  registrar como resultado final.
- (Nota: durante essa retomada, um `cy.origin()` falhou de forma intermitente uma vez ao logar —
  mesmo padrão já documentado pelo `SupE2eAutomation`, resolvido com retry no ciclo seguinte, sem
  intervenção necessária.)
- Tentei repetir o mesmo fluxo com um cedente real de HML ("AGROFOODS BRASIL ALIMENTO S/A") em vez
  do cedente de teste → confirmado: o bloqueio anterior era específico do `Cliente Teste
  Automacao` (sem conta bancária cadastrada em HML), não um bug geral do fluxo. Com este cedente,
  o assistente perguntou: "Verifiquei que sua última operação foi para o produto - AQUISICAO -
  ANTECIPACAO DE DUPLICATA - DUPLICATA - SERVICO - BOLETO. Manter o produto para esta nova
  operação?" (botões "Manter" / "Trocar") — a composição do produto já inclui "SERVICO".
- Cliquei em "Trocar" (em vez de "Manter") para ver o catálogo completo de opções de produto/tipo
  de operação, buscando uma opção explícita de "Serviço" em vez de depender do produto herdado da
  última operação desse cedente.
