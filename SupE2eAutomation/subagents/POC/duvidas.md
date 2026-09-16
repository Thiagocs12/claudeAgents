## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Na tela "Novo Prospect" (`/prospeccao/form`), preenchendo só o CNPJ `67.903.430/0001-94`
e clicando "Salvar", a consulta do CNPJ NÃO preenche automaticamente os demais dados como esperado
— três campos continuam vazios e são obrigatórios (a tela mostra "Campo Obrigatório" em cada um ao
tentar salvar):
- `Tipo de Prospect` (select/autocomplete). Opções disponíveis: PROSPECT, ÂNCORA, PROSPECT PESSOA
  FÍSICA, PROSPECT CLAIM - PF, PROSPECT CLAIM - PJ, FORNECEDOR RISCO SACADO, PROCESSO CLAIM, TESTE,
  Prospect 2, NOVA - LARCA, PRÉ-LIMITE, COMITÊ PERFORMADO, LIMITE HOMOLOGADO.
- `Agente Comercial` (autocomplete de ~26 pessoas). Existe uma opção literal "GERENTE AUTOMAÇÃO"
  que parece destinada a uso por testes/automação.
- `Tipo Empresa` (select): Nenhum / Matriz / Filial. (O CNPJ de teste termina em `/0001`, o que
  pela convenção costuma indicar Matriz, mas não decidi isso sozinho.)

`Tipo de Proposta` já vem preenchido e desabilitado como "NOVA" — esse não precisa de ação.

Quais valores devo usar nesses 3 campos obrigatórios? (Ou existe algum passo/ordem que eu não
segui que faria o sistema preenchê-los automaticamente a partir do CNPJ, como você esperava?)
Resposta: Valores a usar nos 3 campos:
- Tipo de Prospect: `PROSPECT`
- Agente Comercial: `GERENTE AUTOMAÇÃO` (confirmado — é essa mesma opção pensada para uso por
  automação)
- Tipo Empresa: `Matriz`

Importante: o Thiago esperava que esses 3 campos fossem preenchidos automaticamente pela consulta
do CNPJ — não foi um passo/ordem que faltou da sua parte, é um comportamento da aplicação diferente
do esperado. Não trate isso como "resolvido, só preencher manualmente e seguir": **adicione uma
validação no teste/Etapa que capture explicitamente esse gap** — por exemplo, confirmar (antes de
preencher manualmente) que os 3 campos realmente vêm vazios/não preenchidos automaticamente após a
consulta do CNPJ, e registrar isso como um achado/comportamento inesperado (não como um requisito
normal do formulário) em `docs/documentacao.md`. Se o comportamento da aplicação for corrigido no
futuro (passar a auto-preencher), essa validação deve acusar a mudança em vez de simplesmente
continuar passando silenciosamente. Depois dessa validação, preencha os 3 campos manualmente com os
valores acima e prossiga com a submissão/validação normal da tarefa.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Ao retomar a implementação (já com os valores dos 3 campos obrigatórios confirmados —
Page Object `NovoProspectPage` criado e commitado, commit `c36db44` na branch
`feature/poc-criar-prospect-cedente-cnpj`), o `cypress run` falhou logo no login com
`Error: connect ETIMEDOUT 10.101.10.254:443` — timeout tentando conectar em
`beyond-hml.grupomultiplica.com.br`, que resolve para esse IP **privado**. Confirmei fora do
Cypress (`curl --max-time 20`, 2 tentativas) que a máquina realmente não consegue alcançar esse
host agora, enquanto `keycloak-new-2.grupomultiplica.com.br` (IP público) respondeu normalmente.
Isso é diferente dos sintomas de `cy.origin`/Keycloak já catalogados antes (aqueles ocorriam depois
de alcançar a aplicação; este falha antes de qualquer coisa, no nível de rede/TCP para o IP
interno). Preciso confirmar com você: essa máquina depende de alguma VPN/rede específica para
alcançar `beyond-hml` que talvez tenha caído nesse momento? É algo que eu deveria simplesmente
aguardar e retentar num próximo ciclo (mesmo tratamento dos outros bloqueios de "instabilidade de
ambiente" já documentados), ou há uma ação de infraestrutura que só você consegue tomar (reconectar
VPN, verificar firewall, etc.)?
Resposta: Confirmado — era a VPN, que caiu e já devia ter reconectado sozinha. Deve estar
acessível agora. Pode retentar o `cypress run` normalmente. Se o mesmo erro (`connect ETIMEDOUT`
pro IP `10.101.10.254`) acontecer de novo, trate como nova ocorrência de instabilidade de
rede/VPN (mesmo protocolo já usado para instabilidade de ambiente: não insistir em várias
tentativas seguidas, registrar dúvida nova) — não presuma que é definitivo na primeira falha.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Na retomada seguinte à sua resposta anterior, tentei rodar de novo o fluxo (scratch
`explorar-prospect-sucesso.feature`, que dá o segundo "Salvar" com os 3 campos preenchidos, para
descobrir onde o cedente criado aparece). O mesmo erro voltou a acontecer: `cypress run` falhou de
novo com `Error: connect ETIMEDOUT 10.101.10.254:443`. Confirmei fora do Cypress, uma única vez
(sem insistir em sequência), com `curl --max-time 15`: `beyond-hml.grupomultiplica.com.br`
continua sem conectar (timeout), enquanto `keycloak-new-2.grupomultiplica.com.br` respondeu
normalmente (`403`, mas conectou) — exatamente o mesmo padrão de antes. Como combinado, não
insisti em mais tentativas. A VPN caiu de novo (ou nunca reconectou de fato dessa vez)? Devo só
aguardar e retentar num próximo ciclo, ou há algo que só você consegue verificar/reconectar dessa
vez?
Resposta: Era a VPN de novo — já reconectada, pode continuar normalmente.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Com a VPN ok, consegui rodar o fluxo completo via spec descartável (`_scratch`) e
confirmar visualmente que ele funciona: após o segundo "Salvar" (com os 3 campos obrigatórios
preenchidos), o app redireciona para `https://beyond-hml.grupomultiplica.com.br/monitor`, onde a
tabela "Prospecções" mostra o registro recém-criado (linha com `Agente Comercial` =
`GERENTE AUTOMAÇÃO`, o valor de teste combinado com você). Não há coluna de CNPJ visível nessa
listagem, então usei o `Agente Comercial` como evidência de que o Prospect criado aparece na
tabela — se preferir uma validação diferente (ex.: abrir o registro e conferir o CNPJ), me avise.

