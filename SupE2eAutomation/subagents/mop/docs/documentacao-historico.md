# Histórico arquivado — módulo mop

> Conteúdo movido de `documentacao.md` (regra 11 do `AGENTE.md`, arquivar quando o arquivo
> principal cresce muito) — resolvido/superado, mantido aqui só como registro, nunca descartado.

## BLOQUEIO original (achado reproduzido ao vivo, 2026-09-18): operação nova não aparece na listagem "Operações" do Beyond Banking — RESOLVIDO

> Superado pela decisão do Thiago documentada em `documentacao.md`, seção "Resolução do 1º
> bloqueio" da tarefa `20260918104219-hand-off-criacao-operacao-servico-monitor-diario". Mantido
> aqui só o texto original da investigação.

Depois de "Operação criada com sucesso", o passo seguinte do roteiro (clicar "Avançar" na linha da
operação recém-criada — necessário pra ela deixar de ser pré-operação e progredir além de "Inclusão
OPE" no Monitor Diário) não consegue achar a linha: a tabela "Operações" continuou mostrando só as
mesmas 7 linhas antigas de 16/09/2026 (sobras da investigação exploratória anterior, `88677-88683`),
mesmo depois de `cy.wait(10000)` + `cy.reload()`. O código pegava a primeira linha (assumindo "mais
recente primeiro"), que na prática é uma operação antiga já "Em Análise" com o botão "Avançar" já
desabilitado — `cy.click() failed because this element is disabled`.

Isso é a reprodução ao vivo, hoje, de um achado já documentado pelo `SupTestesFrontEnd`
(`SupTestesFrontEnd/subagents/mop/docs/documentacao.md`, "Armadilha/achado: operação recém-criada
não aparece na listagem 'Operações' do Beyond Banking, apesar de existir no banco e aparecendo
normalmente no Monitor Diário"). Lá esse achado foi tratado como "não bloqueia" porque a validação
final usou uma operação antiga já convertida em banco (`88683`) em vez de recriar uma nova — mas um
teste automatizado permanente (Documento aleatório a cada execução, por design) não tem esse atalho:
precisa de uma operação nova a cada run, e não consegue avançá-la se ela não aparece na listagem.

Dúvida registrada em `duvidas.md` (`20260918104219-...`), tarefa movida para
`tarefas/aguardando-resposta/`. Não commitei nenhum workaround pro bug em si (banco, API direta
etc.) — só o fix legítimo do bug de async/sync acima, que é independente deste bloqueio.

**Resposta do Thiago**: se a operação está aparecendo no Monitor Diário do Beyond BackOffice (realm
`multiplicacapital`), está OK — pode finalizar; é o mesmo bug de produto já documentado pelo
`SupTestesFrontEnd` (fora do escopo, não bloqueia). Se precisar validar a etapa "Middle" e a nova
não avançar por causa desse bug, usar uma operação já confirmada em banco em vez de depender só da
recém-criada avançar via UI. Implementado (ver `documentacao.md`).
