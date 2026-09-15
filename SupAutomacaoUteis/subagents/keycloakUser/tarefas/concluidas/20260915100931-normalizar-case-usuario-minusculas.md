---
id: 20260915100931-normalizar-case-usuario-minusculas
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição
Bug de comparação de case no `expect` da automação de clonagem/criação de usuário no Keycloak.

Cenário relatado: Thiago passou o usuário como `formalizacao.Automacao` (com maiúscula). O
Keycloak, por padrão, normaliza o username para minúsculas ao criar (`formalizacao.automacao`).
O `expect`/assertion do teste compara o valor exatamente como foi enviado (com o case original,
`formalizacao.Automacao`) contra o valor retornado pelo Keycloak (já em minúsculas,
`formalizacao.automacao`), e a comparação falha por divergência de case — não é uma divergência
de dado real, é só o case.

Correção: normalizar o username para minúsculas **em todos os pontos** onde ele é usado
(entrada/parâmetro, criação/requisição ao Keycloak, e a comparação no `expect`) — não deixar o
valor original com maiúsculas circulando em nenhuma dessas etapas. Ou seja: se o usuário passar
`AUTOMACAO`, `Automacao` ou `automacao`, o resultado usado/comparado deve ser sempre
`automacao`.

Isso deve valer tanto para a clonagem PROD→HML quanto para qualquer outro fluxo do módulo
`keycloakUser` que receba um username como entrada e depois compare com o retorno do Keycloak
(revisar todos os pontos do código deste módulo que lidam com username, não só o caminho que
gerou o bug relatado).

## Critérios de aceite
- Username informado com qualquer combinação de maiúsculas/minúsculas (ex.: `AUTOMACAO`,
  `Automacao`, `automacao`) é normalizado para minúsculas antes de ser usado em qualquer
  operação (busca, criação, comparação) no Keycloak.
- O `expect`/assertion que hoje quebra por divergência de case passa a comparar valores já
  normalizados (ambos em minúsculas) e deixa de falhar por esse motivo.
- Testar reproduzindo o cenário relatado: passar `formalizacao.Automacao` como entrada e
  confirmar que a automação encontra/cria/compara corretamente contra
  `formalizacao.automacao` sem falha de expect.
- Nenhuma outra parte do módulo (testes de safety, outros cenários já cobertos) quebra com essa
  mudança.

## Material de apoio
- Relato direto do Thiago (sem print/log anexado): erro observado foi o `expect` do teste
  quebrando ao comparar o username enviado (`formalizacao.Automacao`) com o retornado pelo
  Keycloak (`formalizacao.automacao`).
- Ver tarefas já concluídas do módulo para contexto de fluxo de clonagem de usuário:
  `tarefas/concluidas/20260914115110-clonar-usuario-keycloak-prod-hml.md` e
  `tarefas/concluidas/20260914174624-clonar-usuarios-em-lote.md`.
