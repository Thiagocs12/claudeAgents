## 20260911214610-monitor-diario-analisar-operacao
Status: respondida
Pergunta: Estou investigando ao vivo a tela Monitor Diário em HML (login como `master`) para a
tarefa do Monitor Diário. Depois de algumas execuções seguidas de `npx cypress run` em curto
intervalo, `cy.loginComoPerfil('master')` passou a falhar de forma consistente (3 tentativas
seguidas) com `CypressError: cy.origin() failed to create a spec bridge to communicate with the
specified origin`, logo após o redirect para `keycloak-new-2.grupomultiplica.com.br` (o mesmo
comando tinha funcionado normalmente antes, cheguei a navegar até "Monitor Diário" com sucesso).
Suspeito de rate-limit/bloqueio de bot no Keycloak de HML por múltiplos logins automatizados em
sequência rápida, mas não tenho como confirmar isso sozinho. Pode confirmar se existe algum
bloqueio/rate-limit conhecido no Keycloak de HML para o usuário `automacao`/IP da máquina, ou se é
só esperar mais tempo entre tentativas antes de eu continuar a investigação?
Resposta: Não é rate-limit — o ambiente HML provavelmente estava fora do ar naquele momento
(Thiago está verificando). Não é bloqueio permanente. Pode tentar de novo normalmente; se o login
falhar de novo do mesmo jeito, não insista em várias tentativas seguidas — registre uma nova
dúvida em vez de ficar re-tentando, mas dessa vez assumindo instabilidade pontual do ambiente, não
rate-limit.

## 20260911214610-monitor-diario-analisar-operacao
Status: respondida
Pergunta: Retomei a tarefa do Monitor Diário e tentei o cenário de descoberta (`discovery.feature`,
login como `master`) uma única vez, conforme orientado. O login falhou de novo, com exatamente o
mesmo erro de antes: `CypressError: cy.origin() failed to create a spec bridge to communicate with
the specified origin`, logo após o redirect para `keycloak-new-2.grupomultiplica.com.br` (screenshot
salvo em
`repo/cypress/screenshots/discovery.feature/Descoberta temporária de estrutura de tela (não
commitar) -- Explorar a home logada como master (failed).png`). Diferença importante desta vez: já
se passaram ~3 dias desde a última tentativa (a resposta anterior apontava para o ambiente HML
fora do ar "naquele momento", em 2026-09-11) — não parece mais compatível com "instabilidade
pontual" de um instante específico, já que o mesmo erro persiste dias depois, numa única tentativa
isolada (não em sequência rápida). Pode confirmar se o ambiente HML/Keycloak está de fato no ar e
saudável agora, ou se há algo estrutural (ex.: mudança de configuração do Keycloak, certificado,
CORS/CSP para `cy.origin`) impedindo esse login especificamente neste fluxo? Não vou tentar de novo
sozinho enquanto não houver uma pista nova.
Resposta: HML está ok agora. Pode retomar a investigação.

