> Histórico de dúvidas já respondidas/arquivadas: ver `duvidas-historico.md` (mesma pasta).

## 20260915131339-criar-prospect-cedente-cnpj
Status: respondida
Pergunta: Retomei a tarefa após a limpeza de cache do Cypress (sua última resposta, 12ª rodada) e,
seguindo a orientação de revisar a espera com base em spinner/requisição real (não tempo fixo)
antes de aumentar o timeout para 60s, rodei primeiro o spec de diagnóstico descartável
(`_scratch/diagnostico-campos-habilitam.feature`) para coletar evidência, sem alterar nenhum
código de produção ainda. VPN/ambiente confirmados ok antes (`curl` em `beyond-hml`: `200` em
~0.4s).

O diagnóstico falhou de novo, mas com um sintoma **diferente** do `cy.origin() failed to create a
spec bridge` catalogado nas rodadas anteriores desta tarefa: desta vez travou no
`cy.session`/login com `AssertionError: Timed out retrying after 15000ms: expected` a URL do
Keycloak (`.../login-actions/authenticate?...`) `to include 'https://beyond-hml...'` — ou seja,
depois de submeter as credenciais, a página não redirecionou de volta pro Beyond. Segui o
protocolo de comparar com `shared/login.feature` (mesma janela de minutos) e ele **também falhou**,
no mesmo cenário exato ("Login com credenciais válidas"), com o mesmo sintoma.

O screenshot da falha mostra o motivo: a tela não ficou em branco/carregando — é o próprio
formulário do Keycloak, com o campo de usuário preenchido (`automacao`) e uma mensagem de
validação em vermelho logo abaixo: **"usuário ou senha inválidos"**. Ou seja, o Keycloak rejeitou
ativamente a credencial — não é timeout de rede/redirect lento. Conferi que `HML_MASTER_PASSWORD`
neste `.env` bate exatamente com o valor documentado em `../geral/docs/documentacao.md`
(confirmado igual, capitalização correta) — não é erro de digitação neste clone. Confirmação
adicional: no mesmo run de `login.feature`, o cenário "Login com credenciais inválidas" (senha
propositalmente errada) passou normalmente, confirmando que a mensagem é a resposta real do
Keycloak, não artefato do teste.

Isso é mais grave que os sintomas anteriores desta tarefa: não parece mais timing/rede/`cy.origin`
— parece que a própria credencial `automacao` está sendo rejeitada pelo Keycloak
agora, o que bloquearia **todos** os módulos que usam `cy.loginComoPerfil('master')`, não só o
POC. Não tentei de novo nem toquei em `repo/` (git status segue limpo na branch
`feature/poc-criar-prospect-cedente-cnpj`, nenhum código de produção alterado). Screenshot e vídeo
desta execução disponíveis no clone (`cypress/screenshots/login.feature/`,
`cypress/videos/login.feature.mp4` e os equivalentes do spec de diagnóstico). Também registrei
este achado em `../geral/docs/documentacao.md` (catálogo de instabilidade de login), por afetar
potencialmente outros módulos.

A senha do usuário `automacao` em HML foi alterada/expirou, ou a conta foi bloqueada/desativada no
Keycloak recentemente? Ou é intermitência real do Keycloak (rejeitando às vezes uma credencial
válida)? Preciso da credencial correta atualizada, se tiver mudado, antes de continuar — não vou
adivinhar um novo valor. Se a credencial estiver mesmo correta e for intermitência, posso tentar de
novo (mais uma vez, seguindo o protocolo de não insistir sem confirmação)?
Resposta: Thiago ajustou o login/Keycloak (mesma causa raiz do achado 2 do módulo `mop`, isolado ao
realm `multiplicacapital`). Pode tentar de novo.
