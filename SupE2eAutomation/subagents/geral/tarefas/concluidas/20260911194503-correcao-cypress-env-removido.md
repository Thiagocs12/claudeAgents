---
id: 20260911194503-correcao-cypress-env-removido
modulo: geral
tipo: correcao
tarefa_original: 20260911181703-login-keycloak-usuario-master
solicitado_por: Thiago
data: 2026-09-11
---

## Descrição

**Correção** sobre a tarefa `20260911181703-login-keycloak-usuario-master` (fundação de login).
Thiago rodou o teste manual (`npx cypress open`) na pasta `C:\multiplica\cypress-e2e` (já
sincronizada pelo Agent Master após o merge) e o teste quebrou antes mesmo de chegar na tela de
login, ao carregar a configuração de ambiente.

Erro reportado:
```
Cypress.env() was removed in Cypress version 16.0.0. Please update to use Cypress.expose() for
non-sensitive values, or cy.env() for sensitive values.

The key being accessed was: HML_APP_BASE_URL
```

Stack trace aponta para `cypress/config/environments.js`, função `montarAmbientes()` (chamada por
`getEnvironment()`), que usa `Cypress.env('HML_APP_BASE_URL')`, `Cypress.env('HML_KEYCLOAK_URL')`,
`Cypress.env('HML_MASTER_USERNAME')` e `Cypress.env('HML_MASTER_PASSWORD')` para montar o objeto
de ambiente (arquivo atual em `reviewAgents`, linhas 1-16).

Observação de investigação já feita: a versão do Cypress instalada em
`C:\multiplica\cypress-e2e\node_modules` é `15.20.1` (dentro do range `^15.14.2` do
`package.json`), então vale confirmar se a mensagem de erro realmente vem dessa versão instalada
ou se há alguma outra fonte (plugin, cache do Cypress, versão diferente rodando via `npx`) antes de
decidir a correção — investigar a causa raiz faz parte desta tarefa, não só aplicar a sugestão
literal da mensagem de erro.

## Critérios de aceite

- Identificada a causa raiz (por que `Cypress.env()` está falhando/sendo rejeitado nesse ambiente).
- `cypress/config/environments.js` (e qualquer outro ponto do código que dependa do mesmo padrão)
  ajustado para não quebrar mais com esse erro — usando `cy.env()`/`Cypress.expose()` conforme a
  natureza do dado (sensível vs. não sensível), ou fixando a versão do Cypress de forma explícita
  no `package.json`, o que for a correção correta identificada na investigação.
- Cenários de login válido e inválido (`cypress/e2e/features/shared/login.feature`) voltam a
  passar via `npx cypress run` **e** via `npx cypress open` (o erro relatado só aparecia no modo
  interativo/open — confirmar que os dois modos funcionam).
- `docs/documentacao.md` do módulo `geral` atualizado com o que foi aprendido sobre essa
  incompatibilidade, para não se repetir em módulos futuros que também vão ler `environments.js`.
- Autoteste executado com sucesso antes de reportar conclusão.

## Material de apoio

- Tarefa original: `subagents/geral/tarefas/concluidas/20260911181703-login-keycloak-usuario-master.md`
- Pasta de teste manual onde o erro ocorreu: `C:\multiplica\cypress-e2e` (mesmo repositório,
  branch `reviewAgents`, dependências instaladas)
- Repositório: https://github.com/Thiagocs12/automacaoUiMultiplica.git
