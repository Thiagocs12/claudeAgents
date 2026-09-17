# Conhecimento geral do sistema (leitura obrigatória para todo agente)

Este arquivo reúne aprendizados e convenções que atravessam módulos — todo subAgent e o Agent
Master devem ler este arquivo INTEIRO antes de iniciar qualquer ciclo, além do
`docs/documentacao.md` do próprio módulo. Se você (agente) aprender algo que outro módulo também
precisaria saber, registre aqui — não só no seu `docs/documentacao.md` local.

**Antes de escrever:** releia este arquivo imediatamente antes de salvar sua atualização, para não
perder uma edição feita por outro agente rodando em paralelo (não há lock automático entre
ciclos).

## Segurança — nunca ecoe GH_TOKEN (ou qualquer secret) em comando de diagnóstico (2026-09-14)

- Um comando de diagnóstico rodado pelo Agent Master (erro de sintaxe/quoting, não foi uma tarefa)
  ecoou o `GH_TOKEN` completo em texto puro na saída, que foi parar em `agent-master/run-log.txt`
  (o log em streaming grava literalmente o que passa pelo stdout/stderr do ciclo). Token tinha
  acesso total aos repositórios e não expira — ficou exposto até o Supervisor redigir o log e o
  Thiago revogar/rotacionar no GitHub.
- **Nunca rode um comando que possa imprimir `$env:GH_TOKEN` (ou qualquer variável de
  credencial) por inteiro** — nem para depurar. Se precisar confirmar que a variável está setada,
  cheque só o comprimento/prefixo (`$env:GH_TOKEN.Length`, `$env:GH_TOKEN.Substring(0,4)`), nunca
  o valor completo.
- Se acontecer de novo (qualquer secret vazar em `run-log.txt`, `docs/documentacao.md`, ou
  qualquer arquivo lido por outro agente/Supervisor): registre dúvida bloqueante imediatamente
  (não tente redigir/apagar sozinho — isso é decisão do Supervisor/Thiago) e não repita o comando
  que causou o vazamento tentando "corrigir" — pare e espere resposta.

## Convenções do repositório do projeto (automacaoUiMultiplica)

- Branch de integração: **`reviewAgents`** (nunca `reviewAgent`, no singular). `main` só recebe
  merge de `reviewAgents` em momentos de release — nunca commit/merge direto.
- O padrão de arquitetura do projeto está documentado no `README.md` e `CLAUDE.md` **do próprio
  repositório clonado** (não confundir com o `CLAUDE.md`/`docs/` do Supervisor, que é sobre como
  os agentes se organizam, não sobre a automação de UI em si).
- **Fluxo de integração (atualizado 2026-09-14, pedido explícito do Thiago):** o Agent Master faz
  merge direto (com push) de cada tarefa aprovada nos testes **na `reviewAgents`** — sem PR nem
  aprovação humana por tarefa. Ele **nunca** mergeia/dá push direto na `main`: o único ponto de
  revisão manual do Thiago é um **PR único e contínuo `reviewAgents → main`** — reflete sozinho no
  GitHub cada commit novo pusheado na `reviewAgents`; o Agent Master só garante que ele existe a
  cada ciclo (`gh pr list`/`gh pr create` se faltar), nunca recria. **Atenção: o número do PR muda**
  toda vez que o anterior é mergeado pelo Thiago e não há commit novo pendente (`gh pr create`
  falha com "No commits between main and reviewAgents" nesse caso — normal, só criar de novo depois
  do próximo push em `reviewAgents`) — não hardcode o número aqui; confira sempre com `gh pr list`.
  Histórico: PR #10 (criado 2026-09-14) foi mergeado pelo Thiago no mesmo dia; PR #11 (criado
  2026-09-14, mesmo dia, depois do push do commit `9f38a75`) é o atual em aberto. Autenticado via
  `GH_TOKEN` setado em `agent-master/run-cycle.ps1`. Modelo anterior (PR por tarefa,
  `feature/xxx → reviewAgents`, aprovado manualmente um a um) foi abandonado por ser lento demais
  para o volume de tarefas; `fila-merge/aguardando-aprovacao/` do Agent Master só existe hoje para
  terminar de processar avisos que já tinham PR aberto na troca de fluxo — ex.: PR #9
  (`feature/mop-monitor-diario-analisar-operacao`), que ficou `OPEN` até **2026-09-14** e nesse dia
  foi **MERGED** pelo Thiago (processado pelo Agent Master como legado/MERGED, aviso movido para
  `concluidos/`) — nenhum aviso novo passa mais por ali.
  - **Resolvido (2026-09-14) — docs do próprio repositório (`repo/CLAUDE.md`, `repo/README.md`)
    estavam desatualizadas:** o commit `69cc6cd` (2026-09-11, "docs: fluxo de integração volta a
    usar Pull Request, aprovado manualmente por tarefa") havia documentado o modelo **antigo** (PR
    por tarefa) como vigente, sem nunca ter sido corrigido após a mudança de 2026-09-14 acima.
    Corrigido pelo subAgent `geral` (tarefa `20260914125955-atualizar-claude-md-fluxo-integracao`,
    branch `feature/atualizar-claude-md-fluxo-integracao`): seção "Collaboration workflow" do
    `CLAUDE.md` e "Fluxo de trabalho" do `README.md` agora descrevem o fluxo atual (merge direto +
    PR único). Aviso deixado em `agent-master/fila-merge/pendentes/` para merge em `reviewAgents`.
- Arquitetura alvo: camadas Pages / Etapas / Esteiras, com Cucumber como camada fina de
  legibilidade sobre as Esteiras (não orquestra nada sozinho).

## Contas de Claude Code por agente

- Cada subAgent/Agent Master roda um `claude -p` fixado numa conta própria via
  `CLAUDE_CONFIG_DIR` (pastas em `%USERPROFILE%\.claude-accounts\<conta>`), setada no início do
  `run-cycle.ps1` antes do `claude` iniciar.
- **`contaB` é a conta padrão de tudo** (Agent Master, todo subAgent, Status Watcher) — mudou em
  2026-09-17, pedido explícito do Thiago (`contaB` é a conta pessoal dele). `contaA` só entra como
  fallback de rate-limit (ver seção 3.0 do `CLAUDE.md` do Supervisor e
  `CONHECIMENTO-SUPERVISORES.md`). Antes disso era revezamento por ordem de criação — histórico,
  não usar mais como referência de "casa" atual.

## Alternância de conta por rate-limit (pedido do Thiago, 2026-09-15)

Cada agente (subAgent, Agent Master, Status Watcher) tem uma conta "de casa" fixa (ver
atribuições acima) — mas agora, além disso, todo `run-cycle.ps1` deste Supervisor tenta usar a
conta alternativa **só no ciclo atual** quando a conta de casa está saturada, para não desperdiçar
capacidade ociosa da outra conta.

