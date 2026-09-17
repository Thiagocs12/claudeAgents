# Histórico — conhecimento-geral.md (arquivado)

Este arquivo guarda o conteúdo histórico/resolvido/superado que foi retirado de
`conhecimento-geral.md` para manter aquele arquivo enxuto (ele é relido INTEIRO a cada ciclo por
todo agente). Nada foi descartado — só movido para cá. Organizado na mesma ordem/seção do arquivo
original, com a data de arquivamento: **2026-09-17**.

## Segurança — GH_TOKEN: narrativa do incidente original (2026-09-14)

(A regra em si — nunca ecoar `GH_TOKEN`/secrets em comando de diagnóstico — permanece no arquivo
principal. Abaixo, a narrativa completa do incidente que motivou a regra.)

- Um comando de diagnóstico rodado pelo Agent Master (erro de sintaxe/quoting, não foi uma tarefa)
  ecoou o `GH_TOKEN` completo em texto puro na saída, que foi parar em `agent-master/run-log.txt`
  (o log em streaming grava literalmente o que passa pelo stdout/stderr do ciclo). Token tinha
  acesso total aos repositórios e não expira — ficou exposto até o Supervisor redigir o log e o
  Thiago revogar/rotacionar no GitHub.

## Convenções do repositório — evolução do fluxo de integração (PRs, números específicos)

(O estado atual do fluxo — merge direto do Agent Master na `reviewAgents`, PR único e contínuo
`reviewAgents → main`, não hardcodear número de PR — permanece no arquivo principal. Abaixo, a
narrativa completa com números de PR e datas específicas, hoje só histórico.)

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

## Armadilhas conhecidas de ambiente — detalhe original do fix do widget de menu do Beyond

- Widget de menu do Beyond (`mc-menu.js`, carregado de `beyond-hml.grupomultiplica.com.br`): ao
  clicar em "Beyond BackOffice" às vezes lança uma exceção não tratada própria
  (`Cannot read properties of undefined (reading 'content')`) que derruba o teste por padrão, sem
  afetar a navegação visual real. Corrigido globalmente em `cypress/support/e2e.js` com um handler
  `Cypress.on('uncaught:exception', ...)` que ignora especificamente essa mensagem (commit
  `a83b438` na branch `feature/mop-monitor-diario-analisar-operacao`, ainda sem PR **no momento em
  que isso foi escrito**). Qualquer módulo que navegue por esse menu já herda a correção assim que
  essa branch for mergeada em `reviewAgents`.

## Armadilhas conhecidas de ambiente — saga completa de instabilidade de login (`cy.origin`), 2026-09-14 a 2026-09-16

(Consolidado no arquivo principal em "Instabilidade de login/HML — catálogo de sintomas e estado
da investigação". Abaixo, a narrativa completa com todas as datas/recorrências.)

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

## Armadilhas conhecidas de ambiente — resolução do vídeo gravado (superado, vídeo desativado em 2026-09-17)

(Todo este achado ficou sem efeito prático desde que `cypress.config.js` passou a ter `video:
false` — ver "Vídeo substituído por relatório em PDF" no arquivo principal. Mantido aqui só como
registro histórico da medição.)

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

## Conectividade com `beyond-hml.grupomultiplica.com.br` — timeout de rede ao IP interno (narrativa completa, 2026-09-15)

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

## GitHub CLI (`gh`) — risco de exposição do `GH_TOKEN` via log em tempo real (narrativa completa, 2026-09-14)

- **Risco de exposição do `GH_TOKEN` via log em tempo real (2026-09-14):** como o `run-cycle.ps1`
  agora grava o `stream-json` do ciclo em tempo real em `run-log.txt` (ver seção "Scheduled Tasks"
  no arquivo principal), qualquer comando de shell que ecoe/imprima uma variável de ambiente
  sensível (ex.: um `echo $GH_TOKEN` de diagnóstico, mesmo que acidental por erro de quoting) fica
  gravado em texto puro no log. Já aconteceu uma vez (Agent Master, ciclo de 2026-09-14) — token
  não foi rotacionado ainda, dúvida bloqueante registrada em `agent-master/duvidas.md`. **Nunca
  rode comandos que imprimam o valor de `GH_TOKEN` (ou qualquer segredo) no stdout/stderr**, nem
  para "confirmar que está setado" — use `gh auth status` (mascara o token) se precisar verificar
  autenticação.

## HML/login — mais sintomas de instabilidade além do já catalogado `cy.origin` (narrativa completa, 2026-09-14)

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

## Pré-checagem (seção 3.4) não distingue "pendente normal" de "pendente deliberadamente parado" (narrativa completa, 2026-09-15)

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

## `mop/mop-monitor-diario.feature` — terceiro sintoma catalogado: botão desabilitado (`Mui-disabled`) (narrativa completa, 2026-09-15)

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

## Bug em `Test-DuvidaRespondida` (run-cycle.ps1) — narrativa completa (achado pelo `POC`, 2026-09-16)

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

## `cy.origin()`/spec bridge — `shared/login.feature` passa de forma confiável enquanto outro spec com o mesmo comando falha no mesmo ciclo (narrativa completa, achado pelo `POC`, 2026-09-17)

- Contexto: o Thiago já havia atribuído as falhas recorrentes de `cy.origin() failed to create a
  spec bridge...` (ver seção "HML/login" acima) a instabilidade pontual do ambiente HML, mas
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
  - **Nota (arquivamento 2026-09-17):** esta hipótese foi CONTRADITA no mesmo dia por um ciclo do
    Agent Master em que `login.feature` também falhou — ver bloco seguinte e o resumo no arquivo
    principal.

## Novo sintoma de login + `shared/login.feature` deixa de ser confiável isoladamente (narrativa completa, Agent Master, merge de teste de `migrar-video-para-relatorio-pdf`, 2026-09-17)

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
