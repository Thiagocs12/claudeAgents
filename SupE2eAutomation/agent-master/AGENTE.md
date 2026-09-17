# AGENTE — Agent Master

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `../docs/conhecimento-geral.md` (raiz do Supervisor) INTEIRO antes de começar qualquer
   ciclo — conhecimento cross-módulo, obrigatório para todo agente. Em seguida, leia
   `docs/documentacao.md` INTEIRO (conhecimento específico do Agent Master).
2. **Você faz merge direto (com push) na `reviewAgents` de cada tarefa aprovada nos testes — sem
   PR nem aprovação humana por tarefa.** Você **nunca** mergeia/dá push direto na `main`: o único
   ponto de revisão manual do Thiago é um **PR único e contínuo `reviewAgents → main`**, que
   você garante que existe (cria uma vez se não existir; nunca recria) e que reflete sozinho, via
   GitHub, cada commit novo pusheado na `reviewAgents`. O `GH_TOKEN` (variável de ambiente setada
   no `run-cycle.ps1`) autentica o `gh` CLI pra isso. *(Mudança de fluxo em 2026-09-14, pedido
   explícito do Thiago — antes disso cada tarefa tinha seu próprio PR aprovado manualmente; ver
   histórico na seção 3.3 do `CLAUDE.md` do Supervisor.)*
3. Garanta o PR único: rode `gh pr list --base main --head reviewAgents --state open`. Se não
   existir nenhum aberto, crie um (`gh pr create --base main --head reviewAgents --title
   "Integração contínua reviewAgents → main" --body <resumo do que está pendente de revisão>`). Se
   já existir, não mexa nele.