- **Como funciona:** logo após um ciclo que efetivamente chama `claude -p`, o script grava a
  última utilização conhecida da conta usada (janela `five_hour` do `rate_limit_info` que vem no
  stream NDJSON) em `%USERPROFILE%\.claude-accounts\<conta>\ultima-utilizacao.json` (funções
  `Set-UtilizacaoConta`/`Get-UtilizacaoConta` em cada `run-cycle.ps1`). Esse arquivo é um estado
  **por conta**, compartilhado entre qualquer agente/Supervisor que use aquela conta (pool
  `contaA`/`contaB` é cross-Supervisor — ver `CONHECIMENTO-SUPERVISORES.md`).
- **Antes de chamar `claude -p`** (depois da pré-checagem normal da seção 3.4, que decide SE vale a
  pena rodar o ciclo), o script lê a última utilização conhecida da sua conta de casa. Se for
  `>= 0.99` (99%) na janela `five_hour` **e** o `resetsAt` gravado ainda não tiver passado (dado
  ainda válido, a janela não resetou), tenta a conta alternativa: se ela não estiver também
  `>= 0.99`, usa a alternativa **só neste ciclo**; se as duas estiverem saturadas, segue com a
  conta de casa mesmo assim (não há alternativa melhor). Registra a decisão em `run-log.txt` com
  a tag `[alternancia]`.
- **Não persiste a troca**: no próximo ciclo, o agente sempre tenta a conta de casa primeiro de
  novo — a troca é só um fallback pontual, não uma reatribuição permanente. Decisão explícita do
  Thiago (2026-09-15): manter o modelo de conta fixa como padrão, a alternância é só para não
  desperdiçar ciclos quando a conta de casa está momentaneamente no limite.
- **Limitação conhecida**: não existe forma de consultar a utilização de uma conta sem já ter
  feito uma chamada `claude -p` nela — o valor usado na decisão é sempre o último conhecido (de
  até ~5-30min atrás, dependendo da cadência do agente que gravou por último), não uma leitura em
  tempo real. Na prática isso é uma aproximação boa o suficiente dado que os ciclos são frequentes.
- Aplicado nos 5 `run-cycle.ps1` deste Supervisor (`geral`, `mop`, `POC`, `agent-master`,
  `status-watcher`) em 2026-09-15. Os outros Supervisores (`SupAutomacaoUteis`,
  `SupTestesFrontEnd`) ainda não adotaram esse padrão — registrado também em
  `CONHECIMENTO-SUPERVISORES.md` para eles copiarem se quiserem, mas não foi aplicado nos
  `run-cycle.ps1` deles por este Supervisor.

## `.env` / variáveis de ambiente — quem cuida do quê

- O Agent Master mantém `agent-master/repo/.env` atualizado automaticamente: a cada merge, compara
  `.env.example` antes/depois para achar variáveis novas e busca o valor em
  `subagents/<modulo>/docs/documentacao.md` e/ou na tarefa concluída correspondente. Nunca inventa
  nem deixa em branco — se não achar, vira dúvida bloqueante.
- O Agent Master sincroniza `C:\multiplica\cypress-e2e` (pasta de teste manual do Thiago, mesmo
  repositório em clone separado) a cada ciclo: `npm ci`/`npm install` se necessário, e copia
  `repo/.env` por cima do `.env` de lá. **Atualizado 2026-09-14:** essa pasta agora fica sempre na
  `reviewAgents` (não há mais branch de PR-por-tarefa pra testar antes de aprovar) — mesmo
  enquanto o PR legado #9 (`feature/mop-monitor-diario-analisar-operacao`) segue `OPEN`, a pasta
  não fica mais presa à branch dele. O Thiago não precisa criar/manter esse `.env` na mão.
- **Nunca** exponha valores de variáveis de `.env` em `docs/documentacao.md`, `duvidas.md` ou em
  log de saída — só o nome da variável e de onde veio o valor.

## Armadilhas conhecidas de ambiente (Windows / Cypress)

- O cache de binário do Cypress é **global por usuário do Windows**
  (`%LOCALAPPDATA%\Cypress\Cache`), compartilhado entre **todos** os projetos da máquina — não é
  isolado por repositório. Rodar `npx cypress open`/`run` num projeto cujo `node_modules` ainda
  não tem o Cypress resolvido localmente pode disparar a instalação de uma versão diferente da
  pinada no `package.json` (já aconteceu: instalou `16.0.0` em vez da `15.20.1` pinada, causando um
  erro que parecia bug de código mas não era). Prefira versão **exata** (sem `^`) de `cypress` no
  `package.json` quando isso for um risco, e garanta que `npm ci`/`npm install` já rodou antes de
  qualquer `cypress open`/`run`.
- `cy.session`: o `setup`/`validate` só restaura cookies/localStorage — ao final, a página fica em
  `about:blank`. Sempre fazer um `cy.visit` adicional logo após o `cy.session` para que a asserção
  de "autenticado com sucesso" funcione (senão a URL fica em `about:blank` mesmo com sessão
  válida). Ver `cy.loginComoPerfil` em `commands.js` como referência já implementada.
- Widget de menu do Beyond (`mc-menu.js`, carregado de `beyond-hml.grupomultiplica.com.br`): ao
  clicar em "Beyond BackOffice" às vezes lança uma exceção não tratada própria
  (`Cannot read properties of undefined (reading 'content')`) que derruba o teste por padrão, sem
  afetar a navegação visual real. Corrigido globalmente em `cypress/support/e2e.js` com um handler
  `Cypress.on('uncaught:exception', ...)` que ignora especificamente essa mensagem (commit
  `a83b438` na branch `feature/mop-monitor-diario-analisar-operacao`, ainda sem PR). Qualquer
  módulo que navegue por esse menu já herda a correção assim que essa branch for mergeada em
  `reviewAgents`.
