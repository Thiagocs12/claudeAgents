# Histórico arquivado — módulo POC

> Conteúdo movido de `docs/documentacao.md` (regra 11 do `AGENTE.md`, arquivo passou de ~250 linhas).
> Nada foi descartado, só movido para cá. Ver `docs/documentacao.md` para o resumo compacto
> operacional atual.

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
  fluxo de sucesso (ver bloqueio abaixo) antes de chegar lá.
- **Ainda não descoberto (nesta retomada):** a tela/rota exata da listagem de cedentes onde o
  Prospect criado deve aparecer (descoberto na retomada seguinte, ver abaixo).

### Bloqueio de conectividade com `beyond-hml.grupomultiplica.com.br` (2026-09-15)

- Ao tentar rodar o fluxo completo (login + navegação) via `cypress run`, a sessão falhou logo no
  primeiro `cy.visit(ambiente.appBaseUrl)` (antes de qualquer interação com Keycloak) com
  `Error: connect ETIMEDOUT 10.101.10.254:443`.
- Confirmado fora do Cypress: `curl -sS --max-time 20 https://beyond-hml.grupomultiplica.com.br/`
  também deu timeout de conexão. `nslookup` mostra que `beyond-hml` resolve para um IP **privado**
  (`10.101.10.254`), enquanto `keycloak-new-2` resolve para IPs públicos — ou seja, o host da
  aplicação só é alcançável dentro de alguma rede privada/VPN. Detalhe completo (recorrências
  subsequentes) em `../../docs/conhecimento-geral.md`.
- Dúvida bloqueante registrada; tarefa movida para `aguardando-resposta/`.

## Retomada (2026-09-15): dúvida da VPN respondida, mas mesmo sintoma reapareceu na tentativa seguinte

Thiago respondeu confirmando queda de VPN e autorizando retentar. Mesmo sintoma
(`connect ETIMEDOUT 10.101.10.254:443`) reapareceu na tentativa seguinte. Nova dúvida registrada.

## Retomada (2026-09-15): descoberta da listagem + implementação de produção, bloqueada no login por flake já catalogado

Com a VPN ok, rodei o fluxo completo (segundo "Salvar") via scratch
(`_scratch/explorar-prospect-sucesso.feature`) e confirmei visualmente onde o Prospect criado
aparece:

- **Redirecionamento:** após o segundo "Salvar" (com os 3 campos obrigatórios preenchidos), o app
  navega de `/prospeccao/form` para `/monitor`.
- **Listagem:** em `/monitor`, a seção "Prospecções" (tabela, a última da página) mostra o registro
  recém-criado. Colunas observadas: ID, Nome, Agente Comercial, Pleito De Limite, Aprovado Limite,
  Área, Etapa, Tempo, DOC, Data Criação, Chat, Ações. **Não há coluna de CNPJ visível** — a
  validação de sucesso usa o `Agente Comercial` (`GERENTE AUTOMAÇÃO`, valor de teste reservado para
  automação) como evidência de que o registro aparece na tabela, em vez de tentar casar pelo CNPJ.
- **Achado sobre a própria exploração (não é bug do fluxo):** a tentativa de capturar
  `document.documentElement.outerHTML` inteiro (~19MB) via `cy.writeFile` deu timeout (4000ms) e
  derrubou o teste scratch depois do fluxo já ter funcionado — corrigido na própria exploração
  capturando só a última `<table>` da página em vez do documento inteiro.
- **Flake novo observado na etapa de preencher os 3 campos obrigatórios:** logo após o primeiro
  "Salvar" (que habilita os campos), tentar clicar no autocomplete de "Tipo de Prospect" às vezes
  falha com `cy.click() failed because this element is disabled` — o `Mui-disabled` não sai
  instantaneamente. Corrigido no `NovoProspectPage` com um novo método
  `aguardarCamposObrigatoriosHabilitados()` (`should('not.be.disabled')`) chamado entre o primeiro
  `salvar()` e o preenchimento dos 3 campos, em vez de um `cy.wait` fixo.

**Implementação de produção** (commit `b804d23`, branch `feature/poc-criar-prospect-cedente-cnpj`):
`cypress/support/etapas/poc/EtapaCriarProspectPorCnpj.js` (perfil `master`; reaproveita
`NovoProspectPage` + valida via `MonitorProspectPage`) + `cypress/support/esteiras/poc/EsteiraCriarProspectPorCnpj.js`
+ `cypress/support/pages/poc/MonitorProspectPage.js` (`estaNaTelaDeListagem()` +
`prospectCriadoApareceNaListagem(agenteComercial)`) + `cypress/e2e/features/poc/poc-criar-prospect-cedente-cnpj.feature`
+ `cypress/support/step_definitions/poc/pocCriarProspectPorCnpj.js`, seguindo exatamente o padrão
já usado pelo módulo `mop` (Page/Etapa/Esteira/feature fina).

