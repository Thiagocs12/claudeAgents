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
## Retomada (2026-09-15, dúvida respondida): `NovoProspectPage` implementado, bloqueado por conectividade

Dúvida dos 3 campos obrigatórios foi respondida pelo Thiago (valores: `Tipo de Prospect` =
`PROSPECT`, `Agente Comercial` = `GERENTE AUTOMAÇÃO`, `Tipo Empresa` = `Matriz`). Nesta retomada:

- **Criado** `cypress/support/pages/poc/NovoProspectPage.js` (commit `c36db44` na branch
  `feature/poc-criar-prospect-cedente-cnpj`): `navegarAte()`, `preencherCnpj()`,
  `validarCamposNaoPreenchidosAutomaticamentePeloCnpj()` (a validação do gap pedida pelo Thiago —
  assevera que os 3 campos continuam com valor vazio logo após a consulta do CNPJ, antes de
  qualquer preenchimento manual, para acusar se esse comportamento for corrigido no futuro),
  `salvar()`, `selecionarTipoProspect()`, `selecionarAgenteComercial()`, `selecionarTipoEmpresa()`.
- **Seletores confirmados ao vivo (lendo o HTML capturado em `cypress/_discovery/`, gitignored,
  local a este clone):**
  - `Tipo de Prospect` e `Agente Comercial` são MUI Autocomplete: `input` com `id` dinâmico
    (tipo `mui-46697`, muda a cada carregamento — nunca usar o id direto). Andar via
    `label` (texto) → ancestral `[role="combobox"]` → `input` descendente. Antes da consulta do
    CNPJ resolver, o `input` vem com `disabled=""` e `value=""`; depois de clicar "Salvar" pela
    primeira vez (com os 3 campos vazios), o `disabled` some e o campo vira `Mui-error` — é só
    depois disso que dá pra interagir/selecionar uma opção.
  - `Tipo Empresa` é um MUI **Select** (não Autocomplete), com `id` **estável**
    (`#mui-component-select-tipoEmpresa`, derivado do `name="tipoEmpresa"` do campo — diferente
    dos Autocompletes, esse pode ser usado direto como seletor). Input nativo espelho:
    `input[name="tipoEmpresa"]` (útil para checar `value` sem depender do texto exibido).
  - Selecionar uma opção nos 3 campos: digitar o valor exato no input antes de escolher evita
    ambiguidade de `cy.contains` por substring (ex.: "PROSPECT" também é substring de "PROSPECT
    PESSOA FÍSICA" e "PROSPECT CLAIM - PF/PJ" na lista de `Tipo de Prospect`) — usar regex
    `^valor$` contra os itens de `[role="listbox"] li` / `.MuiAutocomplete-listbox li` /
    `.MuiMenu-list li`.
- **Etapa/Esteira/feature/step_definitions ainda não criados** — o ciclo esgotou na validação do
  fluxo de sucesso (ver bloqueio abaixo) antes de chegar lá. Próxima retomada deve criar
  `EtapaCriarProspectPorCnpj` (perfil `master`) reaproveitando este Page Object, depois
  `EsteiraCriarProspectPorCnpj` e a feature/step definitions em `poc/`, seguindo exatamente o
  padrão já usado pelo módulo `mop` (`EtapaAnalisarOperacaoMonitorDiario` /
  `EsteiraAnalisarOperacaoMonitorDiario`).
- **Ainda não descoberto:** a tela/rota exata da listagem de cedentes onde o Prospect criado deve
  aparecer (critério de aceite da tarefa) — a exploração ao vivo para descobrir isso foi
  interrompida pelo bloqueio de conectividade abaixo antes de conseguir clicar "Salvar" pela
  segunda vez (com os 3 campos já preenchidos). Retomar a partir daqui assim que a conectividade
  voltar: rodar o fluxo completo uma vez via spec descartável (`_scratch/`) e observar
  URL/tela/mensagem resultante antes de decidir se precisa virar dúvida separada para o Thiago.

### Bloqueio de conectividade com `beyond-hml.grupomultiplica.com.br` (2026-09-15)

- Ao tentar rodar o fluxo completo (login + navegação) via `cypress run`, a sessão falhou logo no
  primeiro `cy.visit(ambiente.appBaseUrl)` (antes de qualquer interação com Keycloak) com
  `Error: connect ETIMEDOUT 10.101.10.254:443`.
- Confirmado fora do Cypress: `curl -sS --max-time 20 https://beyond-hml.grupomultiplica.com.br/`
  também deu timeout de conexão (2 tentativas, mesmo resultado), enquanto
  `https://keycloak-new-2.grupomultiplica.com.br/` respondeu normalmente (`403`, mas conectou).
  `nslookup` mostra que `beyond-hml` resolve para um IP **privado** (`10.101.10.254`), enquanto
  `keycloak-new-2` resolve para IPs públicos (Cloudflare) — ou seja, o host da aplicação só é
  alcançável dentro de alguma rede privada/VPN, e algo nesse acesso está indisponível agora nesta
  máquina, mesmo com internet pública funcionando normalmente.
- **Isso é diferente dos sintomas já catalogados em `conhecimento-geral.md`** (`cy.origin() failed
  to create a spec bridge`, timeout de 60s carregando a página do Keycloak, `ResizeObserver
  loop...`) — todos esses ocorriam **depois** de alcançar a aplicação/Keycloak. Este é um bloqueio
  de conectividade **antes** de qualquer interação, ao IP interno da aplicação em si — pode indicar
  que a máquina não está numa VPN/rede que dá acesso a esse IP no momento (nenhuma outra
  documentação da máquina menciona VPN até agora). Registrado também em `conhecimento-geral.md` por
  poder afetar qualquer módulo que dependa de `beyond-hml`.
- Dúvida bloqueante registrada em `duvidas.md` (mesmo id da tarefa). Tarefa movida de volta para
  `tarefas/aguardando-resposta/`.