- **Login (`cy.loginComoPerfil`) via `cy.origin` falhou de forma consistente (3 tentativas) com
  `CypressError: cy.origin() failed to create a spec bridge...` logo após o redirect para
  `keycloak-new-2.grupomultiplica.com.br`, depois de funcionar normalmente pouco antes**: a
  suspeita inicial foi rate-limit/bloqueio de bot no Keycloak por múltiplas execuções seguidas em
  curto intervalo (~10 min), mas o Thiago avaliou como mais provável que o **ambiente HML estivesse
  instável/fora do ar** naquele momento — não confirmado como rate-limit. Se notar o mesmo erro:
  não insista em várias tentativas seguidas; registre dúvida bloqueante assumindo primeiro
  instabilidade pontual do ambiente (não rate-limit) e aguarde confirmação antes de tentar de novo
  (ver módulo `mop`, tarefa `20260911214610-monitor-diario-analisar-operacao`, para o caso
  original).
  - **Atualização (2026-09-14):** numa retomada ~3 dias depois, uma única tentativa (não em
    sequência rápida) reproduziu o **mesmo erro exato**. Isso enfraquece a hipótese de
    "instabilidade pontual do ambiente naquele momento" — o problema pode ser mais estrutural
    (config do Keycloak, certificado, CORS/CSP afetando especificamente `cy.origin`) e não ligado a
    volume/frequência de tentativas. Qualquer módulo que dependa de `cy.loginComoPerfil` deve
    considerar esse erro como possivelmente recorrente/estrutural, não só transitório, até o Thiago
    confirmar a causa. Nova dúvida bloqueante registrada (mesma tarefa `mop`), respondida pelo
    Thiago ("HML está ok agora, pode retomar").
  - **Resolvido, sem causa raiz confirmada (2026-09-14, mesmo dia):** na retomada seguinte à
    resposta do Thiago, `cy.loginComoPerfil('master')` funcionou normalmente de ponta a ponta, sem
    reproduzir o erro. A causa raiz nunca foi confirmada como rate-limit nem como algo estrutural —
    só que o erro não é permanente. Se reaparecer em outro módulo: seguir o mesmo protocolo (não
    insistir em várias tentativas seguidas, registrar dúvida bloqueante) em vez de assumir que é
    definitivo.
  - **Nova reprodução (2026-09-14, Agent Master, merge de `feature/atualizar-claude-md-fluxo-integracao`,
    só docs):** no mesmo `npm test` (mesma execução, mesmo instante, mesmo ambiente HML),
    `shared/login.feature` passou 2/2 usando `cy.loginComoPerfil` normalmente, mas
    `mop/mop-monitor-diario.feature` falhou com o erro exato de `cy.origin()` no próprio
    `cy.loginComoPerfil` do setup. Isso enfraquece ainda mais a hipótese de "ambiente HML
    instável no momento" (já que outro teste, rodado segundos depois, usou o mesmo mecanismo de
    login com sucesso) — sugere algo específico do fluxo/perfil/timing do teste do `mop`, não do
    Keycloak/HML em geral. Ainda sem causa raiz confirmada. Tratado como dúvida bloqueante (não
    retentado no mesmo ciclo), merge local desfeito, aviso mantido em
    `agent-master/fila-merge/pendentes/` — ver `agent-master/duvidas.md`
    (`20260914125955-atualizar-claude-md-fluxo-integracao`).
  - **Nova reprodução (2026-09-15, módulo `POC`, tarefa `20260915131339-criar-prospect-cedente-cnpj`):**
    mesmo erro exato (`cy.origin() failed to create a spec bridge...`) no primeiro autoteste do
    spec de produção recém-criado (`poc-criar-prospect-cedente-cnpj.feature`), logo no
    `cy.loginComoPerfil` de setup — antes de qualquer interação com a tela. Reforça que o sintoma
    não é exclusivo do `mop`; qualquer módulo que dependa de `cy.loginComoPerfil` pode encontrá-lo.
    Seguido o mesmo protocolo (não retentar no mesmo ciclo, dúvida bloqueante registrada em
    `subagents/POC/duvidas.md`).
  - **Nova reprodução, agora 2x seguidas na mesma retomada (2026-09-16, módulo `POC`, mesma
    tarefa):** com VPN confirmada ok antes de cada tentativa, o mesmo erro exato ocorreu em duas
    execuções consecutivas do mesmo spec de diagnóstico (não só uma, como em todas as ocorrências
    anteriores catalogadas acima). Diferente do padrão observado até aqui (uma falha isolada,
    resolvida com um único retry após confirmação do Thiago), essa recorrência consecutiva pode
    indicar que o sintoma nem sempre é tão transitório quanto parecia — qualquer módulo que veja
    esse erro se repetir 2x+ seguidas (não só 1x) deve registrar esse detalhe na dúvida em vez de
    assumir que é sempre resolvido só com "tenta de novo uma vez".
  - **Frequência crescente, 3 ocorrências seguidas contando as 2 últimas retomadas (2026-09-16,
    módulo `POC`, mesma tarefa):** depois das 2 falhas consecutivas acima e da autorização do
    Thiago para retry, a tentativa seguinte (1ª desta nova retomada, VPN confirmada ok antes)
    reproduziu o mesmo erro de novo. Isso desloca o padrão de "instabilidade pontual e rara" para
    "acontecendo em praticamente toda tentativa recente" — qualquer módulo que perceba esse mesmo
    aumento de frequência (não só uma recorrência isolada) deve considerar sinalizar isso
    explicitamente na dúvida (em vez de só pedir autorização de retry de novo), já que pode indicar
    que vale a pena investigar causa raiz em vez de continuar tratando como transitório. Dúvida
    registrada em `subagents/POC/duvidas.md` perguntando ao Thiago justamente isso (retry simples
    vs. investigar causa raiz), ainda sem resposta.
- **Inputs controlados por React (ex.: `input[type="date"]` do Monitor Diário do MOP) não reagem a
  `.val()`/`.type()` do jQuery/Cypress da forma ingênua** — setar o valor sem passar pelo setter
  nativo não dispara o `onChange` do React, então o componente não percebe a mudança. Solução:
  pegar o setter nativo do protótipo antes de disparar os eventos manualmente:
  ```js
  const nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set
  nativeSetter.call(input, novoValor)
  input.dispatchEvent(new Event('input', { bubbles: true }))
  input.dispatchEvent(new Event('change', { bubbles: true }))
  ```
  Útil para qualquer módulo que precise setar programaticamente um input controlado por React em
  vez de digitar caractere a caractere com `cy.type()`.
- **Resolução do vídeo gravado (`cypress/videos/*.mp4`) não bate com `viewportWidth`/
  `viewportHeight` configurado** — não é bug, é limitação do Cypress: a captura de vídeo é um
  pipeline interno separado da renderização do viewport, sem nenhuma opção de config para a
  resolução do `.mp4` (`cypress.config.js` só expõe `video`/`videoCompression`/`videosFolder`).
  Medido (lendo o box `tkhd` do `.mp4`) com viewport configurado em 1920x1080: Electron headless
  (`npm test`/`cypress run` padrão, o que qualquer Scheduled Task usa) grava em **1280x720**;
  Chrome headless (`--browser chrome --headless`) grava em **1264x624**; Electron `--headed`
  (manual) grava em **1920x982** (largura bate, altura varia por decoração de janela/DPI). O
  viewport configurado segue correto e é o que importa para a app renderizar certo durante o
  teste — só a resolução do vídeo em si sai menor que Full HD no modo headless. Qualquer módulo
  que documente/prometa "vídeo em 1920x1080" deve corrigir para não afirmar isso; documentar a
  tabela acima em vez disso (ver módulo `geral`, tarefa
  `20260914130450-resolucao-viewport-e-video-execucao`).

## Conectividade com `beyond-hml.grupomultiplica.com.br` — timeout de rede ao IP interno, distinto dos sintomas de `cy.origin` já catalogados (2026-09-15)

- Módulo `POC`, tarefa `20260915131339-criar-prospect-cedente-cnpj`: `cypress run` falhou logo no
  primeiro `cy.visit(ambiente.appBaseUrl)` (dentro do setup de `cy.session`, **antes** de qualquer
  interação com Keycloak) com `Error: connect ETIMEDOUT 10.101.10.254:443`.
