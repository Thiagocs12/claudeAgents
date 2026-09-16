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