4. **Legado** — se houver algo em `fila-merge/aguardando-aprovacao/` (aviso de PR por tarefa do
   modelo antigo, ex.: PR #9 `feature/mop-monitor-diario-analisar-operacao`): para cada um, confira
   o status do PR com `gh pr view <branch> --json state,mergedAt,url`.
   - **MERGED**: dê `git pull origin reviewAgents` em `repo/` (o merge já aconteceu no GitHub).
     Atualize `repo/.env` se a branch trouxe variável nova (mesma lógica da regra 6). Sincronize a
     pasta de teste manual do Thiago (`C:\multiplica\cypress-e2e`) de volta para a `reviewAgents`
     (regra 7). Mova o aviso para `fila-merge/concluidos/` e registre em `docs/documentacao.md`.
   - **CLOSED** sem merge: o Thiago rejeitou o PR. Registre uma dúvida em `duvidas.md` perguntando
     o motivo/próximos passos — não decida sozinho se descarta a tarefa ou pede correção.
   - **OPEN** ainda: não faça nada com esse aviso agora — é o Thiago quem aprova/mergeia esses PRs
     antigos manualmente. Nenhum aviso novo deve passar por essa pasta a partir de agora.
5. Para cada aviso em `fila-merge/pendentes/` (fluxo normal, novo):
   - No repositório em `repo/`: busque a branch indicada e faça um merge de teste **local** contra
     `reviewAgents` para detectar conflito. Se houver conflito, resolva usando a skill
     `/resolve-conflicts` e comite a resolução **na própria branch da feature** antes de mesclar de
     verdade.
   - Atualize `repo/.env` se necessário: compare `.env.example` da
     branch com o de `reviewAgents` para achar variáveis novas. Para cada uma sem valor em
     `repo/.env`, procure o valor em `../subagents/<modulo>/docs/documentacao.md` e/ou no arquivo
     da tarefa em `../subagents/<modulo>/tarefas/concluidas/<id>.md` (seção "Material de apoio").
     Nunca invente nem deixe em branco — se não achar, é dúvida bloqueante (regra 9).
   - **Você não roda os testes da automação** (2026-09-17, pedido explícito do Thiago: o subAgent já
     rodou o autoteste antes de avisar você — regra 5 do `AGENTE.md` dele — rodar de novo aqui
     duplicaria o trabalho). Se não houver conflito, ou o conflito foi resolvido com sucesso:
     **finalize o merge de verdade e dê push direto na `reviewAgents`** (sem PR, sem esperar
     aprovação). Mova o aviso de `fila-merge/pendentes/` direto para `fila-merge/concluidos/` (nunca
     passa por `aguardando-aprovacao/` nesse fluxo).
   - Se o conflito não puder ser resolvido: trate como dúvida bloqueante
     (regra 9), desfaça o merge local (não deixe a `reviewAgents` local suja) e deixe o aviso em
     `fila-merge/pendentes/`.
6. Sincronizar `.env`: nunca invente nem deixe em branco uma variável nova — procure sempre na
   documentação do módulo de origem (ver regra 5).
7. **Depois de processar os avisos**, sincronize a pasta de teste manual do Thiago
   (`C:\multiplica\cypress-e2e`, mesmo repositório em clone separado) sempre para a `reviewAgents`
   (não há mais branch de PR-por-tarefa pra testar antes de aprovar):
   - Rode `npm ci`/`npm install` se necessário.
   - Copie/sincronize `repo/.env` do Agent Master para `.env` nessa pasta, sobrescrevendo o que
     houver. Nunca exponha o conteúdo do `.env`/token em `docs/documentacao.md`, `duvidas.md` ou
     no log de saída — só confirme que foi sincronizado.
   - Copie também `repo/relatorios/*.pdf` (se existirem, dos testes que você rodou neste ciclo —
     substituiu `cypress/videos/*.mp4` em 2026-09-17, pedido explícito do Thiago) para
     `relatorios/` dentro dessa pasta — o relatório da execução deve terminar no repositório do
     Thiago, não só ficar preso no seu próprio clone (`repo/`). Se `repo/relatorios/` ainda não
     existir (infra de PDF ainda não implementada — ver tarefa em
     `../subagents/geral/tarefas/`), não há nada pra copiar; não trate isso como dúvida.
   - Se o pull/checkout falhar (working tree suja, divergência), não force nada: registre em
     `duvidas.md`.
8. Registre em `docs/documentacao.md` tudo que foi feito no ciclo (merges feitos direto na
   `reviewAgents`, conflitos resolvidos, variáveis de `.env` novas — só o nome —, estado do PR
   único pra `main`, e o estado da sincronização da pasta de teste manual). Se o aprendizado valer
   para qualquer módulo, registre também em `../docs/conhecimento-geral.md` (releia antes de
   escrever).
9. Se não conseguir resolver um conflito, não encontrar o valor
   de uma variável de `.env` nova, um PR do legado (regra 4) for fechado sem merge, ou não
   conseguir sincronizar a pasta de teste manual: registre em `duvidas.md`, mantendo o aviso onde
   estiver (não mova para `concluidos/`).
10. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
    dúvida como respondida.
11. **Economia de tokens:** ao rodar `npm ci`/`npm install` (da pasta de teste manual do Thiago),
    redirecione a saída para um arquivo e leia/relate só o resumo relevante (últimas linhas, erro
    específico se falhar) — nunca despeje a saída bruta inteira de volta no seu contexto nem a copie
    pra `docs/documentacao.md`/`duvidas.md` sem necessidade.
12. **Arquive quando grande (economia de tokens):** se `docs/documentacao.md`, `duvidas.md`, ou o
    log de merges ultrapassar ~200-250 linhas, mova o conteúdo histórico/resolvido/superado
    (merges antigos já concluídos, dúvidas já respondidas há muito tempo) para um arquivo
    companheiro na mesma pasta (`<nome-original>-historico.md`), mantendo no arquivo principal só
    um resumo compacto do que ainda é operacionalmente relevante + um ponteiro pro arquivo de
    histórico. **Nunca apague informação ao arquivar — é sempre mover, nunca descartar.** Esses
    arquivos são relidos INTEIROS a cada ciclo (regra 1) — deixá-los crescer sem limite é o maior
    custo de token deste sistema.
13. **Status compacto para o Gerente (2026-09-17):** sempre que processar um aviso (mover entre
    `fila-merge/pendentes/`, `fila-merge/aguardando-aprovacao/`, `fila-merge/concluidos/`) ou
    registrar/atualizar uma dúvida, atualize também `../docs/status-resumo.md`: releia o arquivo
    INTEIRO antes de escrever, localize a seção `## agent-master` (crie se ainda não existir) e
    substitua **só o conteúdo dela** por um resumo de 1-2 frases — ex.: "Sem aviso pendente.",
    "Bloqueado (`duvidas.md`: `<id>`) — <resumo>.", "Processando `<branch>` — <o que falta>." Nunca
    mexa nas seções dos subAgents.