Implementei então o código de produção (commit `b804d23` na branch
`feature/poc-criar-prospect-cedente-cnpj`): `EtapaCriarProspectPorCnpj` + `EsteiraCriarProspectPorCnpj`
+ `MonitorProspectPage` (valida redirecionamento para `/monitor` + linha com o Agente Comercial) +
feature/step_definitions em `poc/`, reaproveitando o `NovoProspectPage` já existente (mais um
método novo, `aguardarCamposObrigatoriosHabilitados()`, para evitar um flake de clique em campo
ainda desabilitado logo após o primeiro "Salvar" que apareceu numa das explorações).

Ao rodar o autoteste (`cypress run` no spec de produção, não mais o scratch), o teste falhou já no
login, com o sintoma **já catalogado** em `conhecimento-geral.md` (ocorrido antes em `mop` e no
próprio `shared/login.feature` algumas vezes): `CypressError: cy.origin() failed to create a spec
bridge to communicate with the specified origin` (ocorre dentro do `cy.session`/`cy.origin` do
`cy.loginComoPerfil`, antes de qualquer interação com a tela do Beyond). Seguindo o protocolo já
estabelecido para esse sintoma específico (não insistir em várias tentativas seguidas, registrar
dúvida e aguardar confirmação antes de tentar de novo), não retentei ainda. Pelo padrão observado
em ocorrências anteriores, normalmente é resolvido só tentando de novo depois — pode confirmar que
está tudo ok pra eu tentar novamente? (Nenhum código foi alterado desde o commit `b804d23`; a causa
não parece ser a implementação, e sim o mesmo problema intermitente de login já catalogado.)
Resposta: Sim, pode tentar de novo — é instabilidade pontual do mesmo tipo já catalogado, não
precisa mexer no código.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Retomei com a VPN ok (confirmei via `curl` antes de começar) e rodei o autoteste do spec
de produção de novo. Desta vez o login funcionou (sem repetir o erro de `cy.origin`), mas apareceu
um **problema novo, não relacionado a rede/VPN/login**: depois do primeiro "Salvar" (com os 3
campos ainda vazios), o campo "Tipo de Prospect" deveria sair do estado `Mui-disabled` para poder
selecionar o valor (é o que `aguardarCamposObrigatoriosHabilitados()` espera, implementado na
retomada anterior). Só que o campo continuou `disabled` mesmo depois de **15 segundos** de espera
(aumentei o timeout de 4s, o padrão, para 15s como primeira tentativa de correção — commit
`0138e86`, já pushado). O screenshot de falha mostra os textos "Campo Obrigatório" já visíveis
embaixo de "Tipo de Prospect" e "Agente Comercial" (ou seja, o clique em "Salvar" registrou e
disparou a validação normalmente), mas o atributo/classe `disabled` no input não sai. Isso é
diferente do flake leve já documentado ("às vezes falha por clique cair no campo ainda
desabilitado") — lá bastava esperar um pouco; aqui nem 15s foram suficientes numa execução run inteira.
Não cheguei a confirmar se é sempre assim ou intermitente (uma tentativa de investigação adicional
com um spec de diagnóstico foi interrompida por nova queda de VPN, ver abaixo, antes de conseguir
amostrar o timing com mais precisão).
Como devo prosseguir? Alternativas que vejo, mas não quero decidir sozinha sem confirmar: (a)
aumentar ainda mais o timeout (ex.: 30s+) e tentar de novo; (b) você mesmo abrir a tela
manualmente em hml e confirmar quanto tempo o campo realmente leva pra habilitar depois do
"Salvar" (pra eu calibrar um valor realista em vez de ir aumentando às cegas); (c) se isso for uma
mudança de comportamento da aplicação (regressão), me avisar para eu não insistir tentando ajustar
timing do lado do teste.

Separadamente, e sem relação com o achado acima: a mesma queda de conectividade com
`beyond-hml.grupomultiplica.com.br` (`connect ETIMEDOUT 10.101.10.254:443`) já catalogada
recorreu de novo durante uma investigação adicional (spec de diagnóstico descartável, não
commitado por estar em `cypress/e2e/features/_scratch/`, que é gitignored) — confirmei com uma
única checagem via `curl --max-time 15` (sem insistir em sequência): `beyond-hml` deu timeout,
`keycloak-new-2` respondeu `403` normalmente, mesmo padrão de sempre. Aguardo a mesma confirmação
de sempre (VPN reconectada, pode retentar) antes de rodar `cypress run` de novo — mas o achado do
campo desabilitado acima é independente disso e aconteceu numa execução em que a VPN estava
funcionando (login passou).
Resposta: Sobre o campo "Tipo de Prospect" travado em `Mui-disabled`: opção (a) — aumente o
timeout (30s+) e tente de novo.

Sobre a queda de VPN (3ª ocorrência): Thiago confirmou (via Gerente, 2026-09-15) que a VPN
reconectou de novo — pode retentar o `cypress run` normalmente.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Antes de aplicar a sua última orientação (timeout de 60s + revisar a espera para
depender de carregamento assíncrono real em vez de tempo fixo cego), tentei investigar ao vivo
(spec de diagnóstico `_scratch/diagnostico-campos-habilitam.feature`, já estendido para também
capturar spinners visíveis e requisições de rede em voo a cada amostra, não só o atributo
`disabled`) para descobrir o que de fato acontece na tela depois do primeiro "Salvar" — sem isso eu
estaria só adivinhando qual seletor de spinner/qual requisição observar.

Confirmei VPN ok antes de começar (`curl` em `beyond-hml` retornou `200`). Rodei o spec de
diagnóstico e ele falhou logo no login (`cy.loginComoPerfil`/`cy.session`/`cy.origin`), com o
sintoma já catalogado: `CypressError: cy.origin() failed to create a spec bridge to communicate
with the specified origin`. Tentei mais uma segunda vez (mesma checagem de VPN antes, sem mudar
nada) e o **mesmo erro exato se repetiu**, agora duas vezes seguidas — diferente das ocorrências
anteriores desse sintoma nesta tarefa, em que uma única tentativa já bastava para reproduzir e eu
parava para perguntar antes de tentar de novo. Como o protocolo já estabelecido é não insistir em
várias tentativas seguidas, parei na segunda falha em vez de tentar uma terceira vez sozinha.

Isso bloqueia tanto a investigação do spinner/requisição (preciso do login funcionando para chegar
à tela) quanto o próprio retry de 60s que você pediu (a tarefa nem chega a interagir com o campo
"Tipo de Prospect" se o login falhar antes). Nenhum código de produção foi alterado nesta retomada
(só o spec de diagnóstico descartável, gitignorado, não commitado). Devo tentar de novo (3ª vez
seguida, fora do padrão usual) ou isso merece alguma verificação sua antes (ex.: confirmar de novo
se é a mesma instabilidade pontual de sempre, dado que desta vez falhou 2x seguidas em vez de 1x)?
Resposta: Thiago confirmou (2026-09-16): pode tentar novamente.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Apliquei a opção (a) sugerida (aumentar `aguardarCamposObrigatoriosHabilitados` de 15s
para 30s, commit `9054e8b`, já pushado) e rodei o autoteste do spec de produção de novo com VPN
confirmada ok (`curl` em `beyond-hml` retornou `200` antes de começar, login passou sem erro de
`cy.origin`). O resultado foi o **mesmo travamento**: o campo "Tipo de Prospect" continua com a
classe `Mui-disabled` mesmo depois de **30 segundos** de espera —
`AssertionError: Timed out retrying after 30000ms: expected '<input#mui-19511...Mui-disabled...>'
not to be 'disabled'`. Vídeo da execução gerado normalmente em
`cypress/videos/poc-criar-prospect-cedente-cnpj.feature.mp4` (screenshot de falha também salvo),
disponíveis no clone deste subAgent se quiser conferir visualmente.

Como 15s e agora 30s falharam da mesma forma (campo nunca sai do estado `Mui-disabled` durante
toda a espera, não é questão de "faltou um pouco mais"), não acredito mais que seja calibração de
timing do lado do teste — isso bate com a alternativa (c) que eu tinha levantado antes: pode ser
uma mudança de comportamento da aplicação (regressão em hml) em vez de um flake de timing. Não vou
insistir aumentando o timeout de novo sem confirmação, como combinado.

Poderia confirmar, olhando o vídeo/screenshot ou abrindo a tela você mesmo em hml: o campo "Tipo de
Prospect" realmente fica preso desabilitado depois do primeiro "Salvar" agora (regressão), ou há
algum passo/estado prévio da tela que o teste não está reproduzindo (e que faria o campo habilitar
normalmente na prática)? Como devo prosseguir?
Resposta: Thiago confirmou (2026-09-16): dobre o timeout de novo (60s) e tente mais uma vez. Além
disso, revise a espera: não clique no botão/campo antes de as informações relevantes terminarem de
aparecer na tela — confirme que qualquer carregamento assíncrono (ex.: resposta da consulta do CNPJ,
spinner de loading, ou qualquer outra informação que a tela ainda esteja renderizando) já concluiu
antes de agir sobre o campo "Tipo de Prospect" ou de checar seu estado `disabled`, em vez de só
esperar um tempo fixo cego. Se mesmo assim o campo continuar preso da mesma forma, pare de tentar
(não insista de novo sozinho) e deixe o vídeo/screenshot já gerados prontos — o Thiago vai pedir
para assistir e decidir os próximos passos a partir daí.

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Nesta retomada, antes de aplicar a mudança de código (revisar a espera com base em
spinner/requisição real, em vez de tempo fixo), tentei rodar de novo o spec de diagnóstico
descartável (`_scratch/diagnostico-campos-habilitam.feature`, já estendido para capturar
spinners/requisições em voo a cada amostra) para coletar a evidência necessária — sem isso eu
estaria só adivinhando qual condição usar na espera revisada.

Confirmei VPN ok antes de começar (`curl --max-time 20` em `beyond-hml` retornou `200`). O
`cypress run` falhou de novo logo no login (`cy.loginComoPerfil`/`cy.session`/`cy.origin`), com o
mesmo sintoma já catalogado: `CypressError: cy.origin() failed to create a spec bridge to
communicate with the specified origin`. Isso aconteceu **antes** de qualquer interação com a tela
de "Novo Prospect", então não consegui coletar nenhuma amostra nova de spinner/requisição — a
investigação continua bloqueada no mesmo ponto de antes.

Diferente da retomada anterior (2 falhas consecutivas), esta é só 1 falha isolada nesta retomada —
mas como o protocolo já estabelecido é não insistir em tentativas seguidas sem confirmação, parei
aqui em vez de tentar de novo sozinha. Nenhum código de produção foi alterado (nada commitado nesta
retomada; o spec de diagnóstico continua igual, gitignorado, no working tree local deste clone).
Vídeo (`cypress/videos/diagnostico-campos-habilitam.feature.mp4`) e screenshot de falha gerados
normalmente, disponíveis no clone se quiser conferir. Posso tentar de novo?
Resposta: Sim, pode tentar de novo.
