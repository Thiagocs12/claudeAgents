# AGENTE — SubAgent cedente

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `../../docs/conhecimento-geral.md` (raiz do Supervisor) INTEIRO antes de começar qualquer
   tarefa — conhecimento cross-módulo, obrigatório para todo agente. Em seguida, leia
   `docs/documentacao.md` INTEIRO (conhecimento específico deste módulo).
2. Leia o `README.md` e o `CLAUDE.md` do repositório em `repo/` — eles contêm o padrão do projeto
   (arquitetura da sincronização PROD→HML, convenções, estrutura de pastas, acesso ao SQL Server
   via `cy.executarQuery`/`dbClient.cjs` etc.) e devem ser seguidos rigorosamente ao implementar a
   tarefa. Se, durante a implementação, perceber que estão desatualizados ou incompletos em relação
   ao padrão real do projeto, atualize-os como parte da tarefa.
3. Nunca trabalhe em mais de uma tarefa ativa por vez.
4. Antes de criar a branch da tarefa, dê `pull` na branch `reviewAgents` do repositório em `repo/` —
   a branch da tarefa deve partir sempre da versão mais atual já integrada.
5. Se encontrar uma tarefa já em `tarefas/executando/` ao iniciar o ciclo, **retome-a** em vez de
   ignorá-la ou recomeçar do zero: procure em `repo/` uma branch já criada para ela e continue de
   onde parou. Se um ciclo for esgotar antes de terminar a tarefa, faça commit do progresso parcial
   na branch (mesmo incompleto) para o próximo ciclo conseguir continuar. **Nunca** inicie um
   processo em segundo plano e encerre o ciclo "esperando ele terminar depois" — o processo não
   sobrevive entre ciclos. Rode comandos de investigação/teste de forma síncrona, aguardando
   terminarem, dentro do próprio ciclo. Esta tarefa em particular é grande (dezenas de tabelas,
   várias etapas) — é esperado que leve vários ciclos; commitar progresso parcial funcional (ex.:
   mapeamento de uma etapa por vez) é o caminho certo, não uma falha.
6. Ao final da tarefa, rode um autoteste sobre a sua própria implementação antes de avisar que está
   pronta.
7. Ao concluir com sucesso: commit + push da branch (incluindo eventual atualização do
   `README.md`/`CLAUDE.md` do repo feita no passo 2), deixe um aviso em
   `../../agent-master/fila-merge/pendentes/` (branch + id da tarefa) — o Agent Master faz o
   **merge direto na `reviewAgents`** depois de rodar os testes (sem PR por tarefa) — atualize
   `docs/documentacao.md` com o que foi implementado/aprendido e, se o aprendizado valer para
   qualquer módulo, registre também em `../../docs/conhecimento-geral.md` (releia antes de
   escrever) — e mova o arquivo da tarefa de `executando/` para `concluidas/`.
8. Se travar numa dúvida bloqueante (inclusive dúvida sobre qual padrão do projeto seguir, sobre
   como classificar uma tabela nova que não estava no escopo original, ou sobre qualquer coisa
   envolvendo dados de PROD/HML): registre em `duvidas.md`, mova a tarefa de `executando/` para
   `aguardando-resposta/`, e encerre o ciclo sem terminar a tarefa. **O título do bloco (`##
   <título>`) tem que ser exatamente o id da tarefa (o nome do arquivo, sem extensão) — não um
   slug descritivo.** A pré-checagem em PowerShell do `run-cycle.ps1` (seção 3.4 do `CLAUDE.md`)
   procura por esse título exato pra saber quando mover a tarefa de volta pra `pendentes/`; um
   título diferente faz a tarefa ficar presa em `aguardando-resposta/` para sempre, mesmo já
   respondida (bug real observado em 2026-09-15, corrigido manualmente — ver
   `../../docs/conhecimento-geral.md`). Se quiser um resumo legível, use um campo extra dentro do
   bloco, nunca o título. **Nunca decida sozinho** incluir
   uma tabela fora do escopo já definido na tarefa, nem mudar a lógica de "já existe → apaga e
   refaz" sem confirmação explícita.
9. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
   dúvida como respondida.
10. Nunca exponha valor de credencial/segredo (`.env`, tokens, senhas de banco) em
    `docs/documentacao.md`, `duvidas.md` ou log — só o nome da variável/artefato.
11. Produção é **somente leitura** — nunca envie uma query de escrita contra o ambiente `prod`
    (já bloqueado em código por `queryProd`/`COMANDO_DE_ESCRITA` em `dbTasks.cjs`, mas a regra de
    negócio vale mesmo antes de rodar: você só LÊ dados de PROD via SQL, nunca escreve). Escrita
    (incluindo o `DELETE` do modo "já existe → apaga e refaz") só é permitida contra HML.
12. **Cuidado redobrado com o `DELETE` em HML**: antes de apagar o cadastro de um cedente já
    existente em HML pra refazer, confirme a chave de match (CNPJ/CPF) e a ordem de exclusão
    (tabelas filhas antes das tabelas pai, respeitando as mesmas foreign keys mapeadas na tarefa) —
    um `DELETE` fora de ordem quebra por violação de FK, não corrompe dado silenciosamente; trate
    esse erro como sinal pra revisar a ordem, nunca contorne desabilitando constraint. Sempre rode
    o `DELETE`+recriação de um cedente por vez, nunca em lote sem confirmação explícita da tarefa.
13. **Economia de tokens:** ao rodar comandos que podem gerar saída grande (`npm run test:safety`,
    `npx cypress run`, `npm install --legacy-peer-deps`, consultas SQL de exploração, etc.),
    redirecione a saída para um arquivo e leia/relate só o resumo relevante — nunca despeje a saída
    bruta inteira de volta no seu contexto nem a copie pra `docs/documentacao.md`/`duvidas.md` sem
    necessidade.

## Escopo deste módulo

Ver `docs/documentacao.md` e a tarefa em `tarefas/pendentes/` (contém o escopo completo definido
com o Thiago: quais tabelas entram, quais ficam de fora, e a regra de "já existe em HML → apaga e
refaz").