- Confirmado fora do Cypress: `curl --max-time 20 https://beyond-hml.grupomultiplica.com.br/`
  também deu timeout de conexão (2 tentativas). `nslookup` mostra que `beyond-hml` resolve para um
  IP **privado** (`10.101.10.254`), enquanto `keycloak-new-2.grupomultiplica.com.br` (que respondeu
  normalmente, `403` mas conectou) resolve para IPs públicos (Cloudflare). Ou seja: o host da
  aplicação em si só é alcançável de dentro de alguma rede privada/VPN, e esse acesso estava
  indisponível no momento do teste, mesmo com internet pública/DNS funcionando normalmente.
- **Diferente dos sintomas já catalogados** (`cy.origin() failed to create a spec bridge...`,
  timeout de 60s carregando a página do Keycloak, `ResizeObserver loop...`) — todos esses ocorrem
  **depois** de alcançar a aplicação/Keycloak. Este é um bloqueio de conectividade **antes** de
  qualquer interação, ao IP interno da aplicação em si.
- Nenhuma documentação de nenhum Supervisor menciona a máquina precisar de VPN até agora — mas
  módulos anteriores (`mop`) já completaram login/navegação nesta mesma máquina com sucesso em
  outras ocasiões, então isso provavelmente é intermitente (rede/VPN instável), não uma limitação
  permanente do ambiente de execução. Se qualquer módulo notar `ETIMEDOUT` para um IP privado
  (`10.101.x.x`) ao tentar alcançar `beyond-hml` (ou qualquer outro host da aplicação), tratar como
  esse mesmo tipo de bloqueio — não confundir com os sintomas de `cy.origin`/Keycloak já
  catalogados acima, e registrar dúvida bloqueante em vez de insistir em múltiplas tentativas
  seguidas.
- **Recorrência (2026-09-15, mesma tarefa, mesma retomada):** o Thiago respondeu a dúvida original
  confirmando que era queda de VPN e que já devia estar reconectada, autorizando retentar. Na
  retomada seguinte, o exato mesmo sintoma reapareceu (`connect ETIMEDOUT 10.101.10.254:443` no
  `cypress run`; `curl --max-time 15` a `beyond-hml` deu timeout de novo, `keycloak-new-2` respondeu
  `403` normalmente) — ou seja, a reconexão de VPN não é necessariamente automática/estável nesta
  máquina, ou caiu de novo de forma independente. Seguido o mesmo protocolo: uma única checagem via
  `curl` (sem insistir em sequência), dúvida bloqueante nova registrada em vez de presumir resolvido.
  Qualquer módulo que reencontrar esse sintoma deve tratar cada ocorrência como um evento novo a
  confirmar com o Thiago, não assumir que uma resposta anterior de "já deve estar ok" cobre
  recorrências futuras.
- **Terceira recorrência (2026-09-15, módulo `POC`, mesma tarefa, retomada seguinte à confirmação de
  login OK):** depois de um ciclo em que login/navegação funcionaram normalmente (sem repetir nem
  o `cy.origin` nem o `ETIMEDOUT`), a mesma queda (`connect ETIMEDOUT 10.101.10.254:443`) voltou a
  acontecer durante uma investigação adicional na retomada seguinte, de novo confirmada com uma
  única checagem via `curl` (sem sequência de tentativas). Reforça que essa VPN/rede é instável de
  forma recorrente e intermitente nesta máquina (não é um evento isolado que, uma vez resolvido,
  fica resolvido) — todo módulo que dependa de `beyond-hml` deve continuar tratando cada nova
  ocorrência como um evento a confirmar, mesmo depois de várias reconexões bem-sucedidas
  anteriores.

## Git — branch nova pode não aparecer sem `fetch`

- Um checkout local (`repo/` do Agent Master ou de um subAgent) pode não listar uma branch remota
  recém-criada em `git branch -a` até rodar `git fetch` (`--prune` para também limpar branches
  remotas apagadas). Isso já causou confusão real (2026-09-14, módulo `mop`, tarefa
  `20260911214610-monitor-diario-analisar-operacao`): o aviso já estava em
  `fila-merge/pendentes/` referenciando a branch, mas ela só apareceu depois do fetch. Sempre dar
  `git fetch` (ou `--prune`) antes de concluir que uma branch referenciada não existe.

## Tarefas que não cabem em um ciclo (retomada)

- Um ciclo de subAgent roda `claude -p` uma única vez; tarefas que exigem investigação ao vivo de
  tela (sem prints/spec prontos, ex.: descobrir seletores de uma tela nova) podem esgotar o ciclo
  antes de terminar. Isso já aconteceu (módulo `mop`, tarefa do Monitor Diário): o ciclo terminou
  com a tarefa ainda em `tarefas/executando/`, uma branch criada, mas nada commitado.
- Por isso a regra "se `executando/` já tiver uma tarefa" agora é **retomar**, não encerrar o
  ciclo: o subAgent deve procurar uma branch já criada para aquela tarefa em `repo/` e continuar
  de onde parou, em vez de ficar preso para sempre (a versão antiga da regra travava a tarefa
  indefinidamente, já que nada nunca movia ela de volta para `pendentes/`).
- Consequência prática: ao implementar algo que pode não caber num ciclo só, sempre faça commit do
  progresso parcial na branch antes do ciclo terminar — nunca deixe só em arquivos não commitados
  (o próximo ciclo não teria como saber o que já foi descoberto/feito).
- **Nunca inicie um processo em segundo plano (ex.: `cypress open`, `cypress run` em background) e
  encerre o ciclo "esperando ele terminar depois"** — isso já aconteceu (mesma tarefa do `mop`) e
  trava a tarefa para sempre, porque o processo em segundo plano não sobrevive entre ciclos (cada
  ciclo é uma execução nova e isolada do `claude -p`; nada do que ficou rodando em background
  continua quando o processo termina). Qualquer comando de investigação/teste deve ser executado
  de forma síncrona (aguardar terminar) dentro do próprio ciclo. Se mesmo assim não der tempo de
  terminar a tarefa, faça commit do progresso parcial e pare — nunca apenas diga "continuo depois"
  sem persistir nada de concreto.

## GitHub CLI (`gh`) — usado pelo Agent Master para abrir PR

- Instalado como versão portátil em `%LOCALAPPDATA%\Programs\gh\bin\gh.exe` (sem precisar de
  admin/UAC — o instalador `.msi` padrão exige elevação e falha nesta máquina).
- Autenticado via variável de ambiente `GH_TOKEN` (não via `gh auth login` — essa versão do `gh`
  tem um bug validando token fine-grained (`github_pat_...`) nesse fluxo; `GH_TOKEN` funciona
  normalmente). O token está setado dentro de `agent-master/run-cycle.ps1` (acesso total aos
  repositórios, sem expiração) — nunca exponha esse valor em documentação/log.