## 20260918104219-hand-off-criacao-operacao-servico-monitor-diario
Status: respondida
Pergunta: Implementei o fluxo completo (branch `feature/mop-criacao-operacao-servico-monitor-diario`,
já commitado): login Beyond Banking → seleção do cedente `kenerson` → "Beyond Operação Interno" →
wizard AQUISIÇÃO→ANTECIPAÇÃO DE DUPLICATA→DUPLICATA→SERVIÇO→BOLETO → título "por digitação" (CPF
de teste, Documento aleatório por execução, Valor R$ 100.000,00) → Salvar → Gerar Operação →
Confirmar. Esse trecho roda de ponta a ponta com sucesso ("Operação criada com sucesso"). O
próximo passo do roteiro (clicar "Avançar" na linha recém-criada da tabela "Operações", necessário
pra ela deixar de ser pré-operação e conseguir progredir até "Middle" no Monitor Diário) está
bloqueado: a operação recém-criada não aparece em lugar nenhum na tabela "Operações" do Beyond
Banking — nem como primeira linha, nem em nenhuma das 7 linhas visíveis (todas de 16/09/2026,
sobras de uma investigação exploratória anterior). Testei esperar 10s + `cy.reload()` da página
antes de olhar a tabela de novo e o resultado foi o mesmo (confirmei via dump das 7 linhas, nenhuma
de hoje 18/09). Isso reproduz ao vivo, agora, um achado já documentado pelo `SupTestesFrontEnd`
(`SupTestesFrontEnd/subagents/mop/docs/documentacao.md`, seção "Armadilha/achado: operação
recém-criada não aparece na listagem 'Operações' do Beyond Banking, apesar de existir no banco e
aparecendo normalmente no Monitor Diário") — só que lá esse achado foi tratado como "fora do escopo,
não bloqueia", porque a validação final da investigação exploratória usou uma operação ANTIGA já
existente em banco (`88683`, já convertida — `indVirouOperacao=true` — de antes desse bug aparecer)
em vez de uma operação nova. O hand-off que virou esta tarefa pede um teste automatizado permanente
que cria uma operação NOVA a cada execução (Documento aleatório) e a leva até "Middle" — isso exige
clicar "Avançar" numa operação que, neste ambiente agora, nunca aparece na listagem pra ser clicada.
Não tentei nenhum workaround pro bug em si (ex.: mexer direto em banco), conforme pedido no hand-off
("não implementar workaround"). Como devo proceder? Algumas opções que consigo ver, mas não decido
sozinho: (a) considerar isso um bug de produto a ser corrigido antes deste teste poder passar de
forma confiável, deixando o teste implementado porém sabidamente falho/pendente até o bug ser
corrigido; (b) o teste automatizado usar uma estratégia diferente pra encontrar/avançar a operação
(ex.: algum endpoint/API direta em vez da tabela da UI — precisaria de orientação sobre qual);
(c) alguma outra forma de contornar que eu não tenha enxergado. Branch com o progresso até aqui já
commitada (`d9843bc`), autoteste (`npx cypress run`) falha no passo "Avançar" com
`cy.click() failed because this element is disabled`.
Resposta: Se a operação está aparecendo no Monitor Diário do Beyond BackOffice (realm
`multiplicacapital`), está OK — pode finalizar. É o mesmo bug de produto já documentado pelo
`SupTestesFrontEnd` (fora do escopo, não bloqueia). Se precisar de uma operação para validar o
Monitor Diário e a nova não avançar por causa desse bug, siga o mesmo caminho que a investigação
original usou: valide com uma operação já confirmada em banco em vez de depender só da recém-criada
avançar via UI.

## 20260918104219-hand-off-criacao-operacao-servico-monitor-diario
Status: pendente
Pergunta: Implementei a decisão acima (branch `feature/mop-criacao-operacao-servico-monitor-diario`,
commit `9689008`): não tento mais clicar "Avançar" na operação recém-criada; `EtapaVerificarOperacao
MonitorDiario` agora valida duas coisas independentes no Monitor Diário — (1) a operação
recém-criada aparece na listagem, em qualquer etapa, e (2) existe alguma operação já em "Middle"
(sem depender da recém-criada chegar lá). Isso resolveu o 1º bloqueio. Mas apareceu um bloqueio
NOVO e diferente ao rodar o autoteste (`npx cypress run`) completo: depois do login/criação no
Beyond Banking funcionar de ponta a ponta, o teste tenta logar no Beyond BackOffice (2º app/origem
dentro da MESMA execução — `cy.loginComoPerfil('master')`, app default `backoffice`, chamado por
`EtapaVerificarOperacaoMonitorDiario.logar()`) e `cy.session('backoffice:master', ...)` falha
consistentemente (reproduzido de forma idêntica em 2 tentativas seguidas) com:
`(uncaught exception) Error: null. This error was thrown by a cross origin page. If you wish to
suppress this error you will have to use the cy.origin command...`, disparado logo no
`cy.visit(appBaseUrl)` de dentro do `cy.session`. Confirmei por `curl` (fora do Cypress) que
`beyond-hml`, `beyondbanking-hml` e `keycloak-new-2` respondem normal (200/200/302, <0.5s) no
momento — não é o ambiente fora do ar. Isso nunca tinha acontecido em tarefas anteriores porque
nenhuma spec anterior deste módulo logava em dois apps/origens diferentes dentro do MESMO teste —
só esta tarefa usa esse recurso (`cy.loginComoPerfil(perfil, { app })`, criado por ela mesma).
Suspeito (não confirmado) que o handler global de `uncaught:exception` em
`cypress/support/e2e.js` só é aplicado à origem "primária" do teste (a primeira visitada) — ao
trocar de app/origem no meio do teste, o Cypress trataria a excação como vinda de uma origem
cruzada e exigiria um handler escopado via `cy.origin(essaOrigem, () => cy.on('uncaught:exception',
...))`, exatamente como a própria mensagem de erro do Cypress sugere. Tentei implementar esse fix
em `cypress/support/commands.js` (dentro do `cy.session` de `cy.loginComoPerfil`, escopado só
quando a origem a visitar for diferente da atual) — mas `cy.origin()` rejeitou a chamada
(`cy.origin() requires the first argument to be a different origin than top`) já na criação da
PRIMEIRA sessão do teste (`beyondBanking:master`), antes de qualquer visita ter ocorrido (não
entendi por que o Cypress já considerava "top" como sendo essa origem nesse ponto). Ajustei a
lógica para só registrar esse handler quando a URL atual já é diferente da origem do app — com
esse ajuste, a tentativa seguinte travou por mais de 25 minutos sem nenhum progresso (nenhuma
linha nova de log, processo Electron/Cypress sem terminar) e precisei abortar manualmente; não sei
se foi o meu ajuste ou uma instabilidade pontual do ambiente/rede especificamente naquele momento
(o `curl` refeito depois do abort respondeu normal). Por segurança, revertido: `commands.js` está
de volta ao estado original, sem esse handler extra — não quis deixar uma mudança não validada no
comando de login compartilhado por todos os módulos (`cy.loginComoPerfil`) só pra resolver um
problema específico desta tarefa. Como devo proceder? Não decido sozinho porque: (a) envolve um
comando fundamental usado por todos os módulos, não só o `mop`; (b) não confirmei a causa raiz
(hipótese do handler de exceção vs. algo mais); (c) a última tentativa de investigação travou de
forma anômala e cara (25 min) sem me dar mais informação. Branch com o progresso do 1º bloqueio já
commitada e íntegra (`9689008`, sem a tentativa de fix revertida).
Resposta: Thiago decidiu abandonar esta tarefa por enquanto. Não continue investigando o
`cy.origin()`/login em duas origens. Deixe o branch como está (progresso do 1º bloqueio preservado
no commit `9689008`, sem a tentativa de fix revertida no `commands.js` compartilhado) — não
finalize, não abra aviso de merge.