**Bloqueio no autoteste do spec de produção:** `cypress run` falhou já no login com o sintoma
já catalogado `cy.origin() failed to create a spec bridge...`. Dúvida bloqueante registrada.

## Retomada (2026-09-15): login ok, mas novo achado — campo obrigatório não sai de `Mui-disabled` mesmo após 15s; nova queda de VPN interrompeu a investigação

- `aguardarCamposObrigatoriosHabilitados()` deu timeout com o padrão de 4000ms. Aumentei para
  15000ms (commit `0138e86`) — **mesmo assim, 15s não foi suficiente**. Screenshot de falha mostra
  "Campo Obrigatório" já visível, mas o atributo/classe `disabled` do input não sai.
- Investigação adicional com spec de diagnóstico descartável (`_scratch/diagnostico-campos-habilitam.feature`
  + `diagnosticoCamposHabilitam.js`, gitignored, não commitado) interrompida por nova queda de VPN.
- Dúvida bloqueante nova registrada (cobrindo os dois pontos).

## Retomada (2026-09-15): timeout de 30s (opção a) também não resolveu — campo nunca sai de `Mui-disabled`

Aumentei o timeout de 15000ms para 30000ms (commit `9054e8b`). **Resultado: mesmo travamento, mesmo
com 30s.** Login passou sem erro de `cy.origin`. Vídeo gerado normalmente
(`cypress/videos/poc-criar-prospect-cedente-cnpj.feature.mp4`) + screenshot de falha. Como 15s e 30s
falharam da mesma forma exata, a hipótese de flake de timing perde força — bate com a alternativa
(c) (possível regressão na aplicação em hml). Nova dúvida bloqueante registrada pedindo confirmação
via vídeo/screenshot ou checagem manual.

## Retomada (2026-09-16): flake de login (`cy.origin`) recorreu de novo na 1ª tentativa, imediatamente após autorização de retry da retomada anterior

Spec de diagnóstico falhou já na 1ª tentativa com o mesmo sintoma exato, antes de qualquer
interação — nenhuma amostra nova coletada. Padrão: 2 falhas consecutivas → autorização → falha de
novo. Nova dúvida registrada perguntando se ainda é instabilidade pontual ou se justifica investigar
causa raiz.

## Retomada (2026-09-16): nova tentativa de coletar evidência (spinner/rede) bloqueada de novo pelo flake de login

Thiago respondeu (60s + revisar espera com base em carregamento assíncrono real). Antes de aplicar,
tentei coletar evidência via spec de diagnóstico — **bloqueada de novo no login**, mesmo sintoma.
Nenhum código de produção alterado. Nova dúvida registrada.

## Retomada (2026-09-16): bloqueada antes mesmo de investigar — flake de login (`cy.origin`) 2x seguidas

Estendi o spec de diagnóstico para também capturar spinners (`.MuiCircularProgress-root`,
`.MuiBackdrop-root`, `[role="progressbar"]`) e requisições em voo via `cy.intercept`. Rodei duas
vezes seguidas — as duas falharam no login com o mesmo sintoma. Parei na segunda falha. Nova dúvida
registrada perguntando se deve insistir uma 3ª vez ou se merece confirmação antes.

## Retomada (2026-09-16): ciclo interrompido antes de fazer qualquer trabalho — bug na sincronização mecânica moveu a tarefa pra `executando/` com a dúvida real ainda pendente

A última dúvida registrada (sobre insistir numa 4ª tentativa de login vs. investigar causa raiz)
continuava sem resposta (`Status: pendente`), mas esta retomada encontrou a tarefa já em
`tarefas/executando/` (movida automaticamente pela pré-checagem mecânica em PowerShell).

**Causa raiz identificada:** a função `Test-DuvidaRespondida` em `run-cycle.ps1` divide
`duvidas.md` em blocos por `## ` e, dentro do `foreach`, dá `return` no **primeiro** bloco cujo
cabeçalho bate com o id da tarefa — mas como esta tarefa já teve várias rodadas de dúvida sob o
mesmo id, o primeiro bloco encontrado é sempre o mais antigo (já respondido há dias), não o mais
recente. Resultado: uma vez que a primeira dúvida de um id é respondida, a checagem mecânica passa
a considerar esse id "respondido" para sempre, mesmo que rodadas posteriores continuem `pendente`.

**Ação tomada:** não executei nenhum passo da tarefa. Apenas movi o arquivo de volta de
`tarefas/executando/` para `tarefas/aguardando-resposta/`. Nenhum código de produção alterado.
Registrado em `../../docs/conhecimento-geral.md` para o Supervisor decidir a correção coordenada.
