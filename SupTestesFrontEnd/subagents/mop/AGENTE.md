# AGENTE — SubAgent mop (Testes FrontEnd)

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `../../docs/conhecimento-geral.md` (raiz do Supervisor) INTEIRO antes de começar qualquer
   tarefa — conhecimento cross-módulo, obrigatório para todo agente. Em seguida, leia
   `docs/documentacao.md` INTEIRO (conhecimento específico deste módulo: seletores, fluxos,
   armadilhas já mapeadas da tela).
2. Nunca trabalhe em mais de uma tarefa ativa por vez.
3. Use Cypress (`npx cypress run`) como ferramenta de automação de browser para tentar cumprir o
   objetivo da tarefa — escreva/ajuste o spec incrementalmente: tente um passo, rode, observe o
   resultado (log, screenshot que o Cypress já tira automaticamente em falha, mensagem de erro),
   decida o próximo passo com base nisso, e assim por diante, até completar o objetivo ou travar
   de vez. Use o que já está documentado em `docs/documentacao.md` para não redescobrir
   seletores/fluxos já mapeados, mas **não** crie nem dependa de um módulo de comandos/page-objects
   compartilhado entre tarefas: o código dessa automação é descartável, só o relatório final, o
   vídeo e o texto em `docs/documentacao.md` persistem. O projeto Cypress desta pasta já está
   instalado (`cypress` pinado em `15.20.1` — nunca deixe subir sozinho pra 16.x, que removeu
   `Cypress.env()`, ver `../../docs/conhecimento-geral.md`) — não reinstale do zero.
4. **Narre cada tentativa à medida que for acontecendo**, direto no corpo da tarefa (seção
   `## Execução`, criar se não existir): uma entrada por tentativa relevante, no formato "Tentei
   <ação> → <o que aconteceu>". Isso não é o relatório final (regra 6) — é o rascunho vivo da
   execução, também útil se o ciclo esgotar no meio e precisar retomar depois.
5. Se encontrar uma tarefa já em `tarefas/executando/` ao iniciar o ciclo, **retome-a** lendo a
   seção `## Execução` já existente para saber onde parou, em vez de recomeçar do zero. **Nunca**
   inicie um processo em segundo plano e encerre o ciclo "esperando terminar depois" — rode sempre
   de forma síncrona, dentro do ciclo. Isso inclui **nunca usar `ScheduleWakeup`**: este ciclo roda
   como `claude -p` de execução única (não é um `/loop` interativo) — não existe "próximo turno"
   pra um wakeup disparar, e tentar isso só faz o ciclo encerrar cedo com o `npx cypress run`
   ainda rodando solto (já aconteceu, ver `docs/documentacao.md` e `CONHECIMENTO-SUPERVISORES.md`).
   Ao chamar `npx cypress run` via Bash, **sempre passe um `timeout` explícito de pelo menos
   `300000` (5 min)** — sem isso, o Bash pode empurrar o comando pra segundo plano sozinho antes
   dele terminar (o padrão implícito não é confiável pra durações de Cypress), o que geraria
   exatamente o problema acima mesmo sem querer. Se mesmo assim um comando acabar sendo movido pra
   background, mate o processo (não deixe rodando) e rode de novo de forma síncrona antes de
   encerrar o ciclo — nunca encerre o ciclo com um processo Cypress/node ainda vivo. (Rede de
   segurança determinística: `run-cycle.ps1` também mata qualquer processo Cypress/node
   remanescente desta pasta no início e no fim de cada ciclo, mas isso é um backup — não substitui
   seguir esta regra.)
6. **Ao terminar** (objetivo cumprido, ou travado sem ser uma dúvida que precise de decisão do
   Thiago — bug real impedindo continuar é RESULTADO, não dúvida):
   - Grave um vídeo Cypress da execução relevante (`video: true` já cobre isso automaticamente em
     `npx cypress run`) e copie o `.mp4` gerado em `cypress/videos/` para
     `../videos/<id-da-tarefa>.mp4` (a pasta `videos/` é irmã de `tarefas/`, um nível acima de
     `cypress/`).
   - Acrescente ao arquivo da tarefa uma seção `## Resultado` com: veredito (objetivo cumprido /
     não cumprido / cumprido parcialmente), o caminho do vídeo, e um resumo dos achados.
   - Atualize `docs/documentacao.md` com qualquer seletor/fluxo novo mapeado (e
     `../../docs/conhecimento-geral.md` se valer para outro módulo, releia antes de escrever).
   - Mova o arquivo de `executando/` para `aguardando-aprovacao/` — **não** para `concluidas/`: só
     o Thiago decide isso. **Nunca gere o hand-off pro `SupE2eAutomation` você mesmo aqui** — isso
     só acontece depois da aprovação dele, executado pelo Supervisor.
7. Se travar numa dúvida bloqueante de verdade (precisa de uma decisão/informação do Thiago pra
   continuar — não confundir com "encontrei um bug", que é resultado, regra 6): registre em
   `duvidas.md`, mova a tarefa de `executando/` para `aguardando-resposta/`, e encerre o ciclo sem
   terminar a tarefa.
8. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
   dúvida como respondida.
9. Nunca exponha credencial/senha em `docs/documentacao.md`, `duvidas.md`, log, ou no relatório —
   só confirme que o login foi feito, nunca o valor usado. O `.env` desta pasta já tem as
   credenciais necessárias (mesmas do `SupE2eAutomation`, reaproveitadas) — nunca versione nem
   copie o conteúdo dele pra outro lugar.
10. **Arquive quando grande (economia de tokens):** se `docs/documentacao.md`, `duvidas.md`, ou a
    narrativa (`## Execução`) de uma tarefa ultrapassar ~200-250 linhas, mova o conteúdo
    histórico/resolvido/superado (rodadas antigas já sintetizadas, dúvidas já respondidas há muito
    tempo, texto duplicado) para um arquivo companheiro na mesma pasta
    (`<nome-original>-historico.md`), mantendo no arquivo principal só um resumo compacto do que
    ainda é operacionalmente relevante (seletores/padrões provados, ponto exato onde a investigação
    está, decisões já tomadas) + um ponteiro pro arquivo de histórico. **Nunca apague informação ao
    arquivar — é sempre mover, nunca descartar.** Esses arquivos são relidos INTEIROS a cada ciclo
    (regra 1) — deixá-los crescer sem limite é o maior custo de token deste sistema.

## Escopo deste módulo

Módulo **mop** — mesma área/nome usado no `SupE2eAutomation` (Comercial → Monitor Diário e fluxos
relacionados de operação). Cobre tanto validação de operações já existentes (já mapeado pelo outro
Supervisor) quanto, agora, criação de novas operações (ex.: "operação de serviço") — território
novo para este módulo especificamente, a mapear.

**Antes de explorar do zero, leia
`C:\Multiplica\claudeAgents\SupE2eAutomation\subagents\mop\docs\documentacao.md`** — o subAgent de
automação do outro Supervisor já mapeou: login (`master`) via Keycloak, navegação
Home → "Beyond BackOffice" → "Comercial" → dashboard com cards ("Operação Diária", "Operação
Estruturada", "Operação Cessão", "Garantia"), o bug conhecido do menu (`mc-menu.js`, já contornado
no `cypress/support/e2e.js` desta pasta), e seletores de tabela/menu lateral do Monitor Diário.
Isso não substitui a exploração ao vivo (a tela de criação de operação em si ainda não foi
mapeada por ninguém), mas evita redescobrir login/navegação básica do zero.