- Só o Agent Master precisa de `gh` (é ele quem abre/consulta PRs); subAgents de módulo não usam.
- **`gh pr list`/`gh pr view` retornam `[]`/vazio silenciosamente (sem erro) se o cwd não estiver
  dentro do clone git correto** (ex.: rodar de `agent-master/` em vez de `agent-master/repo/`) — o
  `gh` detecta o repositório pelo `remote` do diretório atual, não por config global; mesmo com
  `GH_TOKEN` válido e `gh auth status` OK, o comando "funciona" sem erro mas não acha nada. Sempre
  rodar comandos `gh pr *`/`gh repo *` com cwd dentro de `repo/` (2026-09-15, Agent Master).
- **Risco de exposição do `GH_TOKEN` via log em tempo real (2026-09-14):** como o `run-cycle.ps1`
  agora grava o `stream-json` do ciclo em tempo real em `run-log.txt` (ver seção "Scheduled Tasks"
  abaixo), qualquer comando de shell que ecoe/imprima uma variável de ambiente sensível (ex.: um
  `echo $GH_TOKEN` de diagnóstico, mesmo que acidental por erro de quoting) fica gravado em texto
  puro no log. Já aconteceu uma vez (Agent Master, ciclo de 2026-09-14) — token não foi rotacionado
  ainda, dúvida bloqueante registrada em `agent-master/duvidas.md`. **Nunca rode comandos que
  imprimam o valor de `GH_TOKEN` (ou qualquer segredo) no stdout/stderr**, nem para "confirmar que
  está setado" — use `gh auth status` (mascara o token) se precisar verificar autenticação.

## Git — checkout local de `main` pode ficar obsoleto sem ninguém perceber (2026-09-14)

- Como o Agent Master nunca faz checkout de `main` (só mergeia/push em `reviewAgents`), o `git
  fetch` atualiza `origin/main` mas **não** avança o ponteiro local do branch `main` — ele só se
  move com checkout explícito ou `git branch -f main origin/main`/merge. Isso já causou uma
  medição errada de "quantos commits `reviewAgents` está à frente de `main`" num ciclo (`main`
  local ainda em `0492943`, 8 commits atrás do `origin/main` real em `50542bb`, mesmo depois de
  `git fetch --prune`). Antes de comparar `main..reviewAgents` (p.ex. pra decidir se cria o PR
  único), confirme que o `main` local está em dia com `origin/main`
  (`git merge-base --is-ancestor main origin/main` deve dar sucesso; se sim, é seguro
  `git branch -f main origin/main` antes de comparar).

## HML/login — mais sintomas de instabilidade além do já catalogado `cy.origin` (2026-09-14)

- Além do erro de `cy.origin() failed to create a spec bridge` já documentado acima, apareceu um
  sintoma **diferente** no mesmo teste (`shared/login.feature`, `cy.loginComoPerfil`): `CypressError:
  Timed out after waiting 60000ms for your remote page to load` (a página do Keycloak nem chegou a
  carregar). Rodando de novo minutos depois (mesma máquina, mesmo ambiente), o teste passou 2/2 sem
  repetir o erro — reforça que o HML segue instável/intermitente de formas variadas (não é sempre o
  mesmo sintoma), então qualquer falha de login em qualquer módulo deve ser tratada com a mesma
  cautela já registrada (dúvida bloqueante, não insistir em sequência), mesmo que a mensagem de erro
  não bata exatamente com uma já vista antes.
- **Novo erro não catalogado em `mop/mop-monitor-diario.feature`:** `Error: The following error
  originated from your application code, not from Cypress. > ResizeObserver loop completed with
  undelivered notifications.`, disparado em `https://beyond-hml.grupomultiplica.com.br/mop/monitor`
  e derrubando o teste (Cypress falha por padrão em qualquer `uncaught:exception`). É diferente do
  erro do widget de menu do Beyond (`Cannot read properties of undefined (reading 'content')`) já
  tratado em `cypress/support/e2e.js` — esse aqui **não** está coberto pelo handler existente.
  "ResizeObserver loop..." é um erro de browser conhecido por ser inofensivo/ruído (comum em telas
  com layout dinâmico), mas nenhum agente deve decidir sozinho estender o handler de
  `uncaught:exception` sem confirmação do Thiago — registrado como dúvida bloqueante pelo Agent
  Master (ver `agent-master/duvidas.md`,
  `20260914130450-resolucao-viewport-e-video-execucao`). Qualquer módulo que navegue pela mesma
  tela do Monitor Diário do MOP pode reproduzir esse mesmo erro até isso ser resolvido.
- **Atualização (2026-09-14, Agent Master, ciclo de retomada dos dois avisos que ficavam
  bloqueados esperando resposta):** depois do Thiago responder "é instabilidade pontual, tente de
  novo" pras duas dúvidas pendentes, o Agent Master retentou (uma vez cada, sem sequência rápida) o
  merge de teste local das duas branches (`feature/atualizar-claude-md-fluxo-integracao` e
  `feature/resolucao-viewport-e-video-execucao`, ambas só docs/config, sem tocar
  `cypress/e2e/**`). Resultado: `mop/mop-monitor-diario.feature` falhou nas **duas**, com **dois
  sintomas diferentes** (`cy.origin()` failed to create a spec bridge numa, `ResizeObserver loop...`
  na outra); `shared/login.feature` passou 2/2 nas duas. Isso enfraquece bastante a hipótese de
  "instabilidade genérica do HML" (que sugeriria falha aleatória em qualquer teste) — o padrão
  observado até agora é: `mop-monitor-diario.feature` falha quase sempre que roda nesses ciclos,
  `login.feature` praticamente nunca falha. Sugere algo mais específico daquele teste/tela (timing,
  performance, ou um problema real na implementação) do que instabilidade de rede/Keycloak
  genérica. Duas dúvidas foram reabertas em `agent-master/duvidas.md`
  (`20260914125955-atualizar-claude-md-fluxo-integracao` e
  `20260914130450-resolucao-viewport-e-video-execucao`) pedindo ao Thiago uma decisão definitiva
  (não mais "tente de novo"): autorizar estender o handler de `uncaught:exception` para
  `ResizeObserver loop...`, e/ou autorizar não bloquear merges só-docs/config por falha isolada
  nesse teste específico. Qualquer agente que veja `mop-monitor-diario.feature` falhar de novo deve
  registrar o sintoma exato (os já vistos até agora: `cy.origin() failed to create a spec
  bridge...`, `Timed out after waiting 60000ms for your remote page to load`, `ResizeObserver loop
  completed with undelivered notifications`) em vez de assumir que é sempre o mesmo problema.
