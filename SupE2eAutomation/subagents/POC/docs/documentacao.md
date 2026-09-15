# Conhecimento acumulado do módulo POC

## Tela "Novo Prospect" (`/prospeccao/form`) — mapeamento (2026-09-15, tarefa `20260915131339-criar-prospect-cedente-cnpj`)

- **Navegação:** login `master` → clicar "Beyond BackOffice" → clicar "Comercial" → o drawer só
  mostra ícones; clicar no ícone `data-testid="LoopIcon"` expande e revela o texto dos itens (mesmo
  padrão já documentado pelo módulo `mop`, reaproveitado aqui sem redescoberta) → clicar "Prospect"
  → clicar "Novo Prospect". Depois do clique em "Novo Prospect", a URL muda para
  `/prospeccao/form`, mas o app (single-spa, parcel `prospeccao`) demora para montar o formulário —
  um `cy.wait(2000)` (padrão herdado do `mop`) não é suficiente; **10s de espera após a URL mudar**
  foi o que funcionou de forma confiável durante a investigação (recomendo condicionar num
  `cy.get(...).should('be.visible')` do campo CNPJ em vez de `cy.wait` fixo na implementação final,
  para não depender de um número mágico).
- **Formulário "Nova Prospecção":**
  - Único campo habilitado inicialmente: `input[placeholder="CPF/CNPJ do Prospect"]` (id
    dinâmico tipo `mui-2`, não usar o id — usar o `placeholder`, estável).
  - `Tipo de Proposta` já vem preenchido/desabilitado como `NOVA` — não precisa de ação.
  - Botão de submit: `cy.contains('button', 'Salvar')` (existe também um botão "Cancelar" ao
    lado, não confundir).
- **Achado bloqueante:** ao contrário do que o Thiago esperou (consulta automática do CNPJ
  preenchendo o resto), preencher só o CNPJ e clicar "Salvar" dispara validação de **3 campos
  obrigatórios que continuam vazios**: `Tipo de Prospect` (select/autocomplete), `Agente Comercial`
  (autocomplete de pessoas) e `Tipo Empresa` (select `Nenhum`/`Matriz`/`Filial`). Esses 3 campos
  aparecem com classe `Mui-disabled` antes do primeiro submit e viram `Mui-error` (com texto
  "Campo Obrigatório" abaixo) depois — ou seja, eles **habilitam** após a tentativa de salvar, mas
  nunca são preenchidos automaticamente pela consulta do CNPJ. Dúvida bloqueante registrada em
  `duvidas.md` (mesmo id da tarefa) perguntando ao Thiago quais valores usar — **não inventar**.
  Opções capturadas ao vivo (podem mudar com o tempo, reconfirmar se a dúvida demorar a ser
  respondida):
  - `Tipo de Prospect`: PROSPECT, ÂNCORA, PROSPECT PESSOA FÍSICA, PROSPECT CLAIM - PF, PROSPECT
    CLAIM - PJ, FORNECEDOR RISCO SACADO, PROCESSO CLAIM, TESTE, Prospect 2, NOVA - LARCA,
    PRÉ-LIMITE, COMITÊ PERFORMADO, LIMITE HOMOLOGADO.
  - `Agente Comercial`: lista de ~26 pessoas (autocomplete), inclui uma opção literal
    `GERENTE AUTOMAÇÃO` que parece existir especificamente para uso por automação/testes.
  - `Tipo Empresa`: `Nenhum` (valor "vazio", selecionado por padrão mas conta como não
    preenchido), `Matriz`, `Filial`.
- Nenhum código de produção (Page/Etapa/Esteira/feature) foi criado ainda nesta tarefa — só
  exploração via spec descartável em `cypress/e2e/features/_scratch/` +
  `cypress/support/step_definitions/_scratch/` (ambos gitignored, ficam só localmente no clone
  deste subAgent) e capturas em `cypress/_discovery/` (também gitignored). Nada disso foi
  commitado na branch — a branch `feature/poc-criar-prospect-cedente-cnpj` segue idêntica à
  `reviewAgents`. Quando a dúvida for respondida, a implementação real (Page Object
  `NovoProspectPage`, `EtapaCriarProspectPorCnpj`, `EsteiraCriarProspectPorCnpj`, feature +
  step definitions em `poc/`) deve reaproveitar os seletores/aprendizados acima em vez de
  redescobrir do zero.
