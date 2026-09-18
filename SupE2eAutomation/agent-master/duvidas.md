> Entradas antigas já resolvidas (aviso correspondente já saiu de `fila-merge/pendentes/`) foram
> arquivadas em `duvidas-historico.md` (2026-09-17). Nada foi descartado, só movido.

## 20260917111432-migrar-video-para-relatorio-pdf
Status: pendente
Pergunta: Merge de teste local (sem conflito, sem variável de `.env` nova, `npm install` trouxe só
a dependência nova esperada `pdfkit@0.20.2`) rodado contra `feature/migrar-video-para-relatorio-pdf`
→ `reviewAgents`. `npm test` (2 specs, `mop/mop-monitor-diario.feature` e `shared/login.feature`)
resultou em **2 de 2 specs falhando**, ambas com o mesmo sintoma, ocorrido durante o setup de
`cy.session`/`cy.loginComoPerfil`:
`AssertionError: Timed out retrying after 15000ms: expected '...keycloak-new-2.../auth/realms/...'
to include 'https://beyond-hml.grupomultiplica.com.br/'` — ou seja, depois de submeter as
credenciais no Keycloak, a página nunca chegou a redirecionar de volta para `beyond-hml`, ficando
presa na URL do próprio Keycloak. Isso é um **sintoma ainda não catalogado** em
`../subagents/geral/docs/documentacao.md` (diferente de `cy.origin() failed to create a spec bridge`, do
timeout de 60s carregando a página do Keycloak, do `ETIMEDOUT` de rede, do `ResizeObserver loop...`,
do `Mui-disabled` e do backdrop cobrindo elemento — todos já vistos antes). Além disso, é a
**primeira vez que `shared/login.feature` falha no mesmo ciclo que `mop-monitor-diario.feature`**
(cenário "Login com credenciais válidas" falhou; "Login com credenciais inválidas" passou) — todas
as ocorrências anteriores catalogadas mostravam `login.feature` passando 2/2 de forma confiável
enquanto só o outro spec falhava, o que vinha sendo usado como evidência de que o problema não era
instabilidade genérica do Keycloak/HML. Essa suposição fica mais fraca agora. Não retentei uma 2ª
vez em sequência (protocolo já estabelecido). Como pedido pela regra 9 do `AGENTE.md`: desfiz o
merge local (`git reset --hard origin/reviewAgents`, `repo/` confirmado limpo de novo) e mantive o
aviso em `fila-merge/pendentes/`. A mudança em si (vídeo→PDF, `EtapaBase.passo()`, script
`gerar-relatorio-pdf.cjs`) não parece relacionada à causa — não toca em login/Keycloak/`cy.session`
— mas não tenho como confirmar isso com o merge de teste bloqueado. Como devo proceder: (a) é
instabilidade pontual, tentar de novo (quando? agora, ou só depois de confirmação de ambiente
estável)? (b) já são evidências suficientes para investigar causa raiz de forma mais séria (talvez
ligado ao Keycloak/realm em si, não a rede)? (c) alguma outra instrução?
Resposta: Agent Master não deve mais rodar teste nenhum (nem `npm test`, nem `cypress run`) —
reforçado no `AGENTE.md` (regra 5). O subAgent já testou antes de avisar você; rodar de novo aqui
duplica trabalho e bloqueia merges por instabilidade de ambiente que não tem nada a ver com o
código. Como o merge de teste local não teve conflito, finalize o merge de verdade e dê push na
`reviewAgents` normalmente, sem rodar nenhum teste.