- **Resolvido (2026-09-14) — `ResizeObserver loop...` agora tratado como `uncaught:exception`
  conhecido, autorizado pelo Thiago:** resposta à dúvida
  `20260914130450-resolucao-viewport-e-video-execucao` autorizou opção (a) — estender o handler em
  `cypress/support/e2e.js` (mesmo padrão já usado pro erro do widget de menu do Beyond) para também
  ignorar `ResizeObserver loop completed with undelivered notifications`. Aplicado pelo Agent
  Master diretamente na branch `feature/resolucao-viewport-e-video-execucao` (commit `a2f2d88`)
  antes de redar o merge de teste; `npm test` rodado uma única vez após a mudança:
  `mop-monitor-diario.feature` (1/1) e `login.feature` (2/2) passaram. Merge finalizado e pushado em
  `reviewAgents` (`9f38a75`). **Atenção:** essa única execução limpa **não** confirma causa raiz — o
  handler cobre o sintoma `ResizeObserver`, mas os outros dois sintomas já catalogados
  (`cy.origin()` failed to create a spec bridge, timeout de carregamento de página) não têm relação
  com esse handler e podem reaparecer. A pergunta em aberto sobre tolerar falha do
  `mop-monitor-diario.feature` em merges só-docs/config (tarefa
  `20260914125955-atualizar-claude-md-fluxo-integracao`) **segue não respondida** — não foi decidida
  por esta resolução.

## Scheduled Tasks (Windows Task Scheduler)

- `SupE2eAutomation-SubAgent-<modulo>`: a cada 15 min.
- `SupE2eAutomation-AgentMaster`: a cada 30 min.
- `SupE2eAutomation-StatusWatcher`: a cada 15 min (somente leitura + notificação, nunca mexe em
  `repo/`; ver seção 7 do `CLAUDE.md` do Supervisor).
- Todas via `run-cycle.ps1` de cada pasta, chamando `powershell.exe -NoProfile -NonInteractive
  -ExecutionPolicy Bypass -WindowStyle Hidden -File <script>`, com `claude -p ... --permission-mode
  bypassPermissions --output-format stream-json --verbose`, log em `run-log.txt` na própria pasta.
- **Log em tempo real (2026-09-14, a pedido do Thiago):** trocado de `--output-format text` (só
  grava no fim do ciclo) para `stream-json --verbose` piped para um `ForEach-Object` que formata
  cada evento NDJSON em uma linha legível (`[sessao]`/`[fala]`/`[tool]`/`[resultado]`/`[ciclo
  encerrado]`) e grava em `run-log.txt` assim que acontece — dá pra ver o progresso real olhando o
  log durante a execução. Ver detalhe completo em `CONHECIMENTO-SUPERVISORES.md` (mudança feita
  pelo Sup AutomaçãoUteis nos `run-cycle.ps1` dos dois Supervisores).

## Remote `origin` de `C:\multiplica\cypress-e2e` ainda aponta pro nome antigo do repositório (2026-09-15)

- O clone de teste manual do Thiago (`C:\multiplica\cypress-e2e`) tem `origin` configurado como
  `git@github.com:Thiagocs12/automacaoMultiplica.git` (nome antigo), enquanto todo o resto (ex.:
  `agent-master/repo/`, `subagents/<modulo>/repo/`) usa
  `https://github.com/Thiagocs12/automacaoUiMultiplica.git` (nome atual, pós-rename). Verificado
  que não há divergência de conteúdo hoje (`git rev-parse reviewAgents` bateu o mesmo hash nas duas
  URLs) — o GitHub redireciona automaticamente pull/fetch/push do nome antigo pro repositório
  renomeado. Não é um problema agora, mas **se o Thiago um dia liberar/reutilizar o nome antigo no
  GitHub, esse redirect quebra** e qualquer `git pull`/`fetch` feito contra essa URL (só a pasta
  `cypress-e2e`, que não é gerenciada por nenhum agente/repo/) passaria a falhar. Se algum agente
  notar erro de fetch/clone inesperado nessa pasta específica, checar primeiro se é isso antes de
  tratar como bug — a correção seria só `git remote set-url origin
  https://github.com/Thiagocs12/automacaoUiMultiplica.git` nessa pasta.

## Pré-checagem (seção 3.4) não distingue "pendente normal" de "pendente deliberadamente parado" (2026-09-15)

- Quando o Thiago responde uma dúvida bloqueante dizendo "não reprocesse automaticamente até eu
  trazer instrução nova" mas o item continua fisicamente em `fila-merge/pendentes/` (Agent Master)
  ou `tarefas/pendentes/` (subAgent) — em vez de ser movido para um estado de espera — a
  pré-checagem em PowerShell da seção 3.4 do `CLAUDE.md` continua achando "há arquivo em
  pendentes/" e chamando o `claude -p` a cada ciclo, mesmo que a resposta já registrada diga
  explicitamente para não fazer nada. Isso já gerou **21 ciclos idênticos** de "nada a fazer" num
  único dia (Agent Master, aviso `20260914125955-atualizar-claude-md-fluxo-integracao`, ver
  `agent-master/docs/documentacao.md`) — gasto de invocação/rate-limit sem trabalho real, além de
  inflar o log e a documentação com entradas repetidas.
- Dúvida registrada pedindo decisão do Thiago (`agent-master/duvidas.md`,
  `20260915-ciclos-vazios-fila-merge-pendentes`): ajustar a pré-checagem para também tratar como
  "sem novidade" um item cuja resposta mais recente instrua explicitamente a não reprocessar (só
  volta a chamar o Claude quando houver resposta nova), aceitar o custo, ou mover esse tipo de item
  para uma pasta de espera própria enquanto aguarda instrução.
- Até essa decisão: qualquer agente (subAgent ou Agent Master) que receber uma resposta do tipo
  "não reprocesse automaticamente, aguarde instrução nova" para um item que continua em
  `pendentes/` deve esperar o mesmo padrão de ciclos vazios repetidos se depender só da
  pré-checagem por existência de arquivo — não é bug do ciclo em si, é uma lacuna conhecida da
  pré-checagem.

## `mop/mop-monitor-diario.feature` — terceiro sintoma catalogado: botão desabilitado (`Mui-disabled`) (2026-09-15)

- Depois do Thiago liberar o aviso `20260914125955-atualizar-claude-md-fluxo-integracao` de
  `fila-merge/pausados/` para nova tentativa, o Agent Master rodou `npm test` uma única vez contra
  o merge de teste local (branch só docs, sem tocar `cypress/e2e/**`): `shared/login.feature` 2/2
  passando, mas `mop/mop-monitor-diario.feature` falhou de novo com um sintoma **diferente dos dois
  já catalogados** (`cy.origin() failed to create a spec bridge`, `ResizeObserver loop...`):
  `CypressError: Timed out retrying after 4050ms: cy.click() failed because this element is
  disabled`, num botão `Mui-disabled` na tela "Analisar uma operação que não está em Inclusão OPE".
