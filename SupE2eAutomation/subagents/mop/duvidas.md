## 20260911214610-monitor-diario-analisar-operacao
Status: respondida
Pergunta: Estou investigando ao vivo a tela Monitor Diário em HML (login como `master`) para a
tarefa do Monitor Diário. Depois de algumas execuções seguidas de `npx cypress run` em curto
intervalo, `cy.loginComoPerfil('master')` passou a falhar de forma consistente (3 tentativas
seguidas) com `CypressError: cy.origin() failed to create a spec bridge to communicate with the
specified origin`, logo após o redirect para `keycloak-new-2.grupomultiplica.com.br` (o mesmo
comando tinha funcionado normalmente antes, cheguei a navegar até "Monitor Diário" com sucesso).
Suspeito de rate-limit/bloqueio de bot no Keycloak de HML por múltiplos logins automatizados em
sequência rápida, mas não tenho como confirmar isso sozinho. Pode confirmar se existe algum
bloqueio/rate-limit conhecido no Keycloak de HML para o usuário `automacao`/IP da máquina, ou se é
só esperar mais tempo entre tentativas antes de eu continuar a investigação?
Resposta: Não é rate-limit — o ambiente HML provavelmente estava fora do ar naquele momento
(Thiago está verificando). Não é bloqueio permanente. Pode tentar de novo normalmente; se o login
falhar de novo do mesmo jeito, não insista em várias tentativas seguidas — registre uma nova
dúvida em vez de ficar re-tentando, mas dessa vez assumindo instabilidade pontual do ambiente, não
rate-limit.

## 20260911214610-monitor-diario-analisar-operacao
Status: respondida
Pergunta: Retomei a tarefa do Monitor Diário e tentei o cenário de descoberta (`discovery.feature`,
login como `master`) uma única vez, conforme orientado. O login falhou de novo, com exatamente o
mesmo erro de antes: `CypressError: cy.origin() failed to create a spec bridge to communicate with
the specified origin`, logo após o redirect para `keycloak-new-2.grupomultiplica.com.br` (screenshot
salvo em
`repo/cypress/screenshots/discovery.feature/Descoberta temporária de estrutura de tela (não
commitar) -- Explorar a home logada como master (failed).png`). Diferença importante desta vez: já
se passaram ~3 dias desde a última tentativa (a resposta anterior apontava para o ambiente HML
fora do ar "naquele momento", em 2026-09-11) — não parece mais compatível com "instabilidade
pontual" de um instante específico, já que o mesmo erro persiste dias depois, numa única tentativa
isolada (não em sequência rápida). Pode confirmar se o ambiente HML/Keycloak está de fato no ar e
saudável agora, ou se há algo estrutural (ex.: mudança de configuração do Keycloak, certificado,
CORS/CSP para `cy.origin`) impedindo esse login especificamente neste fluxo? Não vou tentar de novo
sozinho enquanto não houver uma pista nova.
Resposta: HML está ok agora. Pode retomar a investigação.
