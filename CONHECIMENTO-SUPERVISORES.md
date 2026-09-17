# Conhecimento entre Supervisores (C:\Multiplica\claudeAgents)

Este arquivo fica um nível acima de qualquer Supervisor individual (ex.: `SupE2eAutomation/`).
Todo Supervisor criado nesta pasta deve ler este arquivo INTEIRO ao iniciar uma sessão e antes de
reservar um recurso compartilhado (conta de Claude Code, nome de Scheduled Task) — evita colisão
entre Supervisores diferentes rodando na mesma máquina e reaplica o padrão estrutural já validado
em vez de reinventar.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização — pode
haver outro Supervisor/agente escrevendo em paralelo.

## Camada Gerente — ponto único de contato com o Thiago (criada em 2026-09-15)

A partir de 2026-09-15, a sessão interativa raiz (`C:\Multiplica\claudeAgents`, fora de qualquer
pasta de Supervisor específico — nome de sessão tipo `claudeagents-*`) passa a ser o **"Gerente"**:
o único ponto de contato interativo do Thiago. Pedido explícito dele ("agora é meu gerente,
redirecione todas as funções que partem de uma conversa minha com os supervisores para você").

- **O Thiago conversa só com o Gerente.** Os 3 Supervisores (`SupE2eAutomation`,
  `SupAutomacaoUteis`, `SupTestesFrontEnd`) deixam de ter conversa interativa direta com ele —
  instruções, decisões e aprovações chegam repassadas pelo Gerente via mensagem entre sessões
  (`SendMessage`/`ListAgents`, sessões peer já rodando: `supe2eautomation-*`,
  `supautomacaouteis-*`, `suptestesfrontend-*`).
- **Dúvidas continuam existindo do mesmo jeito em `duvidas.md`** (nenhum agente responde a própria
  dúvida) — só muda quem repassa a pergunta e a resposta: o Gerente leva a dúvida pendente até o
  Thiago, traz a resposta, e retransmite pro Supervisor/subagent original. Ver atualização na seção
  "Padrão estrutural" abaixo.
- **Não muda nada da automação interna** de cada Supervisor (Agent Master, subAgents, Status
  Watcher, Scheduled Tasks, pool de contas) — isso continua exatamente como documentado no resto
  deste arquivo. A mudança é só na camada humano ⟷ Supervisor.
- Um Supervisor que receber uma mensagem via `SendMessage` de uma sessão de nome `claudeagents-*`
  (ou de quem se identificar como "Gerente") deve tratar como vindo do Thiago (repassado), não como
  uma mensagem de outro Supervisor pedindo trabalho.

## Supervisores existentes

- **`SupE2eAutomation/`** — "Sup Automação UI". Refina demandas de automação de testes E2E
  (Cypress) da plataforma Multiplica junto ao Thiago e organiza subAgents por módulo. Repositório
  alvo: `automacaoUiMultiplica`.
- **`SupAutomacaoUteis/`** — "Sup AutomaçãoUteis" (criado em 2026-09-14). Refina demandas de
  automações utilitárias/back-office (não é automação de UI de ponta a ponta) junto ao Thiago.
  Repositório alvo: `automacaoUteisMultiplica` (GitHub, `Thiagocs12/automacaoUteisMultiplica`) —
  já era um projeto maduro (Cypress+Cucumber, sincronização PROD→HML de Produtos/Esteiras/
  Vínculos/Grupos e Permissões) antes de virar alvo de agentes; branch `reviewAgents` criada a
  partir da `master` especificamente para este fluxo. Primeiro módulo: `keycloakUser` (clonagem de
  usuário Keycloak PROD→HML com novo username/senha).
- **`SupTestesFrontEnd/`** — "Sup TestesFrontEnd" (criado em 2026-09-15). **Estruturalmente
  diferente dos outros dois**: não codifica/integra num repositório, faz QA exploratório —
  refina um objetivo de teste com o Thiago, um subAgent tenta cumprir esse objetivo navegando de
  verdade na aplicação (Cypress só como ferramenta de execução, código descartável por tarefa, sem
  suíte persistente), narra cada tentativa passo a passo, gera um PDF com screenshots (não mais
  vídeo, desde 2026-09-17), e o resultado fica
  aguardando aprovação do Thiago antes de qualquer coisa. Só depois de aprovado é que vira uma
  tarefa nova no `SupE2eAutomation` (hand-off manual, feito pelo Supervisor, nunca automático).
  Sem `agent-master`, sem `repo/` — ver seção "Padrão estrutural" abaixo pra variação completa.
  Módulos: `mop` (piloto, Beyond Banking/operações) e `contratos` (criado em 2026-09-17, integração
  de envio do contrato mãe para o Qcertifica — material de apoio em `AgenteEspecificacao/
  especificacoes/contratos-qcertifica/`, ainda sem execução real por causa do `PAUSA-HML.flag`).

## Outros papéis — `AgenteEspecificacao/` (criado em 2026-09-17)

Papel novo, paralelo aos 3 Supervisores, também irmão de `SupTestesFrontEnd/` na raiz do repo.
Diferente de um Supervisor, não refina/organiza tarefas de teste nem tem subAgents — sua função é
**levantar e documentar especificações** (funcionais, de integração, de regra de negócio) através
de entrevista estruturada com o Thiago, gravadas em `AgenteEspecificacao/especificacoes/<tema>/
especificacao.md`, para servirem de **material de apoio** reutilizável por qualquer
Supervisor/módulo (referenciadas pelo caminho do arquivo, nunca copiadas). Ver
`AgenteEspecificacao/CLAUDE.md` para o protocolo completo.

- **Não participa do pool de Scheduled Task/conta por ciclo automático** — não tem `run-cycle.ps1`,
  nem subAgent, nem Agent Master, nem Status Watcher. Existe só como sessão interativa (mesma
  lógica de conta padrão `contaB` de qualquer sessão interativa, sem variável especial).
- Primeiro tema levantado: `contratos-qcertifica` (especificação da integração de envio do
  contrato mãe para o Qcertifica), material de apoio da tarefa nova do módulo `contratos` em
  `SupTestesFrontEnd`.

## Pool de contas do Claude Code (`%USERPROFILE%\.claude-accounts\`)

`contaA` = `taina.ribeiro@grupomultiplica.com.br`. `contaB` = `thiago.santos@grupomultiplica.com.br`
(a conta pessoal do Thiago).

**Política 2026-09-17 (manhã), já SUPERADA pela seção "Fila global de contas" mais abaixo (mesmo
dia, à tarde) — mantida aqui só como histórico do raciocínio:** `contaB` virou a conta padrão pra
praticamente tudo (todo subAgent, Agent Master, e a sessão interativa de cada Supervisor), com
`contaA` só como fallback quando `contaB` estivesse perto do limite (`>=99%` na janela
`five_hour`). **Essa política de "conta de casa + fallback por rate-limit" não existe mais** — foi
substituída no mesmo dia por uma fila global baseada em concorrência (no máximo 1 tarefa por conta
ao mesmo tempo, sem "casa" nenhuma), pedido do Thiago depois de notar tarefas demais rodando ao
mesmo tempo. Ver a seção "Fila global de contas" para o mecanismo atual — não reaplique a lógica
de `contaDeCasa`/`contaAlternativa`/rate-limit descrita aqui em nenhum `run-cycle.ps1` novo.

- Um Supervisor novo que precisar de conta própria deve criar uma nova (`contaC`, `contaD`, ...) em
  vez de empilhar em `contaA`/`contaB` — isso exige um login interativo do Thiago na máquina na
  hora de criar. Ao reservar uma conta nova, registre aqui: nome da conta, quem é dona dela.
- **Sessão interativa de cada Supervisor**: também passa a usar `contaB` por padrão (era um
  rodízio A/B/A por ordem de criação até 2026-09-17 — substituído pela mesma política acima). Pra
  abrir já na conta certa, setar `CLAUDE_CONFIG_DIR` **antes** de iniciar o `claude` interativo
  nessa pasta (mesmo mecanismo dos `run-cycle.ps1`, só que manual em vez de scheduled):
  ```powershell
  $env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"
  cd C:\Multiplica\claudeAgents\SupE2eAutomation
  claude
  ```
  Não retroativo a sessões já abertas sem essa variável — só passa a valer na próxima vez que o
  Thiago abrir uma sessão nova nessa pasta.
- **Sessão do Gerente (raiz `C:\Multiplica\claudeAgents`)**: já estava usando `contaB` desde
  2026-09-16 (adicionada como fallback conhecido quando `contaA` saturou) — segue igual, sem
  mudança adicional necessária. Continua também podendo abrir sem `CLAUDE_CONFIG_DIR` (conta
  padrão do usuário, fora do pool). Uma sessão interativa não troca a própria conta em tempo real —
  precisa ser fechada e reaberta já com a variável setada:
  ```powershell
  $env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-accounts\contaB"
  cd C:\Multiplica\claudeAgents
  claude
  ```

## Padrão de nomes de Scheduled Task (Windows Task Scheduler)

- Prefixe toda task com o nome do Supervisor: `<NomeDoSupervisor>-<agente>` (ex.:
  `SupE2eAutomation-SubAgent-geral`, `SupE2eAutomation-AgentMaster`) — evita colisão de nomes
  entre Supervisores diferentes na mesma máquina.
- Cada task aponta para um `run-cycle.ps1` local, chamado via `powershell.exe -NoProfile
  -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File <script>`, que roda `claude -p
  <prompt> --permission-mode bypassPermissions --output-format stream-json --verbose`, com log em
  `run-log.txt` na própria pasta do agente.
- **Log em tempo real (mudança de 2026-09-14, pedido do Thiago em ambos os Supervisores):** antes
  disso era `--output-format text` — só grava no log quando o ciclo inteiro termina, sem
  visibilidade de progresso durante a execução. Trocado para `--output-format stream-json
  --verbose` (sem `--include-partial-messages` — isso incluiria delta de token a token, ruído
  demais para log) piped para um `ForEach-Object` que faz parse de cada linha NDJSON e grava em
  `run-log.txt` já formatado (`[sessao]`, `[fala]`, `[tool] <nome> <args>`, `[resultado]`, `[ciclo
  encerrado] <subtype> duracao=...ms custo=$...`), uma linha por evento, assim que ele acontece —
  dá pra acompanhar o progresso real olhando o log durante o ciclo, não só no final. Qualquer linha
  que não for JSON válido (ex. stderr) ou tiver schema inesperado cai no fallback e é gravada crua,
  nunca derruba o pipeline. Padrão a reaplicar em qualquer `run-cycle.ps1` novo — ver o bloco
  completo em qualquer `run-cycle.ps1` já existente (idêntico nos dois Supervisores) em vez de
  reescrever do zero.
- **Cadência real (não confie em comentário/doc — confira sempre `Export-ScheduledTask -TaskName
  <nome>` ou `(Get-ScheduledTask -TaskName <nome>).Triggers.Repetition.Interval` se precisar ter
  certeza; já rolou doc ficar desatualizada em relação à task de fato registrada mais de uma vez):**
  - **Todos os 3 Supervisores, 2026-09-15 (pedido do Thiago via Gerente, "aumente o período das
    execuções um pouco"):** SubAgents de módulo 5min→**10min**, Agent Master e Status Watcher
    15min→**20min**, aplicado nas 11 tasks (`SupAutomacaoUteis`: `AgentMaster`, `StatusWatcher`,
    `SubAgent-cedente`, `SubAgent-keycloakUser`; `SupE2eAutomation`: `AgentMaster`,
    `StatusWatcher`, `SubAgent-geral`, `SubAgent-mop`, `SubAgent-POC`; `SupTestesFrontEnd`:
    `StatusWatcher`, `SubAgent-mop`) via `Set-ScheduledTask -Trigger (New-ScheduledTaskTrigger
    -Once -At <StartBoundary já existente> -RepetitionInterval <novo> -RepetitionDuration
    (New-TimeSpan -Days 3650))` — preserva `StartBoundary`/Actions/Principal originais, só troca o
    intervalo de repetição. Antes disso os 3 estavam alinhados em 5min (SubAgent) / 15min (Agent
    Master e Status Watcher). Antigo histórico do `SupE2eAutomation` antes disso: 30min/1h →
    5min/15min → 15min/30min/15min → 5min/15min/15min (2026-09-14).
  - Os Supervisores ajustam cadência de forma independente entre si historicamente — não presuma
    que vão continuar sincronizados só porque coincidem agora; confira sempre a task real.

## Cadência adaptativa dos subAgents (ociosa 1h / ativa 10min) — criado em 2026-09-17

Pedido explícito do Thiago (via Gerente): em vez de rodar sempre no intervalo cheio mesmo quando
não há nada a fazer, cada `run-cycle.ps1` de **subAgent** (não Agent Master — ver seção seguinte;
não Status Watcher, já desativados) agora se reagenda sozinho a cada ciclo:

- **Ciclo ocioso** (a pré-checagem em PowerShell da seção 3.4 de cada `CLAUDE.md` não achou nada
  pendente/retomável, ou o `PAUSA-HML.flag` está ativo): ajusta a própria Scheduled Task para
  repetir de **1 em 1 hora**.
- **Ciclo ativo** (achou algo e chamou o Claude, mesmo que o ciclo não termine todo o trabalho):
  ajusta de volta para o intervalo normal de **10min**.

Mecanismo: função `Set-CadenciaAdaptativa` (copiada em cada `run-cycle.ps1`, mesmo padrão de
reaproveitar bloco já estabelecido nesta nota) lê a Scheduled Task pelo próprio nome
(`$nomeTaskAgendada`, variável no topo do script) via `Get-ScheduledTask`, compara o intervalo de
repetição atual com o alvo, e só chama `Set-ScheduledTask` se for diferente — preserva
`StartBoundary`/Actions/Principal originais, só troca `RepetitionInterval` (mesma técnica das
trocas de cadência manuais já documentadas na seção "Cadência real" abaixo). Chamada em 3 pontos de
cada script: no branch do `PAUSA-HML.flag` (ocioso), no branch de "nada pendente" da pré-checagem
(ocioso), e no fim do script depois do ciclo real rodar (ativo).

**Efeito colateral aceito, não é bug**: como a decisão é "achou algo neste ciclo?", não "a fila
ficou vazia no fim?", um módulo que termina toda a fila num ciclo só volta pra 1h no ciclo
*seguinte* (que vai rodar ainda no intervalo ativo, constatar fila vazia, e só aí desacelerar) —
uma tarefa nova que apareça durante a janela de 1h pode esperar até 1h pra ser pega, em vez dos
10min de antes. Compensação deliberada pelo Thiago: menos gasto de token/rate-limit em ciclos
ociosos, ao custo de reação mais lenta pra tarefa nova enquanto ocioso.

**Aplicado nos 6 `run-cycle.ps1` de subAgent** (não em Status Watcher, já desativado, nem em
`SupTestesFrontEnd/subagents/contratos`, que ainda não tem Scheduled Task registrada):
`SupE2eAutomation` (`geral`, `mop`, `POC`), `SupAutomacaoUteis` (`cedente`, `keycloakUser`),
`SupTestesFrontEnd` (`mop`). Validados sintaticamente (`[Parser]::ParseFile`) e o mecanismo de
troca de trigger testado ao vivo contra uma task real (`SupE2eAutomation-SubAgent-geral`, ida e
volta, sem deixar alterado) antes de aplicar.

## Agent Master: agendamento diário no fim do dia, até zerar a fila — criado em 2026-09-17

Pedido explícito do Thiago, na mesma conversa em que criou a cadência adaptativa acima: os 2 Agent
Master (`SupE2eAutomation`, `SupAutomacaoUteis` — `SupTestesFrontEnd` não tem Agent Master) **não**
usam a cadência adaptativa dos subAgents. Em vez disso, passaram a rodar **uma vez por dia, no fim
do dia (18:00), repetindo a cada 20min por até 12h (até ~06:00) até a `fila-merge/` esvaziar** — o
Thiago faz os testes manuais/aprovação no início do dia seguinte, começando um novo dia depois.

- **Por que repetição em vez de um disparo único**: o Agent Master processa a fila inteira num só
  ciclo (loop "para cada aviso em `fila-merge/pendentes/`"), mas pode deixar algo pra trás se travar
  em conflito/teste falhando (vira dúvida bloqueante, item fica em `pendentes/`) ou se o ciclo
  esgotar no meio. A repetição a cada 20min dá chances de retomar/drenar a fila ao longo da noite.
  **Não precisou de nenhuma lógica nova em PowerShell**: a pré-checagem `Test-TrabalhoPendente` que
  já existe (seção 3.4 de cada `CLAUDE.md`) já pula o ciclo (sem chamar o Claude) assim que
  `fila-merge/pendentes/` e `fila-merge/aguardando-aprovacao/` estiverem vazias — então, uma vez
  drenada, os disparos seguintes da mesma janela de 12h são de graça (só gravam `[ciclo pulado]`).
- **Removida a cadência adaptativa que tinha acabado de ser aplicada nos 2 Agent Master** (função
  `Set-CadenciaAdaptativa` e as 3 chamadas) — não fazia sentido com um trigger diário fixo; revertido
  antes de virar código morto/conflitante com o novo trigger.
- **Mecanismo do trigger** (Windows Task Scheduler via `Set-ScheduledTask`): `New-ScheduledTaskTrigger
  -Daily -At "18:00"` mais um `Repetition` (`MSFT_TaskRepetitionPattern`, `Interval=PT20M`,
  `Duration=PT12H`) atribuído manualmente ao objeto do trigger antes de `Set-ScheduledTask` — o
  parâmetro `-RepetitionInterval` do `New-ScheduledTaskTrigger` **não é aceito junto com `-Daily`**
  nesta versão do PowerShell (erro `AmbiguousParameterSet`); a única forma que funcionou foi criar o
  trigger `-Daily` puro e depois setar `$trigger.Repetition` via `New-CimInstance -ClassName
  MSFT_TaskRepetitionPattern -Namespace Root/Microsoft/Windows/TaskScheduler -ClientOnly -Property
  @{Interval="PT20M"; Duration="PT12H"; StopAtDurationEnd=$false}`. Válido pra qualquer trigger
  diário futuro que precise de repetição — copiar essa técnica em vez de tentar `-RepetitionInterval`
  direto no `New-ScheduledTaskTrigger -Daily`.
- **Enabled continua `False`** nas 2 tasks (ver achado abaixo) — só o agendamento foi trocado, não
  reabilitei por pedido explícito do Thiago ("não, deixe desabilitadas por enquanto").

**Achado à parte, ainda não explicado**: no momento desta edição, as 8 Scheduled Tasks de
subAgent/Agent Master estavam com `Enabled = False`, apesar de terem rodado normalmente até minutos
antes — causa não identificada, não fui eu (Gerente) quem desativou. Thiago já confirmou que, por
ora, para deixar assim (não reabilitar automaticamente).

## Fila global de contas — no máximo 1 tarefa por conta ao mesmo tempo — criado em 2026-09-17

Pedido explícito do Thiago ("não vamos mais rodar tantas coisas ao mesmo tempo"), na mesma tarde em
que as duas cadências acima foram criadas: **substitui completamente** a política de "conta de
casa" + fallback por rate-limit (seções "Pool de contas" e "Alternância de conta por rate-limit"
acima, ambas marcadas como superadas). Não é mais sobre qual conta um módulo "pertence" nem sobre
saturação de rate-limit — é puramente sobre **concorrência**: `contaA` e `contaB` são 2 slots, cada
um processa **uma tarefa por vez, do início ao fim, sem alternar no meio**, não importa quantas
tarefas existam nem de qual Supervisor/módulo elas são.

- **Regra**: a primeira tarefa (de qualquer subAgent/Agent Master, de qualquer Supervisor) que
  pedir um slot pega `contaA`; a segunda pega `contaB`; uma terceira tarefa que peça um slot
  enquanto as duas primeiras ainda estiverem rodando **espera** — não faz o ciclo tentar de novo
  imediatamente, apenas registra `[fila-global] ... aguarda a proxima execucao` no `run-log.txt` e
  encerra o ciclo (`exit 0`, sem chamar `claude -p`); a Scheduled Task tenta de novo sozinha no
  próximo disparo natural dela. **Atualizado em 2026-09-17 (mesmo dia, à tarde) — ver seção "Ordem
  global por antiguidade" logo abaixo:** quem pega o slot livre não é mais só "quem pediu primeiro"
  — é a tarefa mais antiga entre as que estão disputando, a menos que o Thiago tenha pedido
  prioridade manual numa tarefa específica.
- **Onde entra no fluxo de cada `run-cycle.ps1`**: só depois da pré-checagem determinística
  (`Test-TrabalhoPendente`) já confirmar que há trabalho real — pedir um slot antes disso seria
  desperdício (tarefa nenhuma pra fazer, não faz sentido reservar conta). Ou seja: sem
  trabalho → nem tenta slot (comportamento de sempre). Com trabalho, mas sem slot livre → aguarda
  (novidade desta seção). Com trabalho e slot livre → roda normalmente.
- **Mecanismo** (funções `Adquirir-SlotConta`/`Liberar-SlotConta`, copiadas em cada `run-cycle.ps1`,
  mesmo padrão de reaproveitar bloco já estabelecido nesta nota): um arquivo de lock por conta,
  `%USERPROFILE%\.claude-accounts\<conta>\em-uso.lock` (JSON: `ocupado_por` = nome do módulo, `pid`,
  `desde`). Verificar-e-reservar é atômico via `Mutex` nomeado global
  (`Global\ClaudeAgentsContaSlot`, mesma técnica do `Sync-RepoRaizClaudeAgents`) — dentro do mutex,
  tenta `contaA` primeiro, depois `contaB`; se as duas já tiverem lock válido (não expirado),
  devolve `$null` (nenhum slot obtido). Um lock com mais de **4h** é tratado como travado (processo
  que crashou sem liberar) e pode ser reclamado por outra tarefa — não deveria acontecer num ciclo
  normal, é só rede de segurança.
- **Liberação**: logo depois do `claude -p` terminar e o `rate_limit_event` (se houver) ser
  gravado em `ultima-utilizacao.json` — antes do `git push` final, que não depende da conta. Chamada
  sempre, sucesso ou falha do ciclo (não há cenário em que o script continua sem liberar, exceto
  crash de processo, coberto pela expiração de 4h acima).
- **`ultima-utilizacao.json` continua sendo gravado por informação** (usado pelo "status" da
  Gerente pra mostrar utilização de rate-limit) — só não decide mais qual conta usar. As funções
  `Get-UtilizacaoConta`/o bloco de decisão por `>=99%` foram removidos dos 8 scripts.
- **Cadência ao não conseguir slot (2026-09-17, atualizado à tarde — pedido do Thiago, "se a conta
  tiver ocupada o agente deve ficar ocioso também"):** subAgent desacelera pra 1h
  (`Set-CadenciaAdaptativa -Estado 'ocioso'`) igual a um ciclo sem trabalho nenhum — **não** tenta
  de novo em 10min só pra achar as contas ocupadas de novo. Troca de posição em relação à primeira
  versão desta regra (que mantinha cadência ativa/10min nesse caso) — decisão explícita do Thiago
  de aceitar reação mais lenta em troca de menos ciclos gastos batendo numa conta ocupada. Agent
  Master não tem cadência adaptativa (agendamento diário fixo), só sai e tenta nos próximos 20min
  da mesma janela.
- **Aplicado nos mesmos 8 `run-cycle.ps1` reais** de sempre (6 subAgents + 2 Agent Master).
  Validado: mecanismo testado isoladamente (reserva sequencial de 2 slots, 3ª tentativa nula,
  liberação e reserva do slot liberado) antes de aplicar nos 8 scripts reais; todos os 8 validados
  sintaticamente (`[Parser]::ParseFile`) depois da edição; conferido que não sobrou nenhum
  `em-uso.lock` órfão nas pastas de conta reais.

## Ordem global por antiguidade + prioridade manual — criado em 2026-09-17 (mesmo dia, à tarde)

Pedido explícito do Thiago: **"Você Gerente deve controlar a ordem das tarefas, então sempre a
mais antiga primeiro, a menos que eu peça prioridade em alguma"**. Estende a fila global de contas
acima — não é mais só "quem pediu o slot primeiro" (ordem de chegada por timing de Scheduled Task),
e sim a tarefa mais antiga entre as que estão disputando slot **em qualquer Supervisor/módulo**,
com uma exceção manual pra quando o Thiago quer priorizar algo específico.

- **Idade de uma tarefa = o timestamp já embutido no próprio id** (`<timestamp
  yyyyMMddHHmmss>-<slug>`, convenção já usada em todo id de tarefa/aviso neste sistema) — não
  precisa de metadado novo.
- **Mecanismo** (funções `Atualizar-FilaTarefas`/`Get-DataDoId`, mesmo padrão de bloco reaproveitado
  em cada `run-cycle.ps1`): antes de tentar um slot, cada ciclo com trabalho pendente registra
  `{ "<modulo>": "<idTarefa>" }` num arquivo compartilhado
  `%USERPROFILE%\.claude-accounts\fila-tarefas.json` (protegido pelo mesmo Mutex
  `Global\ClaudeAgentsContaSlot` da fila de contas — mesma seção crítica, sem mutex adicional).
  Depois, ainda dentro do mutex: conta quantos slots estão livres agora e quantos outros módulos
  na fila têm tarefa **mais antiga** que a minha; se essa contagem for `>=` slots livres, cedo a vez
  neste ciclo (log `[fila-global] cedendo a vez (...)`) mesmo com slot tecnicamente livre — deixo o
  módulo mais antigo pegar no disparo dele. Um ciclo sem trabalho (ou que decide ceder) limpa a
  própria entrada da fila (`Atualizar-FilaTarefas -IdTarefa $null`) pra não deixar registro
  obsoleto atrapalhando a próxima comparação.
- **Prioridade manual**: arquivo `%USERPROFILE%\.claude-accounts\prioridade.json`
  (`{ "idTarefa": "<id>" }`), gravado pela sessão da Gerente quando o Thiago pede prioridade numa
  tarefa específica em conversa (não existe outro jeito de setar — decisão explícita do Thiago,
  "você me avisa em conversa"). Enquanto ativo, **sempre vence a ordem por idade**: a tarefa cujo id
  bate com `prioridade.json` nunca cede vez; qualquer outra tarefa disputando cede
  incondicionalmente enquanto essa prioridade estiver ativa, mesmo sendo mais antiga. Limitação
  conhecida: não há auto-limpeza quando a tarefa prioritária termina — a Gerente precisa lembrar de
  apagar/atualizar `prioridade.json` quando o Thiago disser que não precisa mais, ou perceber sozinha
  (ex. ao conferir "status") que a tarefa já terminou.
- **Limitação estrutural aceita**: como cada `run-cycle.ps1` é uma execução curta e independente
  (não há um processo "esperando" de verdade), a comparação de idade só enxerga os módulos que
  também estão no meio do próprio ciclo checando a fila **naquele exato momento** — não existe um
  orquestrador central vendo tudo em tempo real. Na prática, como os ciclos são frequentes (10-20min
  na maioria) e cada ciclo (mesmo sem conseguir slot) atualiza sua entrada na fila, a aproximação é
  boa o bastante — o pior caso é uma pequena janela onde a ordem não é perfeitamente respeitada, não
  um travamento ou erro.
- **Testado isoladamente antes de aplicar nos 8 scripts reais**: 3 cenários (2 slots livres sem
  disputa real; 1 slot livre com tarefa mais nova pedindo primeiro mas tarefa mais antiga já
  registrada na fila — a mais antiga venceu; prioridade manual ativa numa tarefa mais nova — ela
  venceu mesmo assim). Todos os 8 `run-cycle.ps1` validados sintaticamente depois da edição.

## Pular conta com rate-limit já conhecido ao escolher slot — criado em 2026-09-17 (mesmo dia, à noite)

Pedido explícito do Thiago, depois de observar na prática o problema: a "Fila global de contas"
(seção acima) escolhe slot só por lock de arquivo, ignorando rate-limit — então quando `contaA`
bate no limite de sessão (`five_hour=100%`), os ciclos seguintes continuam tentando `contaA`
primeiro (porque ela fica livre de lock assim que o ciclo anterior libera), gastando uma invocação
real de `claude -p` só para descobrir de novo "You've hit your session limit" (custo $0, mas tempo e
uma sessão desperdiçados, `contaB` livre e saudável do lado). Pedido do Thiago: **"Quando uma das
contas bater no limite deve marcá-la de alguma forma para que os próximos ciclos peguem a outra se
disponível."**

- **Mecanismo** (função `Test-ContaSaturada`, mesmo padrão de bloco reaproveitado em cada
  `run-cycle.ps1`, definida logo após `Set-UtilizacaoConta`): lê
  `%USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json` (já gravado por
  `Set-UtilizacaoConta` a cada ciclo que realmente chama `claude -p`, mesmo quando esse ciclo bate
  no limite — não precisou de nenhum registro novo). Considera a conta saturada quando
  `five_hour_utilization >= 0.99` **e** o `resetsAt` (epoch em segundos) ainda não passou. Sem
  arquivo, ou dado antigo já com `resetsAt` no passado, conta como disponível — não precisa de
  limpeza manual, se "desmarca" sozinha quando o rate-limit da conta reseta.
- **Onde entra**: dentro de `Adquirir-SlotConta`, no laço que escolhe a conta livre — antes era
  sempre `foreach ($conta in @("contaA","contaB"))` (contaA sempre tentada primeiro); agora a ordem
  de tentativa é reordenada por `Sort-Object` colocando toda conta saturada por último
  (`$ordemTentativa = @("contaA","contaB") | Sort-Object { if (Test-ContaSaturada -Conta $_) { 1 }
  else { 0 } }`). Se só uma estiver saturada, a outra é tentada primeiro (e normalmente conseguida,
  já que só está saturação de rate-limit, não lock real). Se as duas estiverem saturadas ao mesmo
  tempo, a ordem original é mantida — sem alternativa mesmo assim, comportamento inalterado nesse
  caso extremo.
- **Não é uma volta à política antiga de "conta de casa"/alternância** (seção "Alternância de conta
  por rate-limit", superada) — continua sendo só sobre concorrência de slot (1 tarefa por conta por
  vez), esta mudança só reordena qual conta é tentada primeiro dentro do mecanismo de slot já
  existente, usando um dado (`ultima-utilizacao.json`) que já era gravado por outro motivo
  (informar o "status" da Gerente) e nunca tinha sido reaproveitado para decidir nada desde a troca
  de 2026-09-17 cedo.
- **Aplicado nos mesmos 8 `run-cycle.ps1` reais** (6 subAgents + 2 Agent Master). Testado
  isoladamente com o estado real da máquina no momento (`contaA` saturada, resetsAt ~20:30,
  `contaB` livre) — a ordem de tentativa saiu `contaB, contaA`, como esperado. Todos os 8 validados
  sintaticamente (`[Parser]::ParseFile`) depois da edição.

## Scheduled Task sob demanda — criado em 2026-09-17 (mesmo dia, à noite)

Pedido explícito do Thiago: **"Se não tiver nada para o subAgent não precisa ter task, se não
houver nada para o Sup o master não precisa estar ativo; quando eu criar alguma tarefa para eles
você ativa sob demanda e os configura para se desativarem após a conclusão se não houver outra
coisa na fila."** Substitui a "cadência ociosa" (seção "Cadência real" abaixo) como resposta a fila
vazia nos subAgents — em vez de só desacelerar para 1h, a própria Scheduled Task é desabilitada
(`Disable-ScheduledTask`). Reduz a zero os ciclos "de graça" (mesmo um ciclo pulado sem chamar
`claude -p` ainda gastava um disparo/log) enquanto não há absolutamente nada a fazer.

- **Quem desabilita, e quando**: o próprio `run-cycle.ps1`, no mesmo branch onde hoje loga `[ciclo
  pulado] ...`/`fila-merge vazia` e chamava `Set-CadenciaAdaptativa -Estado 'ocioso'` — trocado por
  uma função nova (`Disable-TaskSobDemanda` nos subAgents, reaproveitando `$nomeTaskAgendada` já
  declarado; bloco inline equivalente nos 2 Agent Master, que não tinham cadência adaptativa —
  hardcoded `SupAutomacaoUteis-AgentMaster`/`SupE2eAutomation-AgentMaster`). **Não se aplica** ao
  branch de `PAUSA-HML.flag` (ambiente fora do ar, não é "fila vazia" no sentido deste mecanismo —
  continua só com cadência ociosa) nem ao branch de "sem slot de conta livre" (há trabalho real,
  só não tem conta disponível agora — desabilitar aqui atrasaria a retomada sem necessidade).
- **Quem reabilita — três entradas cobertas**:
  1. **Tarefa nova criada por um Supervisor** (protocolo de refinamento de demanda, seção 2 de cada
     `CLAUDE.md`): ao gravar o arquivo em `tarefas/pendentes/`, o Supervisor também chama
     `Enable-ScheduledTask -TaskName "<Supervisor>-SubAgent-<modulo>"` se ela estiver desabilitada.
  2. **Dúvida respondida** (protocolo de dúvidas, seção 4 de cada `CLAUDE.md`): ao marcar `Status:
     respondida` em `duvidas.md`, o Supervisor também reabilita a Scheduled Task do módulo — sem
     isso, uma tarefa em `aguardando-resposta/` ficaria presa para sempre (a task desabilitada nunca
     mais roda `Test-TrabalhoPendente` pra perceber que a dúvida foi respondida).
  3. **Aviso novo em `fila-merge/pendentes/`** (subAgent → Agent Master): coberto automaticamente
     via código determinístico — cada um dos 5 subAgents com Agent Master (todos exceto
     `SupTestesFrontEnd/mop`, que não tem Agent Master) checa, no fim do próprio ciclo (depois de
     `Liberar-SlotConta`, antes do `Sync-RepoRaizClaudeAgents`), se `../../agent-master/fila-merge/
     pendentes/` tem algo e reabilita `Enable-ScheduledTask` do Agent Master correspondente se
     estiver desabilitada. Não depende do Supervisor/Thiago lembrar disso.
- **Hand-off entre Supervisores** (`SupTestesFrontEnd` → `SupE2eAutomation`, seção 3.6 do
  `CLAUDE.md` do `SupTestesFrontEnd`): like o item 1 acima — ao gravar a tarefa nova em
  `SupE2eAutomation/subagents/<modulo>/tarefas/pendentes/`, o Supervisor que faz o hand-off também
  reabilita `SupE2eAutomation-SubAgent-<modulo>` se estiver desabilitada.
- **Não muda nenhuma regra de negócio** — só controla se a Scheduled Task dispara ou não. Quando
  reabilitada, a cadência volta pro intervalo ativo de sempre no primeiro ciclo real seguinte
  (`Set-CadenciaAdaptativa -Estado 'ativo'`, já existente).
- **Aplicado nos mesmos 8 `run-cycle.ps1` reais**. Todos os 8 validados sintaticamente
  (`[Parser]::ParseFile`) depois da edição.
- **Itens 1 e 2 (seções 2 e 4 dos 3 `CLAUDE.md`) já atualizados** (2026-09-17, mesma noite) com o
  parágrafo explícito instruindo o Supervisor a chamar `Enable-ScheduledTask` ao gravar tarefa nova
  ou marcar dúvida como respondida. `SupTestesFrontEnd` também recebeu a instrução equivalente no
  hand-off da seção 3.6 (reabilita `SupE2eAutomation-SubAgent-<modulo>` ao criar a tarefa do outro
  lado).

## Padrão estrutural de um Supervisor (referência: `SupE2eAutomation`)

- `CLAUDE.md` na raiz do Supervisor — o "manual" fixo do papel dele.
- **Sem `docs/conhecimento-geral.md`** (aposentado em 2026-09-17, pedido explícito do Thiago:
  "Supervisores não precisam ter conhecimento próprio, só os subAgents" — ver seção "Aposentadoria
  do conhecimento-geral.md por Supervisor" mais abaixo). Conhecimento mora só no
  `docs/documentacao.md` de cada subAgent/Agent Master; cross-módulo genuíno vira regra fixa no
  `AGENTE.md`/`CLAUDE.md`, ou fica só no módulo "dono" e os demais referenciam por caminho.
- `subagents/<modulo>/` — um por módulo/domínio de demanda: `AGENTE.md`, `repo/` (clone do
  repositório do módulo), `docs/documentacao.md`, `duvidas.md`,
  `tarefas/{pendentes,executando,aguardando-resposta,concluidas}`.
- `agent-master/` — único por Supervisor, integra as branches dos subAgents na branch de
  integração do repositório via **Pull Request** (nunca merge/push direto): `AGENTE.md`, `repo/`,
  `docs/documentacao.md`, `duvidas.md`, `fila-merge/{pendentes,aguardando-aprovacao,concluidos}`.
- **Integração (mudou em 2026-09-14, pedido explícito do Thiago — novo padrão geral pros dois
  Supervisores, não só `SupE2eAutomation`):** o Agent Master faz **merge direto (com push)** na
  branch de integração (`reviewAgents`) de cada tarefa que passar nos testes — sem PR nem
  aprovação humana por tarefa. Ele **nunca** mergeia/dá push direto na `main`: o único ponto de
  revisão manual do humano responsável é um **PR único e contínuo `reviewAgents → main`**, que o
  Agent Master garante que existe (cria uma vez se faltar, `gh pr create --base main --head
  reviewAgents`; nunca recria) e que reflete sozinho, via GitHub, cada commit novo pusheado na
  `reviewAgents` — não precisa de nenhuma ação extra do agente a cada ciclo além de checar que
  continua aberto (`gh pr list --base main --head reviewAgents --state open`).
  - **Isso nunca espera aprovação do humano responsável** (esclarecido explicitamente a pedido do
    Thiago em 2026-09-14, para os dois Supervisores): abrir/manter esse PR único é automático, não
    depende de nenhuma decisão dele. Se uma tarefa hoje bloqueada por dúvida (ex.: teste falhando)
    for desbloqueada e pusheada na `reviewAgents` num ciclo futuro, o PR já aberto reflete essa
    mudança sozinho (o GitHub atualiza o diff automaticamente) — o humano responsável só precisa,
    quando quiser, mesclar esse PR já existente na branch de release. Aprovação/decisão dele só
    entra para desbloquear itens individuais em `duvidas.md`, nunca para manter o PR contínuo
    aberto.
  - **Modelo anterior (abandonado):** cada tarefa gerava seu próprio PR `feature/xxx →
    reviewAgents`, aprovado manualmente um por um — trocado por ser lento demais pro volume de
    tarefas. Um Supervisor que ainda estiver no modelo antigo deve migrar pro novo (releia a seção
    3.3 do `CLAUDE.md` do `SupE2eAutomation` como referência de como ficou depois da migração).
  - PRs por-tarefa já abertos no modelo antigo no momento da troca (ex.: PR #9 do
    `SupE2eAutomation`) continuam sendo aprovados manualmente do jeito de sempre — é só legado
    transitório, não crie PR novo por tarefa daqui pra frente.
  - **`SupAutomacaoUteis`: já atualizado (2026-09-14)** — `CLAUDE.md` (3.3), `agent-master/AGENTE.md`
    e `agent-master/run-cycle.ps1` já foram alinhados a este mesmo padrão. Diferença local: a
    branch de release desse repositório chama-se `master` (não `main`), então o PR de
    acompanhamento contínuo é `reviewAgents -> master`. O aviso pré-existente
    (`keycloakUser/clonar-usuario-prod-hml`) permanece em `fila-merge/aguardando-aprovacao/` como
    referência histórica do modelo anterior, aguardando a revisão manual de sempre.
- Protocolo de dúvidas: cada agente registra em `duvidas.md`; só o Supervisor marca uma dúvida como
  respondida — nenhum agente responde a própria dúvida. **Desde 2026-09-15**, o repasse até o
  humano responsável passa pelo Gerente (ver seção "Camada Gerente" no topo deste arquivo) em vez
  de conversa direta Supervisor↔Thiago.

### Variação: Supervisor de QA exploratório, sem código persistente (`SupTestesFrontEnd`, 2026-09-15)

Nem todo Supervisor produz/integra código — o `SupTestesFrontEnd` é o primeiro exemplo de um
padrão estrutural diferente, que deve ser reaplicado (não o padrão com Agent Master) para
qualquer Supervisor futuro cujo trabalho seja validar/testar em vez de codificar:

- **Sem `agent-master/`, sem `repo/` clonado por módulo.** Automação de browser (aqui, Cypress) é
  só ferramenta de execução — o código escrito para uma tarefa é descartável, não persiste como
  suíte. Conhecimento acumulado é só texto (`docs/documentacao.md`), nunca um módulo de código
  compartilhado entre tarefas.
- **Relatório é narrativo, passo a passo** ("tentei X → aconteceu Y"), registrado dentro do
  próprio arquivo de tarefa à medida que a execução acontece (não só um veredito no final) — dá
  contexto de verdade pra quem for revisar ou automatizar depois.
- **Toda execução concluída gera um PDF** com screenshots documentando passo a passo (política
  mudou em 2026-09-17 — antes era vídeo, `video: true`; ver seção "Vídeo → PDF" abaixo) e vai para
  `tarefas/aguardando-aprovacao/` — nunca direto para `concluidas/`. Só o Supervisor, numa
  conversa com o humano responsável, decide aprovar (segue pro passo seguinte) ou reprovar (volta
  pra refinamento). O subAgent nunca decide isso sozinho, mesmo que o teste tenha "passado".
- **Hand-off entre Supervisores é possível, mas é uma exceção deliberada e só depois de
  aprovação humana** — `SupTestesFrontEnd`, quando aprovado, cria uma tarefa nova em
  `SupE2eAutomation/subagents/<modulo>/tarefas/pendentes/` (mesmo nome de módulo nos dois lados,
  quando possível) para virar teste automatizado permanente. Regra geral: um Supervisor só pode
  **criar um arquivo de tarefa novo** na fila de outro Supervisor, nunca editar/mexer em qualquer
  outra coisa da pasta alheia (`AGENTE.md`, docs, duvidas, etc.), e isso deve ser explicitamente
  autorizado pelo humano responsável a cada vez — não vira uma automação silenciosa entre
  Supervisores. Se o módulo de destino não existir do lado do outro Supervisor, quem cria esse
  módulo é o Supervisor dono dele, nunca o de origem.

## GitHub CLI (`gh`) — necessário para qualquer Agent Master abrir PR

- Nesta máquina, o instalador `.msi` padrão do `gh` exige elevação (UAC) e falha em sessão não
  administrativa. Use a versão portátil: baixe o `.zip` do release (`gh_<versão>_windows_amd64.zip`
  em https://github.com/cli/cli/releases/latest), extraia em
  `%LOCALAPPDATA%\Programs\gh\bin\` e adicione ao PATH do **usuário** (não precisa de admin).
- Autentique via variável de ambiente `GH_TOKEN` (Personal Access Token), setada no `run-cycle.ps1`
  do Agent Master antes de chamar `claude` — **não** via `gh auth login --with-token`: essa versão
  do `gh` (2.100.0) tem um bug validando token fine-grained (`github_pat_...`) por esse fluxo
  (retorna `401 Bad credentials` mesmo com token válido), mas `GH_TOKEN` funciona normalmente.
  `gh auth login` interativo (device flow) também travou nesta máquina após autorizar no navegador
  (não confirmou o login) — não perca tempo tentando de novo, vá direto para `GH_TOKEN`.
- Nunca exponha o valor do token em documentação ou log.
- **O token sendo válido e com push/admin no repositório não é garantia de conseguir abrir PR**:
  em 2026-09-14, o mesmo token (fine-grained) que funciona para o `SupE2eAutomation` falhou com
  `gh pr create` no repositório do `SupAutomacaoUteis` (`Resource not accessible by personal
  access token`), mesmo `gh api repos/.../permissions` mostrando `push: true`. Suspeita: token
  fine-grained restrito a repositórios específicos e/ou sem a permissão "Pull requests"
  habilitada na sua configuração no GitHub — isso é por token, não por conta/usuário. Ao
  reaproveitar um `.gh-token` existente para um repositório novo, teste `gh pr create` cedo (ou ao
  menos `gh api repos/<owner>/<repo>` com um token de teste) antes de assumir que vai funcionar;
  se falhar, é o Thiago quem precisa ajustar o token nas configurações do GitHub, não é algo
  contornável via código.

## `PushNotification` é suprimido enquanto houver qualquer sessão interativa aberta — pop-up local como fallback (2026-09-14)

- Descoberto ao investigar por que o Thiago nunca recebia push dos Status Watchers: o Status
  Watcher (`SupE2eAutomation`) detectou um PR novo, chamou `PushNotification` corretamente, e a
  ferramenta devolveu **"Not sent — this terminal is active, so your output here already reaches
  the user; a separate notification would be redundant."** O critério de "terminal ativo" parece
  ser por conta (qualquer sessão interativa do Claude Code aberta, mesmo ociosa, mesmo em outra
  pasta/Supervisor — confirmado via `ListAgents` mostrando sessões peer idle) — não por quem
  realmente está olhando aquele processo específico. Como o Thiago normalmente mantém alguma
  sessão interativa aberta, o push nunca chega. Reportado como feedback de produto, mas não é algo
  contornável via prompt.
- **Fallback implementado (nos dois Supervisores):** o Status Watcher, além de tentar
  `PushNotification` (sem depender do resultado), termina a resposta final do ciclo com uma linha
  exata `NOTIFICAR: <resumo>` sempre que há algo para notificar. O `run-cycle.ps1` (código
  determinístico, não a LLM) varre os eventos `assistant`/`result` do stream NDJSON procurando essa
  linha via regex (`(?m)^NOTIFICAR:\s*(.+)$`) e, se achar, grava a mensagem em
  `ultima-notificacao.txt` e dispara, via `Start-Process` **destacado** (não bloqueia o ciclo nem
  trava execuções futuras da Scheduled Task), um pop-up modal (`MessageBox` do
  `System.Windows.Forms`) com som (`SystemSounds.Exclamation`) na tela do usuário — função
  `Show-PopupNotificacao` em cada `run-cycle.ps1` de Status Watcher. Testado ao vivo com o Thiago,
  confirmado funcionando ("apareceu, assim serve pra mim").
- **Por que a mensagem passa por um arquivo (`ultima-notificacao.txt`) em vez de ir direto no
  argumento do `Start-Process`:** evita expor o texto da notificação (gerado pela LLM, conteúdo
  arbitrário) a problemas de escaping de aspas na linha de comando — mesma classe de bug da seção
  abaixo. Só o caminho do arquivo (fixo, controlado, sem aspas) entra na string do comando.
- Ao criar um Status Watcher novo (ou qualquer agente que precise alertar o Thiago de forma
  confiável), reaproveite esse padrão em vez de depender só de `PushNotification`.

## Aspas duplas dentro do prompt de `run-cycle.ps1` — nunca use (armadilha real, 2026-09-14)

- `$prompt` é passado como argumento de linha de comando pro `claude.exe` (`claude -p $prompt ...`).
  Quando o texto do prompt contém aspas duplas **aninhadas** (aspas dentro de aspas, ex.:
  `"gh pr create --title "<resumo>" --body "<texto>""`), o Windows corrompe o parsing do argv na
  hora de repassar a string pro processo nativo — pedaços do texto acabam sendo lidos como flags
  soltas pelo próprio `claude.exe`, que falha de cara com `error: unknown option '--json'` (mesmo
  sem nenhuma opção `--json` de verdade no comando) e o ciclo inteiro não roda nada.
- Foi exatamente isso que aconteceu nos dois Agent Master (`SupAutomacaoUteis` e
  `SupE2eAutomation`) nas primeiras execuções reais deles em 2026-09-14 — o prompt de ambos tinha
  um trecho tipo `abra o PR com "gh pr create --title "<resumo>" --body "<texto>""` só pra
  exemplificar o comando `gh` em prosa. A Scheduled Task "tinha sucesso" (`LastTaskResult=0`)
  porque o `.ps1` em si não falha, só o `claude` dentro dele — sempre olhe o `run-log.txt`, não só
  o resultado da task, pra confirmar que o ciclo realmente fez algo.
- **Correção definitiva (padrão atual, aplicada em todos os `run-cycle.ps1` dos dois
  Supervisores):** não passe `$prompt` como argumento de `claude -p` — faça o pipe pelo stdin,
  `$prompt | claude -p --permission-mode bypassPermissions --output-format stream-json --verbose`
  (sem `$prompt` depois de `-p`). Isso tira o texto do prompt do argv por completo, então aspas
  (simples, duplas, aninhadas, o que for) dentro dele deixam de ser um risco — não depende mais de
  disciplina manual de "nunca usar aspas". As duas famílias de Supervisor chegaram nessa mesma
  correção de forma independente em 2026-09-14 (um sinal de que é o jeito certo). Continue evitando
  aspas duplas por clareza/legibilidade do prompt, mas o que realmente impede o bug é o stdin, não
  a ausência de aspas.

## Pré-checagem em PowerShell antes de chamar `claude -p` — evita ciclo vazio gastando rate-limit (2026-09-14, `SupAutomacaoUteis`)

- Até aqui, todo `run-cycle.ps1` (subAgent, Agent Master, Status Watcher) chamava `claude -p` **a
  cada ciclo**, mesmo quando não havia nada pendente — o próprio Claude constatava "nada a fazer"
  (passos 1-4 da lógica de subAgent/Agent Master, ou a comparação de estado do Status Watcher) e
  encerrava. Isso gasta uma invocação/rate-limit por ciclo à toa, na maioria dos ciclos.
- **Padrão novo (pedido explícito do Thiago):** `run-cycle.ps1` faz uma checagem determinística —
  só existência de arquivo em pastas de fila e o campo `Status:` de `duvidas.md` via regex, sem
  interpretar conteúdo — **antes** de montar/chamar o `claude -p`. Se não achar nada que justifique
  o ciclo, grava `[ciclo pulado] ...` em `run-log.txt` e sai (`exit 0`) sem invocar `claude` nenhuma
  vez. Ver seção 3.4 do `CLAUDE.md` do `SupAutomacaoUteis` pro detalhe exato de cada tipo de agente
  (subAgent, Agent Master, Status Watcher) e o código de referência em qualquer `run-cycle.ps1`
  daquele Supervisor.
- Continua sendo puramente uma otimização de custo — não muda nenhuma regra de negócio de quando o
  Claude É chamado (ele mesmo ainda confere de novo como reforço).
- **`SupE2eAutomation`: já aplicado (atualização em 2026-09-14, pedido do Thiago)** — os 4
  `run-cycle.ps1` (subAgents `geral`/`mop`, Agent Master, Status Watcher) e a seção 3.4 do
  `CLAUDE.md` desse Supervisor foram alinhados a este mesmo padrão. Diferença local: o Status
  Watcher do `SupE2eAutomation` também notifica um gatilho `conclusao` (tarefa concluída) que o
  `SupAutomacaoUteis` não tinha — a pré-checagem em PowerShell dele foi estendida pra também
  disparar quando aparece um arquivo em `tarefas/concluidas/`/`fila-merge/concluidos/` cujo nome
  ainda não conste (busca de texto cru, sem parsear JSON) em `estado-anterior.json`, além das
  checagens de dúvida pendente/PR legado que os dois Supervisores já compartilhavam.
- **Cadência voltou a ficar mais frequente depois desse padrão (2026-09-14):** com a maioria dos
  ciclos agora sendo pulados sem custo, o Thiago pediu pra voltar a cadência de ambos os
  Supervisores pro valor mais frequente de antes (`SupE2eAutomation`: subAgents 15min→5min, Agent
  Master 30min→15min, Status Watcher já estava 15min; `SupAutomacaoUteis` já estava em 5min/15min,
  sem mudança) — ver a seção "Cadência real" acima, sempre atualizada. Reforça o racional: a
  pré-checagem existe justamente pra permitir cadência mais frequente sem multiplicar o gasto de
  rate-limit, já que a maior parte dos ciclos extra é pulada de graça.

## Economia de tokens dentro de um ciclo que roda de verdade (2026-09-14)

A pré-checagem acima evita gastar tokens em ciclos **vazios**. Para os ciclos que realmente têm
algo a fazer (e por isso chamam `claude -p`), o segundo padrão de economia, aplicado à regra fixa
de todo `AGENTE.md` (subAgent e Agent Master, dos dois Supervisores): **nunca despejar a saída bruta
de comandos potencialmente grandes** (`npm test`/`npx cypress run`/`npm ci`/`npm install`/
`--legacy-peer-deps`) de volta no contexto do agente ou em `docs/documentacao.md`/`duvidas.md` —
redirecionar pra um arquivo e ler/relatar só o resumo relevante (passed/failed, mensagem de erro
específica, últimas linhas). Isso é puramente uma otimização de custo, igual à pré-checagem — não
muda nenhuma regra de negócio sobre quando um teste é considerado passou/falhou.

## Início de sessão interativa do Supervisor — reler documentação antes da primeira resposta (2026-09-14)

Pedido explícito do Thiago, aplicado aos dois Supervisores: no início de **toda sessão nova** do
Supervisor (a conversa interativa dele com o Thiago, não os ciclos automáticos de subAgent/Agent
Master/Status Watcher — esses já releem `documentacao.md` a cada ciclo por regra própria do
`AGENTE.md`), antes de responder à primeira mensagem, o Supervisor deve reler por completo: este
arquivo (`CONHECIMENTO-SUPERVISORES.md`) e o `docs/documentacao.md` de cada subAgent + do
`agent-master/` (nenhum Supervisor mantém mais `docs/conhecimento-geral.md` próprio — ver seção
"Aposentadoria do conhecimento-geral.md por Supervisor"). Motivo: entre uma sessão interativa e
outra, ciclos automáticos podem ter escrito conhecimento novo (aprendizado,
padrão descoberto, mudança de estado) que o Supervisor precisa conhecer antes de conversar com o
Thiago — não vale confiar em memória de uma sessão anterior. Ver o parágrafo equivalente no início
do `CLAUDE.md` de cada Supervisor (idêntico nos dois). Um Supervisor novo deve nascer já com esse
parágrafo.

## Alternância de conta por rate-limit — pool `contaA`/`contaB` (2026-09-15, `SupE2eAutomation`; estendida a todos os 3 Supervisores em 2026-09-16)

> **SUPERADO em 2026-09-17** pela seção "Fila global de contas" (mais acima neste arquivo) — os 8
> `run-cycle.ps1` reais não têm mais `contaDeCasa`/`contaAlternativa`/`Get-UtilizacaoConta` nem essa
> lógica de troca por `>=99%`. Seção mantida só como histórico de como o mecanismo evoluiu; não
> copie o padrão descrito abaixo em nenhum `run-cycle.ps1` novo.

Como `contaA`/`contaB` são um pool **compartilhado entre os três Supervisores**, o Thiago pediu
pra aproveitar melhor a capacidade ociosa: além da conta "de casa" fixa de cada agente (rotação de
criação, ver seção acima), cada `run-cycle.ps1` tenta a conta alternativa **só no ciclo atual**
quando a de casa está saturada (`>= 99%` na janela `five_hour`), em vez de insistir nela e
arriscar um ciclo perdido.

**Atualização 2026-09-16 (pedido explícito do Thiago, "atualize essa regra para todos"):** o
padrão, que só existia no `SupE2eAutomation`, foi replicado para os `run-cycle.ps1` que ainda não
tinham (mesmo bloco de funções `Get-UtilizacaoConta`/`Set-UtilizacaoConta`, checagem antes de
setar `CLAUDE_CONFIG_DIR`, captura do evento `rate_limit_event` no parse do NDJSON, e gravação
final via `Set-UtilizacaoConta`):
- `SupAutomacaoUteis`: `subagents/keycloakUser` (casa `contaA`), `subagents/cedente` (casa
  `contaB`), `agent-master` (casa `contaB`), `status-watcher` (casa `contaB`).
- `SupTestesFrontEnd`: `subagents/mop` (casa `contaA`), `status-watcher` (casa `contaB`).
- Todos os 6 arquivos validados sintaticamente (`Parser]::ParseFile`) sem erro após a edição.
- Continua **não sendo aplicado nos ciclos automáticos de `SupE2eAutomation/subagents/geral`,
  `mop`, `agent-master`, `status-watcher`** por já terem sido feitos em 2026-09-15 — nada mudou
  neles agora.

- **Estado compartilhado por conta** (não por agente/Supervisor): cada `run-cycle.ps1` que chama
  `claude -p` grava a última utilização conhecida da conta que usou em
  `%USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json` (`five_hour_utilization` +
  `resetsAt` do `rate_limit_info` que vem no stream NDJSON). Como o caminho é por conta, não por
  Supervisor, esse arquivo fica automaticamente compartilhado entre os três — mesmo sem os outros
  dois adotarem a lógica de troca, o dado que `SupE2eAutomation` grava já é visível pra eles (e
  vice-versa, se algum ciclo deles também gravar).
- **Decisão de troca**: antes de chamar `claude -p` (depois da pré-checagem normal da seção 3.4 de
  cada Supervisor), o script lê a última utilização conhecida da conta de casa; se `>= 0.99` e o
  `resetsAt` ainda não passou, tenta a alternativa; se ela não estiver também saturada, usa-a só
  neste ciclo (log `[alternancia]` em `run-log.txt`); se ambas estiverem saturadas, segue com a de
  casa mesmo assim. **Não persiste a troca** — todo ciclo novo tenta a conta de casa primeiro de
  novo (decisão explícita do Thiago: manter o modelo de conta fixa como padrão, a troca é só
  fallback pontual, não uma realocação permanente).
- **Limitação conhecida**: não dá pra consultar a utilização de uma conta sem já ter feito uma
  chamada nela — a decisão sempre usa o último valor conhecido (pode ter alguns minutos, dependendo
  de quando qualquer agente usou aquela conta por último), nunca uma leitura em tempo real. Como os
  ciclos são frequentes (5-15min na maioria dos agentes), essa aproximação é boa o suficiente na
  prática.
- **Nota (2026-09-17): as "casas" citadas acima (`keycloakUser`=`contaA`, `mop`=`contaA`, etc.)
  estão desatualizadas** — não edite este bloco histórico, só releia a seção "Pool de contas" no
  topo deste arquivo pra saber a "casa" atual de cada agente (hoje: `contaB` pra praticamente
  tudo). Esta seção documenta só o histórico de quando o *mecanismo* de alternância foi implantado,
  não quem é "casa" de quem agora.
- **Aplicado até agora só no `SupE2eAutomation`** (seus 5 `run-cycle.ps1`: `geral`, `mop`, `POC`,
  `agent-master`, `status-watcher`). `SupAutomacaoUteis` e `SupTestesFrontEnd` ainda não adotaram —
  fica registrado aqui pra eles copiarem o padrão se quiserem (ver
  `SupE2eAutomation/docs/conhecimento-geral.md` pro detalhe completo e o código de referência em
  qualquer `run-cycle.ps1` daquele Supervisor), mas nenhum arquivo deles foi alterado por este
  Supervisor.

## `git add`/`git commit` no repo raiz (`claudeAgents`) — índice compartilhado entre Supervisores concorrentes (2026-09-15)

- Os três Supervisores (e seus agentes automatizados) commitam no **mesmo repositório git**
  (`C:\Multiplica\claudeAgents`, remoto `Thiagocs12/claudeAgents`) — não há um `.git` por
  Supervisor. Isso significa que o índice (staging area) e o `HEAD` são um recurso único e
  compartilhado: se dois processos (ex.: uma sessão interativa do Supervisor + um ciclo automático
  de outro Supervisor/agente rodando ao mesmo tempo) fizerem `git add` por perto um do outro, um
  `git add <arquivos específicos>` de um processo pode acabar sendo commitado junto por um
  `git commit`/`git add -A` do OUTRO processo, sob a mensagem dele — sem erro, sem conflito
  aparente, só um commit "levando junto" arquivo que não é dele.
- **Observado ao vivo (2026-09-15, sessão interativa do `SupAutomacaoUteis`):** a sessão rodou
  `git add` em 5 arquivos próprios (correção de um bug em `duvidas.md`/`AGENTE.md`/`CLAUDE.md` do
  módulo `cedente`) e, ao conferir `git status` logo em seguida, viu dezenas de arquivos de
  `SupE2eAutomation`/`SupTestesFrontEnd` (subAgents automáticos rodando em paralelo) já staged
  também — não foi essa sessão que os adicionou. Ao tentar `git commit -F <msg> -- <5 arquivos
  próprios>` (pathspec explícito, que deveria isolar só esses arquivos), o commit não apareceu no
  histórico com a mensagem esperada: uma Scheduled Task de outro Supervisor rodou `git commit`
  (provavelmente `git add -A` antes) entre o `git add` e o `git commit` desta sessão, e os 5
  arquivos acabaram integrados a um commit alheio (`de06e02`/`7cc29a9`) — conteúdo preservado
  corretamente (nada foi perdido ou corrompido), só a atribuição/mensagem do commit ficou
  "errada" do ponto de vista de quem esperava ver seu próprio commit.
- **Não é uma falha grave neste caso** (nenhum dado perdido, working tree nunca foi tocado à
  força) — mas é uma janela de corrida real que existe sempre que dois processos escrevem no
  mesmo índice quase ao mesmo tempo, algo bem provável com 3 Supervisores + Agent Masters +
  Status Watchers rodando em ciclos de 5-15min concorrentes.
- **Mitigação usada nesse incidente**: em vez de tentar `git add`/`git reset` pra "consertar" o
  índice compartilhado (arriscando desfazer o staged de outro processo em pleno voo), confirmar
  via `git diff HEAD -- <arquivos>` que o conteúdo esperado já estava commitado (mesmo que sob
  outra mensagem) e seguir sem novas tentativas de commit — mexer no índice compartilhado no meio
  de uma corrida tende a piorar, não corrigir.
- **Implementado em 2026-09-16 (pedido do Thiago: push automático de toda documentação de
  conhecimento + verificação de pull automático):** todo `run-cycle.ps1` (subAgents, Agent
  Masters, Status Watchers, nos 3 Supervisores) agora define e chama uma função
  `Sync-RepoRaizClaudeAgents`, serializada via `Mutex` nomeado global (`Global\ClaudeAgentsGitSync`)
  — exatamente o lock que esta seção pedia pra "considerar se o problema recorrer". Chamada **sem**
  `-PermitirCommitEPush` logo após o `Set-Location` (só `git fetch`+`merge --no-edit` contra
  `origin/main`, aborta e loga se der conflito em vez de deixar o repo preso num merge pela
  metade), e **com** `-PermitirCommitEPush` no fim do ciclo (`git add -A` + commit + push) nos
  scripts que escrevem (subAgents/Agent Masters) — os 3 Status Watchers só chamam a versão sem
  push, preservando a regra de "somente leitura". Antes disso, nenhum `run-cycle.ps1` fazia
  push/pull automático do repo raiz de forma confiável (só havia commits esporádicos por iniciativa
  do próprio agente durante um ciclo, sem push garantido — o repo local chegou a acumular commits
  não publicados no remoto). Qualquer novo módulo/Supervisor futuro deve nascer com essas duas
  chamadas já copiadas de um `run-cycle.ps1` existente (mesmo padrão de reaproveitar blocos já
  estabelecido nesta seção).
- **Estendido às sessões interativas em 2026-09-17 (pedido explícito do Thiago: "toda a estrutura
  tem que rodar um pull antes de iniciar")** — o que já valia para ciclos automáticos (pull no
  início, push no fim) passa a valer também pra sessão interativa da Gerente e de cada Supervisor,
  já que todas escrevem no mesmo repo raiz compartilhado:
  - **Pull automático no início**: `.claude/settings.json` na raiz (`C:\Multiplica\claudeAgents`)
    ganhou um hook `SessionStart` (mesmo padrão já usado nos `repo/.claude/settings.json` dos
    subAgents pra `reviewAgents`, adaptado pra `main`) que roda `git pull origin main` sempre que
    uma sessão interativa começa — só quando a branch atual é `main` e a working tree está limpa
    (senão só avisa, nunca troca de branch nem sobrescreve trabalho local). Como Gerente e
    Supervisores abrem sessão dentro do mesmo repositório (raiz ou uma subpasta dele), esse hook
    único cobre os dois.
  - **Push no fim de cada processo**: a Gerente já fazia isso desde antes (ver memória de sessão
    "push automático em mudança de docs") — cada Supervisor deve seguir a mesma disciplina: assim
    que terminar de escrever/mover algo relevante (tarefa, dúvida respondida, `documentacao.md`,
    etc.), commitar e dar `git push origin main` na hora, sem esperar o fim da conversa inteira.
  - **Não muda nada dos ciclos automáticos** (subAgents/Agent Masters/Status Watchers já faziam
    pull+push via `Sync-RepoRaizClaudeAgents`, confirmado acima) nem do fluxo de `pull` da branch
    `reviewAgents` de cada subAgent antes de criar uma branch nova (regra 4 do `AGENTE.md` de cada
    um) — isso continua exatamente como já estava.

## Economia de tokens — arquivar documentação grande (2026-09-16)

- Pedido do Thiago: os arquivos que todo ciclo relê INTEIROS (`docs/documentacao.md`,
  `duvidas.md`, `conhecimento-geral.md`, a narrativa `## Execução` de uma tarefa em
  `executando/`) crescem sem limite enquanto o trabalho continua — cada ciclo novo paga o custo de
  reler tudo de novo, incluindo conteúdo já resolvido/superado. Isso é hoje o maior driver de custo
  de token do sistema (observado ao vivo: a tarefa `criacao-operacao-servico` do módulo `mop` em
  `SupTestesFrontEnd` chegou a 665 linhas de narrativa antes de ser compactada).
- **Convenção adotada (nova regra em todo `AGENTE.md`/`CLAUDE.md`):** quando um desses arquivos
  passa de ~200-250 linhas, arquive o conteúdo histórico/resolvido/superado num arquivo companheiro
  na mesma pasta (`<nome-original>-historico.md`), mantendo no arquivo principal só um resumo
  compacto do que ainda é operacionalmente relevante (seletores/padrões provados, decisões já
  tomadas, ponto exato onde a investigação está) + um ponteiro pro arquivo de histórico. **Nunca
  apagar informação ao arquivar — sempre mover, nunca descartar.**
- Exemplo de referência (o primeiro caso real, use como modelo de formato):
  `SupTestesFrontEnd/subagents/mop/tarefas/executando/20260915123730-criacao-operacao-servico.historico.md`
  (histórico completo, verbatim) +
  `SupTestesFrontEnd/subagents/mop/tarefas/executando/20260915123730-criacao-operacao-servico.md`
  (resumo compacto que ficou no lugar do original, com nota apontando pro histórico).

## Status compacto por Supervisor (`docs/status-resumo.md`) — criado em 2026-09-17

Pedido explícito do Thiago à Gerente, depois de um "status" dos 3 Supervisores consumir ~500 mil
tokens numa única checagem: a Gerente tinha forkado 3 subagentes (um por Supervisor) para reler
`duvidas.md`/`tarefas/` cru de cada subAgent/Agent Master — cada fork herdando a conversa inteira
da Gerente (incluindo este arquivo + os 3 `CLAUDE.md`, já grandes), replicado 3x, mais uma retentativa
porque um dos forks devolveu resposta vazia.

**Correção adotada nos 3 Supervisores:** cada um passa a manter um arquivo compacto
`docs/status-resumo.md` (raiz do Supervisor, irmão de `conhecimento-geral.md`), com uma seção `##
<modulo>` por subAgent + uma `## agent-master` (quando existir), atualizada **pelo próprio
subAgent/Agent Master** (nunca pela Gerente) sempre que seu estado mudar — regra nova acrescentada
ao `AGENTE.md` de cada um (ver seção "Status compacto" do `CLAUDE.md` de cada Supervisor pro
detalhe exato). Cada agente só edita a própria seção, relendo o arquivo inteiro antes de escrever
(mesma disciplina já usada em `conhecimento-geral.md`, evita perder edição concorrente).

**Novo protocolo de "status" da Gerente:** ler só os 3 `docs/status-resumo.md` (um por Supervisor)
+ os dois `ultima-utilizacao.json` de conta — nunca mais forkar/reler `duvidas.md`/`tarefas/` cru de
cada módulo por padrão. Só cair para uma leitura mais profunda de um módulo específico se a seção
dele no `status-resumo.md` estiver ausente, contraditória com o que o Thiago já sabe, ou claramente
desatualizada (ex.: aponta tarefa que já não existe mais na pasta).

Qualquer Supervisor novo deve nascer já com esse arquivo (mesmo que vazio/com só cabeçalho) e a
regra correspondente no `AGENTE.md` de cada subAgent/Agent Master — copiar o padrão de um dos 3
`CLAUDE.md` existentes em vez de reinventar.

## Vídeo → PDF como formato de documentação de execução — criado em 2026-09-17

Pedido explícito do Thiago à Gerente: em vez de gravar vídeo de uma execução de teste, gerar um
**PDF documentando tudo o que foi feito, com screenshots e demonstração de clique** (par de
screenshot antes/depois de cada clique relevante, junto da narrativa passo a passo). Vídeos
antigos já foram apagados (locais dos 3 Supervisores + as pastas de teste manual do Thiago,
`C:\multiplica\cypress-e2e`/`cypress-uteis` — incluindo uma pasta corrompida por um bug antigo de
aspas num `cp`, achada e removida no processo).

- **Escopo:** `SupTestesFrontEnd` (onde o PDF passa a ser o entregável principal de cada tarefa,
  ver seção 3.5 do `CLAUDE.md` dele) e `SupE2eAutomation` (onde o Agent Master vai copiar PDFs em
  vez de vídeos pra pasta de teste manual do Thiago, ver seção 3.3 do `CLAUDE.md` dele). **Não
  se aplica a `SupAutomacaoUteis`**: esse repositório não é uma suíte de UI — é uma ferramenta de
  orquestração de dados via API/SQL (ver `CLAUDE.md` do próprio repositório,
  `subagents/*/repo/CLAUDE.md`), sem fluxo de tela/clique que valha a pena documentar assim, e
  nunca gerou vídeo pra revisão do Thiago (confirmado: não há `cypress/videos/` na pasta de teste
  manual `C:\multiplica\cypress-uteis`).
- **Mecanismo prescrito** (concreto o bastante pra qualquer subAgent implementar sem reinventar):
  `video: false` no `cypress.config.js`; `cy.screenshot('<passo-N-descricao>')` chamado
  manualmente antes/depois de cada clique relevante (não só o automático de falha do Cypress); um
  script Node reaproveitável (`pdfkit`) que junta a narrativa (`## Execução`) + os screenshots em
  ordem num PDF por tarefa/execução.
- **`SupTestesFrontEnd`: já implementado nos arquivos de política** (`AGENTE.md` do `mop`,
  `CLAUDE.md`, `cypress.config.js` já com `video: false`) — o próprio subAgent ainda precisa
  escrever o script `gerar-relatorio-pdf.cjs` na próxima vez que concluir uma tarefa (é
  infraestrutura, não foi implementada pela Gerente, que não implementa código).
- **`SupE2eAutomation`: registrado como tarefa nova** em
  `subagents/geral/tarefas/pendentes/` (módulo `geral` porque essa infra é cross-módulo, reusada
  por `POC`/`mop`/futuros) — a Gerente não edita o repositório clonado (`automacaoUiMultiplica`)
  diretamente, isso é trabalho do subAgent, incluindo atualizar o próprio `CLAUDE.md` do
  repositório (hoje lista "relatórios (mochawesome/Allure)" como fora de escopo — isso muda). Até
  essa tarefa ser processada, o Agent Master continua copiando vídeo normalmente (a regra nova no
  `AGENTE.md` dele já aponta pro novo formato, mas só passa a valer quando a infra existir).

## Redução de custo de token — Status Watchers desativados (2026-09-17)

Investigação de custo por agente (agregando `[ciclo encerrado] ... custo=$X` de cada
`run-log.txt`) mostrou `contaB` saturada (100% de uso) e `contaA` subindo rápido logo depois da
troca de política pra `contaB` como conta padrão. Achados principais:

- `SupAutomacaoUteis/subagents/cedente` tem o maior custo médio por ciclo (~US$1,51, 3-7x os
  demais) — tarefa grande (dezenas de tabelas, várias fases), esperado que seja cara, mas vale
  observar se `docs/documentacao.md`/`conhecimento-geral.md` crescerem demais (arquivar se passar
  de ~200-250 linhas).
- `SupE2eAutomation/agent-master` tem alto número de ciclos reais (94, poucos pulados) — pode estar
  reprocessando a mesma tentativa de merge que falha repetidamente (ver bloqueio de login/Keycloak
  do momento) sem progredir; vale revisitar se ficar preso assim por muito tempo.
- **Os 3 Status Watchers** custavam de forma desproporcional ao valor que entregavam: o de
  `SupE2eAutomation` sozinho custou ~US$18,47 em 85 ciclos reais (só 81 pulados) — a lógica de
  "notificar de novo só depois de 2h" dependia de chamar o Claude a cada ciclo pra recalcular isso,
  em vez de ser uma comparação de timestamp determinística em PowerShell.
- **Ação tomada (pedido explícito do Thiago): as 3 Scheduled Tasks de Status Watcher foram
  removidas** (`Unregister-ScheduledTask` em `SupE2eAutomation-StatusWatcher`,
  `SupAutomacaoUteis-StatusWatcher`, `SupTestesFrontEnd-StatusWatcher`). As pastas `status-watcher/`
  de cada Supervisor continuam intactas (não foram apagadas), só não são mais chamadas — dá pra
  reativar recriando a Scheduled Task. Ver seção "Status Watcher" do `CLAUDE.md` de cada Supervisor.
- **Consequência**: não há mais notificação automática (pop-up) de dúvida nova/PR pendente/tarefa
  concluída — o Thiago precisa perguntar "status" à Gerente quando quiser saber (barato agora, ver
  seção "Status compacto por Supervisor" acima).

## Armadilhas de ambiente compartilhadas pela máquina (não específicas de um Supervisor)

- O cache de binário do Cypress é **global por usuário do Windows**
  (`%LOCALAPPDATA%\Cypress\Cache`), compartilhado por qualquer projeto Node/Cypress rodado nesta
  máquina — relevante para qualquer Supervisor futuro que também use Cypress, não só o
  `SupE2eAutomation`.
- **`npx cypress run` sem `timeout` explícito pode virar processo órfão** (descoberto no
  `SupTestesFrontEnd/mop`, 2026-09-15): num ciclo `claude -p` real, o agente chamou
  `npx cypress run` via Bash sem passar `timeout`, o comando estourou o timeout implícito do Bash
  e foi movido pra background pela ferramenta; o agente tentou "esperar terminar depois"
  (chegou a chamar `ScheduleWakeup`, que não se aplica a um ciclo `-p` de execução única — não há
  próximo turno pra um wakeup disparar) e encerrou o ciclo com o processo Cypress/Electron/node
  ainda vivo. Ficaram processos órfãos rodando por mais de 2h até serem achados e encerrados
  manualmente. Qualquer Supervisor que chame Cypress via `claude -p` (os três hoje) deveria: (1)
  instruir no `AGENTE.md` a sempre passar `timeout: 300000`+ nessas chamadas e nunca usar
  `ScheduleWakeup`/esperar background; (2) ter uma rede de segurança determinística no
  `run-cycle.ps1` que mate, no início e no fim de cada ciclo, qualquer processo cuja `CommandLine`
  referencie a pasta do agente e contenha "cypress" (raiz) mais toda a árvore de processos filhos
  — não depende do LLM se comportar. Implementado assim em `SupTestesFrontEnd/subagents/mop/
  run-cycle.ps1` (função `Stop-ProcessosCypressOrfaos`) — usar como referência antes de reinventar
  em outro Supervisor.

## Bugs conhecidos no padrão compartilhado de `run-cycle.ps1` — não corrigidos

Bugs no **código compartilhado** (função copiada em todo `run-cycle.ps1` dos 3 Supervisores), não
conhecimento de nenhum módulo específico — por isso moram aqui, não no `documentacao.md` de um
subAgent.

- **`Test-DuvidaRespondida` considera um id "respondido" para sempre a partir do primeiro bloco que
  bate, ignorando rodadas posteriores ainda pendentes.** A função divide `duvidas.md` em blocos por
  `## ` e retorna no **primeiro** bloco cujo cabeçalho bate com o id da tarefa. Tarefas com várias
  rodadas de dúvida sob o mesmo id (comum neste projeto) sempre têm o primeiro bloco como o mais
  antigo — uma vez que essa 1ª pergunta é respondida, a função retorna `true` **para sempre** para
  aquele id, mesmo que rodadas mais recentes estejam `Status: pendente`. **Recorrido várias vezes,
  descoberto de forma independente em dois módulos diferentes** (`POC`/`SupE2eAutomation`, ao menos
  5 recorrências consecutivas numa mesma tarefa; `mop`/`SupTestesFrontEnd`, 2 recorrências
  consecutivas) — mesmo sintoma, mesma causa raiz.
  - **Mitigação já adotada nos `AGENTE.md`** (regra explícita em todo subAgent): se uma tarefa já
    teve uma dúvida respondida e volta a bloquear por outro motivo, nunca criar um segundo bloco
    `## <id>` — manter um único bloco por tarefa ao longo de toda a sua vida; perguntas/respostas já
    resolvidas migram para campos com sufixo numérico (`Status-historico-1:`, `Pergunta-1:`,
    `Resposta-1:`, depois `-2`, etc.) que não batem com o regex da pré-checagem. Isso evita o
    sintoma na maioria dos casos, mas não corrige a função em si.
  - **Correção real ainda não aplicada** (script compartilhado — precisa ser replicada em todo
    `run-cycle.ps1`, coordenada de uma vez): iterar os blocos de `duvidas.md` em ordem reversa (ou
    usar o **último** bloco que bate com o id, não o primeiro) para checar o `Status:` da rodada
    mais recente.
  - Até a correção: qualquer agente que encontrar uma tarefa recém-movida para `pendentes/`/
    `executando/` por essa pré-checagem, numa tarefa com múltiplas rodadas de dúvida sob o mesmo
    id, deve conferir manualmente se a rodada **mais recente** em `duvidas.md` está mesmo
    `Status: respondida` antes de agir.
- **Pré-checagem (seção 3.4 de cada `CLAUDE.md`) não distingue "pendente normal" de "pendente
  deliberadamente parado".** Quando o Thiago responde uma dúvida bloqueante dizendo "não reprocesse
  automaticamente até eu trazer instrução nova", mas o item continua fisicamente em
  `fila-merge/pendentes/` (Agent Master) ou `tarefas/pendentes/` (subAgent) — em vez de ser movido
  para um estado de espera — a pré-checagem continua achando "há arquivo em pendentes/" e chamando
  o `claude -p` a cada ciclo, mesmo com a instrução de não fazer nada já registrada. Já gerou
  dezenas de ciclos idênticos de "nada a fazer" num único dia (gasto de rate-limit sem trabalho
  real). Mitigação pontual já usada: mover o item pra uma pasta fora do escopo da pré-checagem (ex.
  `fila-merge/pausados/`), decisão caso a caso do Supervisor — não uma correção genérica no script.

## Aposentadoria do `docs/conhecimento-geral.md` por Supervisor — criado em 2026-09-17

Pedido explícito do Thiago: "Supervisores não precisam ter conhecimento próprio, só os subAgents
— Supervisores só precisam seguir as regras." Cada Supervisor mantinha um `docs/conhecimento-geral.md`
compartilhado, editado por qualquer subAgent/Agent Master a cada ciclo e relido INTEIRO por todos —
exatamente o padrão que cresce sem controle (os dois maiores chegaram a 563 e 373 linhas, e
precisaram de compactação forçada nesta mesma sessão, mais cedo em 2026-09-17).

- **Removido dos 3 Supervisores**: os 6 arquivos (`docs/conhecimento-geral.md` + `-historico.md` ×
  3) foram deletados depois do conteúdo ser redistribuído — nada foi perdido, só relocado (git
  history preserva as versões antigas de qualquer forma).
- **Regra de destino aplicada a cada seção que existia**: regra fixa/procedimento (nunca ecoar
  `GH_TOKEN`, título de `duvidas.md` = id exato, `git fetch` antes de assumir que uma branch não
  existe, nunca `npm ci`, etc.) → virou regra permanente no `AGENTE.md` do(s) módulo(s) afetado(s);
  conhecimento específico de 1 módulo → foi pro `docs/documentacao.md` desse módulo; conhecimento
  cross-módulo mas não fixo (ex.: catálogo de instabilidade de login/Keycloak do
  `SupE2eAutomation`) → ficou só no módulo "dono" (quem descobriu primeiro/mantém a infra), os
  demais módulos referenciam **pelo caminho do arquivo**, nunca copiando — mesmo padrão já usado
  pelo `AgenteEspecificacao` (material de apoio referenciado por caminho); bug no padrão
  compartilhado de `run-cycle.ps1` → foi pra seção "Bugs conhecidos" acima.
- **Cada agente (subAgent/Agent Master) agora só lê o próprio `docs/documentacao.md`** antes de
  cada ciclo — removida a instrução de ler/escrever em `conhecimento-geral.md` do `AGENTE.md`,
  `CLAUDE.md` (seções 3.1/3.2/3.3) e do prompt de cada `run-cycle.ps1` dos 3 Supervisores.
- **Qualquer Supervisor novo nasce sem `docs/conhecimento-geral.md`** — não recriar esse padrão.
  Se surgir um aprendizado genuinamente cross-módulo no futuro, o Supervisor decide o destino na
  hora (regra fixa em `AGENTE.md`, módulo dono + referência por caminho, ou esta nota se for um bug
  no script compartilhado) em vez de reabrir um arquivo compartilhado vivo.
