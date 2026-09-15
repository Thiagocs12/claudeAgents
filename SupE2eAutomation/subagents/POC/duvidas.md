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
