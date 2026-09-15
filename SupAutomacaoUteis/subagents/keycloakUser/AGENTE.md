# AGENTE — SubAgent keycloakUser

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `../../docs/conhecimento-geral.md` (raiz do Supervisor) INTEIRO antes de começar qualquer
   tarefa — conhecimento cross-módulo, obrigatório para todo agente. Em seguida, leia
   `docs/documentacao.md` INTEIRO (conhecimento específico deste módulo).
2. Leia o `README.md` e o `CLAUDE.md` do repositório em `repo/` — eles contêm o padrão do projeto
   (arquitetura da sincronização PROD→HML, convenções, estrutura de pastas etc.) e devem ser
   seguidos rigorosamente ao implementar a tarefa. Se, durante a implementação, perceber que estão
   desatualizados ou incompletos em relação ao padrão real do projeto, atualize-os como parte da
   tarefa.
3. Nunca trabalhe em mais de uma tarefa ativa por vez.
4. Antes de criar a branch da tarefa, dê `pull` na branch `reviewAgents` do repositório em `repo/` —
   a branch da tarefa deve partir sempre da versão mais atual já integrada.
5. Se encontrar uma tarefa já em `tarefas/executando/` ao iniciar o ciclo, **retome-a** em vez de
   ignorá-la ou recomeçar do zero: procure em `repo/` uma branch já criada para ela e continue de
   onde parou. Se um ciclo for esgotar antes de terminar a tarefa, faça commit do progresso parcial
   na branch (mesmo incompleto) para o próximo ciclo conseguir continuar. **Nunca** inicie um
   processo em segundo plano e encerre o ciclo "esperando ele terminar depois" — o processo não
   sobrevive entre ciclos. Rode comandos de investigação/teste de forma síncrona, aguardando
   terminarem, dentro do próprio ciclo.
6. Ao final da tarefa, rode um autoteste sobre a sua própria implementação antes de avisar que está
   pronta.
7. Ao concluir com sucesso: commit + push da branch (incluindo eventual atualização do
   `README.md`/`CLAUDE.md` do repo feita no passo 2), deixe um aviso em
   `../../agent-master/fila-merge/pendentes/` (branch + id da tarefa) — o Agent Master faz o
   **merge direto na `reviewAgents`** depois de rodar os testes (sem PR por tarefa) — atualize
   `docs/documentacao.md`
   com o que foi implementado/aprendido e, se o aprendizado valer para qualquer módulo, registre
   também em `../../docs/conhecimento-geral.md` (releia antes de escrever) — e mova o arquivo da
   tarefa de `executando/` para `concluidas/`.
8. Se travar numa dúvida bloqueante (inclusive dúvida sobre qual padrão do projeto seguir, sobre
   qual usuário/dado copiar, ou sobre qualquer coisa envolvendo dados de PROD): registre em
   `duvidas.md`, mova a tarefa de `executando/` para `aguardando-resposta/`, e encerre o ciclo sem
   terminar a tarefa. **Nunca decida sozinho** qual usuário copiar, qual senha usar, ou assuma
   escopo de permissões além do que a tarefa especificar explicitamente.
9. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
   dúvida como respondida.
10. Nunca exponha valor de credencial/segredo (`.env`, tokens, senhas — inclusive a senha nova
    definida para o usuário clonado) em `docs/documentacao.md`, `duvidas.md`, log, ou no corpo do
    aviso pro Agent Master — só confirme que foi criada/aplicada.
11. Produção (`keycloakProd`) é **somente leitura** — nunca envie requisição não-GET para esse
    ambiente (já bloqueado em código por `validarSomenteLeituraEmProducao`, mas a regra de negócio
    vale mesmo antes de rodar: você só LÊ dados de PROD, nunca escreve).
12. **Economia de tokens:** ao rodar comandos que podem gerar saída grande (`npm run test:safety`,
    `npx cypress run`, `npm install --legacy-peer-deps`, etc.), redirecione a saída para um arquivo
    e leia/relate só o resumo relevante (contagem de passed/failed, a mensagem de erro específica,
    últimas linhas) — nunca despeje a saída bruta inteira de volta no seu contexto nem a copie pra
    `docs/documentacao.md`/`duvidas.md` sem necessidade.

## Escopo deste módulo

Ver `docs/documentacao.md`.
