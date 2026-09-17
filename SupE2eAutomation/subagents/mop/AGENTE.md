# AGENTE — SubAgent mop

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `../../docs/conhecimento-geral.md` (raiz do Supervisor) INTEIRO antes de começar qualquer
   tarefa — conhecimento cross-módulo, obrigatório para todo agente. Em seguida, leia
   `docs/documentacao.md` INTEIRO (conhecimento específico deste módulo).
2. Leia o `README.md` do repositório em `repo/` — ele contém o padrão do projeto (arquitetura de
   testes, convenções, estrutura de pastas etc.) e deve ser seguido rigorosamente ao implementar a
   tarefa. Se, durante a implementação, perceber que o `README.md` está desatualizado ou incompleto
   em relação ao padrão real do projeto, atualize-o como parte da tarefa.
3. Nunca trabalhe em mais de uma tarefa ativa por vez.
4. Antes de criar a branch da tarefa, dê `pull` na branch `reviewAgents` do repositório em `repo/` —
   a branch da tarefa deve partir sempre da versão mais atual já integrada.
5. Se encontrar uma tarefa já em `tarefas/executando/` ao iniciar o ciclo, **retome-a** em vez de
   ignorá-la ou recomeçar do zero: procure em `repo/` uma branch já criada para ela e continue de
   onde parou. Se um ciclo for esgotar antes de terminar a tarefa, faça commit do progresso parcial
   na branch (mesmo incompleto) para o próximo ciclo conseguir continuar. **Nunca** inicie um
   processo em segundo plano (`cypress open`, `cypress run` em background etc.) e encerre o ciclo
   "esperando ele terminar depois" — o processo não sobrevive entre ciclos (cada ciclo é uma
   execução nova e isolada). Rode comandos de investigação/teste de forma síncrona, aguardando
   terminarem, dentro do próprio ciclo.
6. Ao final da tarefa, rode um autoteste sobre a sua própria implementação antes de avisar que está
   pronta.
7. Ao concluir com sucesso: commit + push da branch (incluindo eventual atualização do `README.md`
   feita no passo 2), deixe um aviso em `agent-master/fila-merge/pendentes/` (branch + id da
   tarefa) — o Agent Master faz merge direto na `reviewAgents` (sem PR por tarefa, ver seção 3.3
   do `CLAUDE.md` do Supervisor) — atualize `docs/documentacao.md` com o que foi
   implementado/aprendido — e, se o aprendizado
   valer para qualquer módulo (não só o `mop`), registre também em
   `../../docs/conhecimento-geral.md` (releia o arquivo imediatamente antes de escrever, para não
   perder edição concorrente de outro agente) — e mova o arquivo da tarefa de `executando/` para
   `concluidas/`.
8. Se travar numa dúvida bloqueante (inclusive dúvida sobre qual padrão do projeto seguir):
   registre em `duvidas.md`, mova a tarefa de `executando/` para `aguardando-resposta/`, e encerre
   o ciclo sem terminar a tarefa.
9. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
   dúvida como respondida.
10. **Economia de tokens:** ao rodar comandos que podem gerar saída grande (`npm test`, `npm ci`/
    `npm install`, `cypress run`, etc.), redirecione a saída para um arquivo e leia/relate só o
    resumo relevante (contagem de passed/failed, a mensagem de erro específica, últimas linhas) —
    nunca despeje a saída bruta inteira de volta no seu contexto nem a copie pra
    `docs/documentacao.md`/`duvidas.md` sem necessidade.
11. **Arquive quando grande (economia de tokens):** se `docs/documentacao.md`, `duvidas.md`, ou a
    narrativa de uma tarefa ultrapassar ~200-250 linhas, mova o conteúdo histórico/resolvido/
    superado (entradas antigas já sintetizadas, dúvidas já respondidas há muito tempo, texto
    duplicado) para um arquivo companheiro na mesma pasta (`<nome-original>-historico.md`),
    mantendo no arquivo principal só um resumo compacto do que ainda é operacionalmente relevante
    + um ponteiro pro arquivo de histórico. **Nunca apague informação ao arquivar — é sempre mover,
    nunca descartar.** Esses arquivos são relidos INTEIROS a cada ciclo (regra 1) — deixá-los
    crescer sem limite é o maior custo de token deste sistema.
12. **Status compacto para o Gerente (2026-09-17):** sempre que mudar o estado da sua tarefa (mover
    entre pastas de `tarefas/`, registrar ou atualizar uma dúvida em `duvidas.md`), atualize também
    `../../docs/status-resumo.md`: releia o arquivo INTEIRO antes de escrever (evita perder edição
    concorrente de outro módulo), localize a seção `## mop` (crie se ainda não existir) e substitua
    **só o conteúdo dela** por um resumo de 1-2 frases do estado atual — ex.: "Sem tarefa ativa.",
    "Bloqueado (`duvidas.md`: `<id>`) — <resumo objetivo da pergunta>.", "Em execução (`<id>`) — <o
    que já foi feito> — falta: <o que falta>." Nunca mexa na seção de outro módulo. Isso existe pra
    o Gerente responder "status" ao Thiago sem precisar reler `duvidas.md`/`tarefas/` de todos os
    módulos a cada consulta.

## Escopo deste módulo

O módulo `mop` cobre as telas e fluxos de submissão/validação de operações do MOP (ex.: Monitor
Diário, análise de operação). Segue o mesmo padrão de arquitetura documentado no `README.md`/
`CLAUDE.md` do repositório (Pages/Etapas/Esteiras, Cucumber como camada fina), reaproveitando a
fundação de login (`LoginPage`, `cy.loginComoPerfil`) já implementada pelo módulo `geral` — não
reimplemente login, apenas use o comando já existente.
