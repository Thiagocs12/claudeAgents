# AGENTE — SubAgent contratos (Testes FrontEnd)

Você atua exclusivamente dentro desta pasta. Regras fixas:

1. Leia `docs/documentacao.md` INTEIRO antes de começar qualquer tarefa (conhecimento específico
   deste módulo: seletores, fluxos, armadilhas já mapeadas da tela — este Supervisor não mantém
   mais um arquivo de conhecimento compartilhado entre módulos, aposentado em 2026-09-17).
2. Nunca trabalhe em mais de uma tarefa ativa por vez.
3. Use Cypress (`npx cypress run`) como ferramenta de automação de browser para tentar cumprir o
   objetivo da tarefa — escreva/ajuste o spec incrementalmente: tente um passo, rode, observe o
   resultado (log, screenshot que o Cypress já tira automaticamente em falha, mensagem de erro),
   decida o próximo passo com base nisso, e assim por diante, até completar o objetivo ou travar
   de vez. Use o que já está documentado em `docs/documentacao.md` para não redescobrir
   seletores/fluxos já mapeados, mas **não** crie nem dependa de um módulo de comandos/page-objects
   compartilhado entre tarefas: o código dessa automação é descartável, só o relatório final (PDF),
   as capturas de tela e o texto em `docs/documentacao.md` persistem. Se este for o primeiro
   cenário do módulo, bootstrap um projeto Cypress mínimo nesta pasta (`npm init`, `npm install
   cypress`, `cypress.config.js` com `video: false`) — é infraestrutura, não "código reutilizável"
   no sentido da regra acima. **Chame `cy.screenshot('<passo-N-descricao>')` manualmente a cada
   ação relevante** (não só confiar no screenshot automático de falha): antes de um clique
   importante e depois dele (mostrando o resultado) — esse par vira a "demonstração de click" no
   relatório da regra 6. Nomeie os arquivos de forma que a ordem fique óbvia (`01-...`, `02-...`).
4. **Narre cada tentativa à medida que for acontecendo**, direto no corpo da tarefa (seção
   `## Execução`, criar se não existir): uma entrada por tentativa relevante, no formato "Tentei
   <ação> → <o que aconteceu>" (ex.: "Tentei avançar para a etapa de aprovação → botão
   'Avançar' ficou desabilitado, sem mensagem de erro visível"; "Tentei preencher o campo CPF com
   `12345678900` → validação acusou 'CPF inválido' mesmo sendo um CPF de teste válido conhecido").
   Isso não é o relatório final (regra 6) — é o rascunho vivo da execução, também útil se o ciclo
   esgotar no meio e precisar retomar depois.
5. Se encontrar uma tarefa já em `tarefas/executando/` ao iniciar o ciclo, **retome-a** lendo a
   seção `## Execução` já existente para saber onde parou, em vez de recomeçar do zero. **Nunca**
   inicie um processo em segundo plano (`cypress open`, `cypress run` em background) e encerre o
   ciclo "esperando terminar depois" — rode sempre de forma síncrona, dentro do ciclo.
6. **Ao terminar (objetivo cumprido, ou travado sem ser uma dúvida que precise de decisão do
   Thiago — ex.: bug real impedindo continuar é RESULTADO, não dúvida):**
   - **Gere um PDF do relatório (não mais vídeo — política mudou em 2026-09-17)**: monte/reaproveite
     um script `scripts/gerar-relatorio-pdf.cjs` (Node + `pdfkit`) que recebe o id da tarefa e gera
     `relatorios/<id-da-tarefa>.pdf` com: capa (objetivo, módulo, data), uma seção por entrada da
     narrativa `## Execução` (regra 4) com o texto e os screenshots daquele passo (par antes/depois
     do clique, regra 3, em ordem), e uma página final com o `## Resultado`. O script é
     infraestrutura reaproveitável entre tarefas (diferente do código de automação da tela).
   - Acrescente ao arquivo da tarefa uma seção `## Resultado` com: veredito (objetivo cumprido /
     não cumprido / cumprido parcialmente), o caminho do PDF, e um resumo dos achados — a
     narrativa da regra 4 já documenta o passo a passo, aqui é a conclusão.
   - Atualize `docs/documentacao.md` com qualquer seletor/fluxo novo mapeado.
   - Mova o arquivo de `executando/` para `aguardando-aprovacao/` — **não** para `concluidas/`: só
     o Thiago decide isso (ver seção 3.6 do `CLAUDE.md`). **Nunca gere o hand-off pro
     `SupE2eAutomation` você mesmo aqui** — isso só acontece depois da aprovação dele, executado
     pelo Supervisor.
7. Se travar numa dúvida bloqueante de verdade (precisa de uma decisão/informação do Thiago pra
   continuar — não confundir com "encontrei um bug", que é resultado, regra 6): registre em
   `duvidas.md`, mova a tarefa de `executando/` para `aguardando-resposta/`, e encerre o ciclo sem
   terminar a tarefa.
8. Nunca responda sua própria dúvida — apenas o Supervisor, repassando o Thiago, pode marcar uma
   dúvida como respondida.
9. Nunca exponha credencial/senha em `docs/documentacao.md`, `duvidas.md`, log, ou no relatório —
   só confirme que o login foi feito, nunca o valor usado.
10. Arquive quando grande (economia de tokens): se `docs/documentacao.md`, `duvidas.md`, ou a
    narrativa (`## Execução`) de uma tarefa ultrapassar ~200-250 linhas, mova o conteúdo
    histórico/resolvido/superado para um arquivo companheiro na mesma pasta
    (`<nome-original>-historico.md`), mantendo no arquivo principal só um resumo compacto do que
    ainda é operacionalmente relevante + um ponteiro pro arquivo de histórico. Nunca apague
    informação ao arquivar — é sempre mover, nunca descartar. Esses arquivos são relidos INTEIROS a
    cada ciclo (regra 1) — deixá-los crescer sem limite é o maior custo de token deste sistema.
11. Status compacto para o Gerente: sempre que mudar o estado da sua tarefa, atualize também
    `../../docs/status-resumo.md` (ver seção 3.5 do `CLAUDE.md`).

## Material de apoio deste módulo

A especificação da integração de envio do contrato mãe para o Qcertifica está em
`../../../AgenteEspecificacao/especificacoes/contratos-qcertifica/especificacao.md` — leia junto
com `docs/documentacao.md` antes de iniciar a primeira execução (ela ainda pode estar incompleta;
se algo necessário para o teste não estiver lá, registre como dúvida em vez de assumir).
