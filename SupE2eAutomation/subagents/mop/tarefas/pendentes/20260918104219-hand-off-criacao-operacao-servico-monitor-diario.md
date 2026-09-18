---
id: 20260918104219-hand-off-criacao-operacao-servico-monitor-diario
modulo: mop
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-18
---

## Descrição

Hand-off do `SupTestesFrontEnd` (aprovado pelo Thiago em 2026-09-18) — virar teste automatizado
permanente. Cenário original validado manualmente/exploratoriamente lá:
`SupTestesFrontEnd/subagents/mop/tarefas/concluidas/20260915123730-criacao-operacao-servico.md`
(ver esse arquivo para a narrativa completa de todas as rodadas de exploração, achados e
armadilhas — este resumo cobre só o essencial para implementar).

Fluxo a automatizar, de ponta a ponta:

1. Login no **Beyond Banking** (`beyondbanking-hml.grupomultiplica.com.br`, perfil `master`).
2. Selecionar o cedente **kenerson** (usar o cadastro master dele).
3. Entrar em **"Beyond Operação Interno"** → **"Criar Operação"**.
4. Navegar o wizard: **AQUISIÇÃO → ANTECIPAÇÃO DE DUPLICATA → DUPLICATA → SERVIÇO → BOLETO**.
5. Selecionar qualquer conta (pré-selecionada é aceitável).
6. Incluir a operação **"por digitação"**.
7. Em **Cad Pessoa**, consultar qualquer CPF de teste e usar como sacado.
8. Preencher **Documento** com valor único/aleatório a cada execução (documento duplicado causa
   erro 400 — achado confirmado; ver `gerarDocumentoAleatorio()` já implementado no clone do
   `SupTestesFrontEnd`) e **Valor** plausível (ex. R$ 100.000,00).
9. **Salvar** → **Gerar Operação** → **Confirmar**. Validar toast de sucesso.
10. Trocar para **Beyond BackOffice** (`beyond-hml.grupomultiplica.com.br`, realm
    `multiplicacapital`, mesmo perfil `master`) e navegar até **Monitor Diário**
    (`pathname === '/mop/monitor'`).
11. Buscar a operação recém-criada pelo número (1ª coluna "Op." da tabela). Se não aparecer na
    janela de data padrão ("hoje"), ampliar para 29 dias (técnica: setter nativo do protótipo de
    `HTMLInputElement` no `input[type="date"]`, `.val()` do jQuery não dispara `onChange` de input
    controlado por React — já implementado nos dois clones).
12. **Critério de aceite final**: a operação deve aparecer na tabela do Monitor Diário com a coluna
    **Etapa** (chip `.mop-MuiChip-label`, cuidado: a linha tem DOIS chips com essa classe — o da
    coluna "Etapa" e outro na coluna "Tempo" logo depois; escopar pela célula/índice certo, não usar
    seletor solto) mostrando **"Middle"** (ou etapa posterior). **Confirmado pelo Thiago
    explicitamente**: não existe status literal "concluída" para a etapa "Inclusão OPE" nem tela de
    histórico separada — o sistema pula direto de "Inclusão OPE" para "Middle", então a operação
    aparecer em "Middle" **é** a própria confirmação de que "Inclusão OPE" foi concluída. Não
    procurar nenhuma outra evidência além dessa.

## Critérios de aceite

- Fluxo completo (passos 1-9) roda de ponta a ponta sem intervenção manual, com autoteste
  (`npx cypress run`) confirmando.
- Operação criada é localizada no Monitor Diário do Beyond BackOffice (passos 10-11).
- Etapa da operação no Monitor Diário é **"Middle"** (ou posterior) — esse é o critério de sucesso
  final, não um status "concluída" literal.
- Seguir o padrão de arquitetura do repositório (Page Object, Etapa/Esteira, camada fina de
  Cucumber) já usado pelos outros módulos deste Supervisor.

## Achados/armadilhas conhecidas (reaproveitar, não redescobrir)

- Login Beyond Banking × Beyond BackOffice usa realms diferentes do Keycloak
  (`beyondbanking-hml` × `multiplicacapital`) — ambos já confirmados funcionando (correção de
  credencial feita pelo Thiago em 2026-09-17/18).
- Screenshots automáticos do Cypress em telas com fundo animado derrubam o runner logo após
  redirects — armadilha já conhecida e contornada no clone do `SupTestesFrontEnd` (evitar
  `cy.screenshot()` imediatamente após `cy.visit()`/redirect).
- **Achado separado, fora do escopo desta tarefa** (não bloqueia, não implementar workaround):
  operações recém-criadas às vezes não aparecem na listagem "Operações" do próprio Beyond Banking
  (mesmo existindo no banco e aparecendo normalmente no Monitor Diário) — se acontecer durante a
  implementação, registrar como achado, não tentar resolver aqui.

## Material de apoio

- Tarefa original (narrativa completa, screenshots, PDF):
  `SupTestesFrontEnd/subagents/mop/tarefas/concluidas/20260915123730-criacao-operacao-servico.md`
- Spec Cypress de referência (exploratório, não é pra copiar direto — mas mapeia todos os
  seletores/fluxo já validados):
  `SupTestesFrontEnd/subagents/mop/cypress/e2e/criacao-operacao-servico.cy.js`
- `docs/documentacao.md` do `SupTestesFrontEnd/subagents/mop` — seletores do Monitor Diário e da
  tela de criação de operação, todos confirmados ao vivo.