- Diferença importante: os dois primeiros sintomas ocorriam durante o **login**
  (`cy.loginComoPerfil`/Keycloak) — compatível com instabilidade de rede/HML. Este terceiro ocorre
  **depois** do login, numa interação de UI dentro da própria tela do Monitor Diário — um botão
  aparecer desabilitado quando o teste espera clicável soa mais a um problema de
  timing/estado real da aplicação ou do teste (ex.: uma condição que habilita o botão ainda não
  foi satisfeita no momento do `cy.click()`) do que a instabilidade genérica de rede já suspeitada
  antes. Reforça ainda mais o padrão já observado: `mop-monitor-diario.feature` falha quase sempre
  que roda nesses ciclos, `login.feature` quase nunca falha — mas agora com um sintoma que aponta
  para dentro da própria tela/teste do MOP, não para o Keycloak.
- Sintomas de `mop-monitor-diario.feature` catalogados até agora (registrar o sintoma exato sempre
  que reaparecer, em vez de assumir que é sempre o mesmo problema): `cy.origin() failed to create a
  spec bridge...` (durante login), `ResizeObserver loop completed with undelivered notifications`
  (já tratado como `uncaught:exception` conhecido desde `a2f2d88`), e agora `cy.click() failed
  because this element is disabled` (`Mui-disabled`, depois do login, dentro da tela).
- Nova dúvida bloqueante registrada pelo Agent Master (`agent-master/duvidas.md`,
  `20260914125955-atualizar-claude-md-fluxo-integracao`, "retomada 2") — merge local desfeito, aviso
  mantido em `fila-merge/pendentes/`. Ainda sem causa raiz confirmada; o Thiago mencionou que ia
  investigar por conta própria o `cy.origin`/`mop-monitor-diario.feature` — este novo sintoma pode
  ser relevante para essa investigação. Qualquer módulo que dependa dessa tela deve considerar que o
  teste pode falhar por qualquer um dos três motivos acima até a causa raiz ser resolvida.

## Bug em `Test-DuvidaRespondida` (run-cycle.ps1): considera um id "respondido" para sempre após a 1ª rodada, ignorando rodadas posteriores ainda pendentes (achado pelo `POC`, 2026-09-16)

- Contexto: o commit `41eafa6` moveu a triagem mecânica da fila (dúvida respondida → volta pra
  `pendentes/`) do prompt do Claude pro `run-cycle.ps1`, via função `Test-DuvidaRespondida`. Essa
  função divide `duvidas.md` em blocos por `## ` e, no `foreach`, dá `return` no **primeiro** bloco
  cujo cabeçalho bate com o id da tarefa.
- **Problema:** tarefas que passam por várias rodadas de dúvida sob o **mesmo id** (padrão comum
  neste projeto — ex.: a tarefa `20260915131339-criar-prospect-cedente-cnpj` do módulo `POC` já
  teve 9 rodadas) sempre têm seu primeiro bloco como o mais antigo. Uma vez que essa 1ª pergunta é
  respondida, `Test-DuvidaRespondida` retorna `true` **para sempre** para aquele id, mesmo que a
  2ª, 3ª... 9ª rodada estejam `Status: pendente`. Isso fez a tarefa do `POC` ser movida
  automaticamente `aguardando-resposta/` → `pendentes/` → `executando/` sem que a pergunta mais
  recente (real bloqueio) tivesse sido respondida pelo Thiago.
- **Risco:** qualquer módulo/Agent Master cuja tarefa acumule mais de uma rodada de dúvida sob o
  mesmo id está sujeito ao mesmo falso positivo — o subAgent pode ser instruído a "retomar" uma
  tarefa cuja dúvida real continua pendente, arriscando agir sem a resposta do Thiago (evitado no
  caso do `POC` só porque a regra 9 do `AGENTE.md`/instrução do ciclo exige nunca responder a
  própria dúvida, então o subAgent notou a inconsistência antes de agir — mas nem todo prompt
  necessariamente pega esse caso).
- **Correção sugerida (não aplicada ainda — script compartilhado, copiado em cada
  subAgent/Agent Master/Status Watcher; melhor coordenar a correção de uma vez em todas as cópias
  em vez de cada subAgent corrigir a sua isoladamente):** iterar os blocos em ordem reversa (ou usar
  `Where-Object`/`Select-Object -Last 1` sobre todos os blocos que batem com o id) para checar o
  `Status:` do bloco **mais recente**, não do primeiro.
- Até a correção: qualquer agente que encontrar uma tarefa recém-movida para `pendentes/`/
  `executando/` por essa pré-checagem, numa tarefa com múltiplas rodadas de dúvida sob o mesmo id,
  deve conferir manualmente se a rodada **mais recente** em `duvidas.md` está mesmo
  `Status: respondida` antes de agir — não confiar cegamente na movimentação mecânica nesse caso
  específico.
- **Recorrência (2026-09-16, módulo `POC`, mesma tarefa, retomada seguinte):** o mesmo bug moveu a
  tarefa de volta para `tarefas/executando/` de novo, com a pergunta mais recente (10ª rodada, sobre
  insistir em retry de login vs. investigar causa raiz) ainda `Status: pendente`. Confirma que a
  correção ainda não foi aplicada e que o falso positivo não é um evento isolado — reforça que
  qualquer módulo com múltiplas rodadas de dúvida sob o mesmo id deve continuar conferindo
  manualmente a cada retomada, não só na primeira vez que notar o problema. O subAgent `POC` seguiu
  o mesmo protocolo já estabelecido: não tocou em `repo/`, não rodou Cypress, não respondeu a dúvida
  sozinho, apenas moveu o arquivo de volta para `tarefas/aguardando-resposta/`.

## `cy.origin()`/spec bridge — `shared/login.feature` passa de forma confiável enquanto outro spec com o mesmo comando falha no mesmo ciclo (achado pelo `POC`, 2026-09-17)

- Contexto: o Thiago já havia atribuído as falhas recorrentes de `cy.origin() failed to create a
  spec bridge...` (ver seção acima, "HML/login") a instabilidade pontual do ambiente HML, mas
  condicionou: se o mesmo sintoma voltasse a se repetir com essa frequência mesmo com o ambiente
  já confirmado estável, deveria ser tratado como suspeita de causa raiz nova, não mais
  instabilidade pontual.
- **Retomada 2026-09-17, módulo `POC`, tarefa `20260915131339-criar-prospect-cedente-cnpj`:** com
  VPN/ambiente confirmado ok via `curl` (`beyond-hml` respondeu `200` em ~0.4s, nada de lento),
  rodei em sequência no mesmo ciclo: (1) spec de diagnóstico `_scratch/diagnostico-campos-habilitam.feature`
  → falhou no login com `cy.origin()`; (2) `shared/login.feature` (mesma máquina, minutos depois)
  → **passou 2/2**, sem nenhum erro; (3) spec de produção `poc/poc-criar-prospect-cedente-cnpj.feature`
  → **falhou de novo**, mesmo erro exato, mesmo ponto (dentro do `cy.session`/setup do
  `cy.loginComoPerfil`, antes de qualquer interação com a tela).
