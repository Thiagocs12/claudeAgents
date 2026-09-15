# Conhecimento geral do sistema (leitura obrigatória para todo agente)

Este arquivo reúne aprendizados e convenções que atravessam módulos — todo subAgent deve ler este
arquivo INTEIRO antes de iniciar qualquer ciclo, além do `docs/documentacao.md` do próprio módulo.
Se você (agente) aprender algo que outro módulo também precisaria saber, registre aqui — não só no
seu `docs/documentacao.md` local.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização, para não
perder uma edição feita por outro agente rodando em paralelo (não há lock automático entre
ciclos).

## O que é diferente aqui (vs. SupE2eAutomation / SupAutomacaoUteis)

- Sem `repo/`, sem `agent-master/`, sem branch de integração. Cada subAgent bootstrap um projeto
  Cypress mínimo na própria pasta (`npm init` + `npm install cypress`) só como ferramenta de
  execução — não é uma suíte que persiste/cresce entre tarefas.
- Toda execução gera um vídeo (`videos/<id>.mp4`) e uma narrativa passo a passo dentro do próprio
  arquivo de tarefa (seção `## Execução`), não só um veredito final.
- Toda tarefa concluída fica em `tarefas/aguardando-aprovacao/` até o Thiago decidir — nunca vai
  direto para `concluidas/`. Só depois de aprovado é que vira uma tarefa nova no
  `SupE2eAutomation` (ver `CLAUDE.md`, seção 3.5) — hand-off nunca é automático.

## Aplicação testada e ambientes

Mesma aplicação (Beyond Banking / Multiplica) que o `SupE2eAutomation` automatiza — reaproveitar
o que já está mapeado lá quando fizer sentido (ex.: fluxo de login via Keycloak). Ambiente
principal: HML.

## Credenciais / `.env`

Se precisar de credenciais de login (HML), verificar primeiro se dá para reaproveitar as mesmas
já usadas pelo `SupE2eAutomation` (ver `.env` em
`C:\Multiplica\claudeAgents\SupE2eAutomation\agent-master\repo\.env` ou na pasta de teste manual
`C:\multiplica\cypress-e2e\.env`) em vez de pedir credenciais novas ao Thiago — mas nunca copiar
esse arquivo automaticamente sem confirmar com o Supervisor primeiro (aplicação diferente de
contexto — o subAgent aqui não tem repositório próprio para guardar um `.env`, então isso deve
ficar documentado como pendência/dúvida na primeira vez que um módulo precisar disso, não
resolvido sozinho).

## Contas de Claude Code por agente

Ver `CONHECIMENTO-SUPERVISORES.md` (raiz de `C:\Multiplica\claudeAgents`) para o registro
completo. Resumo: sessão interativa deste Supervisor = `contaA`; subAgents revezam `contaA`/
`contaB` pela ordem de criação; Status Watcher = `contaB`.

## Scheduled Tasks (Windows Task Scheduler)

- `SupTestesFrontEnd-SubAgent-<modulo>`: a cada 5 minutos.
- `SupTestesFrontEnd-StatusWatcher`: a cada 15 minutos.
- Sem Agent Master — não existe uma 3ª task de integração aqui.
- Mesmos padrões de infraestrutura dos outros dois Supervisores (prompt via stdin, log em
  `stream-json`, pré-checagem em PowerShell antes de chamar `claude -p`) — ver
  `CONHECIMENTO-SUPERVISORES.md` para o detalhe e o código de referência em qualquer
  `run-cycle.ps1` já existente.
