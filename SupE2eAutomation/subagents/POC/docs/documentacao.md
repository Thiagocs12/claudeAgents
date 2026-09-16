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

## Retomada (2026-09-15): dúvida da VPN respondida, mas mesmo sintoma reapareceu na tentativa seguinte

Thiago respondeu a dúvida de conectividade confirmando queda de VPN (já deveria estar
reconectada) e autorizando retentar. Nesta retomada: nenhum código novo (Page Object
`NovoProspectPage` de `c36db44` segue igual, working tree limpo). Tentativa de rodar o scratch
`explorar-prospect-sucesso.feature` (segundo "Salvar" com os 3 campos preenchidos, para descobrir
onde o cedente criado aparece — critério de aceite pendente) falhou de novo com o **mesmo** erro:
`connect ETIMEDOUT 10.101.10.254:443`. Confirmado fora do Cypress com uma única tentativa de
`curl --max-time 15` (sem insistir em sequência, conforme protocolo): `beyond-hml` continua sem
conectar, `keycloak-new-2` respondeu `403` normalmente — padrão idêntico ao bloqueio original.

Nova dúvida bloqueante registrada em `duvidas.md` (mesmo id da tarefa) perguntando ao Thiago se é
nova queda de VPN ou se a reconexão anterior não se sustentou. Tarefa movida de volta para
`tarefas/aguardando-resposta/`. Registrado também em `../../docs/conhecimento-geral.md` (a
recorrência é relevante para qualquer módulo que dependa de `beyond-hml`, não só o `POC`).

**Ainda pendente para a próxima retomada** (sem mudança desde a retomada anterior): rodar o fluxo
completo (segundo "Salvar") uma vez via scratch para descobrir a tela/rota da listagem de
cedentes, depois criar `EtapaCriarProspectPorCnpj` + `EsteiraCriarProspectPorCnpj` +
feature/step_definitions em `poc/`, seguindo o padrão do módulo `mop`.

## Retomada (2026-09-15): descoberta da listagem + implementação de produção, bloqueada no login por flake já catalogado

Com a VPN ok, rodei o fluxo completo (segundo "Salvar") via scratch (`_scratch/explorar-prospect-sucesso.feature`)
e confirmei visualmente onde o Prospect criado aparece:

- **Redirecionamento:** após o segundo "Salvar" (com os 3 campos obrigatórios preenchidos), o app
  navega de `/prospeccao/form` para `/monitor` (confirmado pela barra de URL do Test Runner no
  screenshot automático de falha da exploração — ver adiante sobre por que aquela execução falhou).
- **Listagem:** em `/monitor`, a seção "Prospecções" (tabela, a última da página) mostra o registro
  recém-criado. Colunas observadas: ID, Nome, Agente Comercial, Pleito De Limite, Aprovado Limite,
  Área, Etapa, Tempo, DOC, Data Criação, Chat, Ações. **Não há coluna de CNPJ visível** — a
  validação de sucesso usa o `Agente Comercial` (`GERENTE AUTOMAÇÃO`, valor de teste reservado para
  automação) como evidência de que o registro aparece na tabela, em vez de tentar casar pelo CNPJ.
- **Achado sobre a própria exploração (não é bug do fluxo):** a tentativa de capturar
  `document.documentElement.outerHTML` inteiro (~19MB) via `cy.writeFile` deu timeout (4000ms) e
  derrubou o teste scratch depois do fluxo já ter funcionado (a falha ocorre na captura, não no
  fluxo de negócio) — corrigido na própria exploração capturando só a última `<table>` da página
  em vez do documento inteiro.
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

**Bloqueio no autoteste do spec de produção:** `cypress run` falhou já no login
(`cy.loginComoPerfil` → `cy.session`/`cy.origin`) com o sintoma **já catalogado** em
`../../docs/conhecimento-geral.md`: `cy.origin() failed to create a spec bridge to communicate with
the specified origin`. Não é um problema introduzido por este código (nenhuma mudança na fundação
de login). Seguido o protocolo já estabelecido para esse sintoma (não insistir em várias tentativas
seguidas): dúvida bloqueante registrada em `duvidas.md`, tarefa movida para
`tarefas/aguardando-resposta/`. Próxima retomada, assim que confirmado: apenas rodar
`npx cypress run --spec "cypress/e2e/features/poc/poc-criar-prospect-cedente-cnpj.feature"`
de novo (nenhum código pendente de escrever) e, se passar, seguir a regra 7 do `AGENTE.md` (push +
aviso ao Agent Master + mover tarefa para `concluidas/`).

## Retomada (2026-09-15): login ok, mas novo achado — campo obrigatório não sai de `Mui-disabled` mesmo após 15s; nova queda de VPN interrompeu a investigação

Dúvida da VPN/login respondida pelo Thiago ("instabilidade pontual, pode tentar de novo"). Nesta
retomada, confirmei conectividade com `curl` antes de rodar (`beyond-hml` OK) e o `cypress run` do
spec de produção passou do login sem repetir o `cy.origin` — mas falhou num ponto novo:

- `aguardarCamposObrigatoriosHabilitados()` (que espera `Tipo de Prospect` sair de `Mui-disabled`
  depois do primeiro "Salvar") deu timeout com o timeout **padrão** de 4000ms. Aumentei para 15000ms
  (`inputDoAutocomplete` agora aceita `options` repassadas ao `.find('input', options)`, commit
  `0138e86`, branch `feature/poc-criar-prospect-cedente-cnpj`, já pushado) — **mesmo assim, 15s não
  foi suficiente** numa nova execução: o campo continuou `disabled`, ainda que o screenshot de falha
  mostre "Campo Obrigatório" já visível embaixo de `Tipo de Prospect`/`Agente Comercial` (ou seja, o
  clique em "Salvar" registrou e dispara a validação normalmente — só o atributo/classe `disabled`
  do input não sai).
- Isso é diferente do flake leve já documentado (clique caindo no campo ainda desabilitado logo
  após o "Salvar", resolvido esperando um pouco) — aqui nem 15s de espera bastaram numa execução
  inteira. Não é possível ainda dizer se é sempre assim ou intermitente.
- Tentei uma investigação adicional com um spec de diagnóstico descartável (`cypress/e2e/features/_scratch/diagnostico-campos-habilitam.feature`
  + `cypress/support/step_definitions/_scratch/diagnosticoCamposHabilitam.js`, gitignored, **não
  commitado** — ficam no working tree local deste clone para a próxima retomada reaproveitar) que
  amostra o estado `disabled` do campo em intervalos crescentes após o "Salvar". A primeira
  tentativa falhou por um `cy.writeFile` que deu timeout em 4000ms (aumentado para 20000ms depois);
  a segunda tentativa foi interrompida por uma **nova queda de conectividade**
  (`connect ETIMEDOUT 10.101.10.254:443`, mesmo padrão já catalogado) antes de coletar dados úteis.
  Confirmado com uma única checagem via `curl` (sem insistir em sequência): `beyond-hml` de novo sem
  conectar, `keycloak-new-2` respondeu `403` normalmente.
- Dúvida bloqueante nova registrada em `duvidas.md` (mesmo id da tarefa), cobrindo os dois pontos
  (o achado do campo desabilitado além de 15s, e a nova recorrência de queda de VPN). Tarefa movida
  de volta para `tarefas/aguardando-resposta/`. A recorrência de VPN também foi registrada em
  `../../docs/conhecimento-geral.md` (mesma seção já existente sobre esse sintoma).
- **Próxima retomada:** depois de resposta do Thiago, se a orientação for calibrar o timeout, rodar
  o spec de diagnóstico (já commitado localmente como scratch, não versionado) para amostrar o
  tempo real antes de simplesmente aumentar o número às cegas. Se a VPN precisar ser reconfirmada de
  novo, seguir o mesmo protocolo já estabelecido (checagem única, aguardar confirmação).

## Retomada (2026-09-15): timeout de 30s (opção a) também não resolveu — campo nunca sai de `Mui-disabled`

Thiago respondeu a dúvida anterior confirmando opção (a): aumentar `aguardarCamposObrigatoriosHabilitados`
para 30s+ e tentar de novo (também confirmou reconexão da VPN, 3ª ocorrência). Nesta retomada:
aumentei o timeout de 15000ms para 30000ms (commit `9054e8b`, branch
`feature/poc-criar-prospect-cedente-cnpj`, já pushado), confirmei VPN ok via `curl` (`beyond-hml`
respondeu `200`) e rodei o `cypress run` do spec de produção completo.

- **Resultado: mesmo travamento, mesmo com 30s.** Login passou sem erro de `cy.origin`. O teste
  falhou no mesmo ponto de sempre: `Tipo de Prospect` continua com classe `Mui-disabled` até o
  timeout estourar (`AssertionError: Timed out retrying after 30000ms: ... not to be 'disabled'`).
  Vídeo gerado normalmente (`cypress/videos/poc-criar-prospect-cedente-cnpj.feature.mp4`,
  confirmado presente no disco) + screenshot de falha.
- **Conclusão desta retomada:** como 15s e 30s falharam da mesma forma exata (nunca chega a
  habilitar em nenhuma das duas execuções, não é "quase passou"), a hipótese de flake de timing
  perde força — bate com a alternativa (c) já levantada antes (possível regressão na aplicação em
  hml, não um problema de calibração do teste). Não insisti aumentando o timeout de novo sem
  confirmação (evitar ficar tentando às cegas, conforme já orientado). Nova dúvida bloqueante
  registrada em `duvidas.md` (mesmo id da tarefa) pedindo ao Thiago para confirmar via
  vídeo/screenshot ou checagem manual em hml se é regressão real ou se falta algum passo/estado
  prévio que o teste não está reproduzindo. Tarefa movida de volta para
  `tarefas/aguardando-resposta/`.
- **Próxima retomada:** aguardar resposta. Se confirmado que é regressão real da aplicação, não há
  ajuste possível do lado do teste — precisa virar reporte de bug para quem mantém a tela, e a
  tarefa deste módulo fica bloqueada até isso ser corrigido (ou até surgir uma orientação
  alternativa, ex.: usar outro fluxo/estado para chegar aos campos habilitados). Se o Thiago
  identificar um passo prévio faltante, seguir a orientação específica que ele der.