- **Por que isso é relevante além do `POC`:** os dois specs do `POC` usam exatamente o mesmo
  comando `cy.loginComoPerfil('master')` que `login.feature` usa (mesmo `commands.js`, mesmo
  `cy.session`/`cy.origin`). Comparei o código até a chamada de login nos dois fluxos e não
  encontrei diferença de comando Cypress antes dela. Isso enfraquece a hipótese de "instabilidade
  genérica do ambiente HML/Keycloak" (que faria `login.feature` falhar também, já que ele bate no
  mesmo Keycloak) e é o **mesmo padrão já visto antes com `mop/mop-monitor-diario.feature`** (ver
  seção "HML/login" acima, atualização de 2026-09-14: `login.feature` passa quase sempre,
  `mop-monitor-diario.feature` falha quase sempre, no mesmo `npm test`). Ou seja, já são dois
  módulos diferentes (`mop` e `POC`) mostrando o mesmo padrão de "`login.feature` isolado é
  confiável, mas outro spec que também loga falha no mesmo ciclo" — reforça que pode não ser
  instabilidade de rede/Keycloak genérica, e sim algo específico de como/quando outros specs
  disparam o `cy.origin()` (timing, ordem de specs, algo no próprio spec bridge do Cypress).
  Nenhuma causa raiz confirmada ainda.
- Nova dúvida bloqueante registrada pelo `POC` (`subagents/POC/duvidas.md`,
  `20260915131339-criar-prospect-cedente-cnpj`, ainda `Status: pendente`) com essa evidência
  comparativa completa, pedindo decisão do Thiago. Qualquer módulo que veja `login.feature` passar
  isoladamente enquanto seu próprio spec falha com `cy.origin()` no mesmo ciclo deve registrar essa
  mesma comparação (não assumir só "ambiente instável") e referenciar este achado.

## Vídeo substituído por relatório em PDF por cenário (módulo `geral`, tarefa `20260917111432-migrar-video-para-relatorio-pdf`, 2026-09-17)

- **Infra cross-módulo nova, disponível para qualquer Etapa:** `cypress.config.js` agora tem
  `video: false`. `cypress/support/etapas/EtapaBase.js` ganhou `this.passo(descricao, acao)` —
  tira `cy.screenshot` antes/depois de rodar `acao()`, nomeando o arquivo com o cenário (via
  `Cypress.currentTest.title`) + número do passo. Um novo `scripts/gerar-relatorio-pdf.cjs`
  (dependência `pdfkit`) agrupa esses screenshots por cenário e gera `relatorios/<cenario>.pdf`
  automaticamente depois de `npm test` (também via `npm run relatorio`). `relatorios/*.pdf` é
  **versionado** (não gitignored); `cypress/screenshots/` segue gitignored. Detalhe completo em
  `repo/CLAUDE.md` (seção "PDF execution report") e em `subagents/geral/docs/documentacao.md`.
  **Qualquer módulo (POC, mop, futuros) que queira o mesmo relatório visual só precisa envolver as
  ações relevantes de `executar()` em `this.passo(...)` em vez de chamar a Page direto** — só
  `EtapaAnalisarOperacaoMonitorDiario` (mop) foi migrada até agora, como referência.
- **Novo sintoma catalogado em `mop/mop-monitor-diario.feature`** (autoteste desta tarefa,
  2026-09-17): `CypressError: cy.click() failed because this element ... is being covered by
  another element: <div class="menu-MuiBackdrop-root" ...>` — ocorreu dentro de
  `MonitorDiarioPage.navegarAte()` (clique num item de menu do Beyond enquanto um backdrop de
  transição/overlay ainda cobria o elemento). Diferente dos três sintomas já catalogados na seção
  "HML/login" acima (`cy.origin()` failed to create a spec bridge, `ResizeObserver loop...`,
  `cy.click()` em botão `Mui-disabled`) — este é um problema de timing de UI (clique disparado
  antes do backdrop/transição do menu terminar), não de rede/Keycloak nem de estado de botão.
  Reforça, mais uma vez, que `mop-monitor-diario.feature` segue instável de formas variadas; não
  investigado a fundo aqui (fora do escopo desta tarefa, que era só sobre vídeo→PDF) — registrar o
  sintoma exato sempre que reaparecer, como já orientado acima.

## Novo sintoma de login + `shared/login.feature` deixa de ser confiável isoladamente (Agent Master, merge de teste de `migrar-video-para-relatorio-pdf`, 2026-09-17)

- **Sintoma novo, não catalogado até agora:** `AssertionError: Timed out retrying after 15000ms:
  expected '...keycloak-new-2.grupomultiplica.com.br/auth/realms/.../login-actions/authenticate...'
  to include 'https://beyond-hml.grupomultiplica.com.br/'` — depois de submeter credenciais no
  Keycloak, a página **nunca redireciona de volta** para `beyond-hml`, ficando presa na própria URL
  do Keycloak. Ocorreu dentro do `cy.session`/`cy.loginComoPerfil`, mesmo ponto dos sintomas já
  catalogados (`cy.origin() failed to create a spec bridge`, timeout de 60s carregando a página do
  Keycloak, `ETIMEDOUT` de rede) — mas a mensagem de erro em si é diferente de todos eles.
- **Contradiz a hipótese registrada horas antes na seção acima** ("`shared/login.feature` passa de
  forma confiável enquanto outro spec com o mesmo comando falha"): neste ciclo do Agent Master
  (merge de teste local de `feature/migrar-video-para-relatorio-pdf` contra `reviewAgents`, `npm
  test` com 2 specs), **`shared/login.feature` também falhou** — o cenário "Login com credenciais
  válidas" reproduziu o sintoma acima, e `mop/mop-monitor-diario.feature` falhou no mesmo ponto,
  com o mesmo sintoma. É a primeira vez registrada em que `login.feature` falha no mesmo ciclo que
  outro spec de login — todas as ocorrências anteriores (`mop`, `POC`) mostravam `login.feature`
  passando 2/2 de forma confiável. Isso enfraquece a teoria de "algo específico de timing/ordem de
  outros specs" e reabre a possibilidade de instabilidade genérica do Keycloak/HML (ou algo mudou no
  ambiente entre as ocorrências do mesmo dia).
- A mudança sendo testada (vídeo→PDF, `EtapaBase.passo()`, `gerar-relatorio-pdf.cjs`) não toca em
  login/Keycloak/`cy.session` — não parece ser a causa, mas o merge de teste ficou bloqueado mesmo
  assim (protocolo padrão: não decidir sozinho, não insistir em sequência).
- Dúvida bloqueante registrada em `agent-master/duvidas.md`
  (`20260917111432-migrar-video-para-relatorio-pdf`), merge local desfeito, aviso mantido em
  `agent-master/fila-merge/pendentes/`. Qualquer módulo que use `cy.loginComoPerfil`/`cy.session`
  deve considerar, a partir de agora, que **mesmo `login.feature` isolado pode falhar** — não usar
  mais "login.feature passou" como evidência definitiva de que o problema é específico de outro
  spec/timing, sem checar a data/hora e comparar com este registro.
