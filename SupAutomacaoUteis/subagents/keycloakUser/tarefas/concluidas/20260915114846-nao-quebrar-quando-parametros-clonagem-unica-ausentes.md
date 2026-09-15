---
id: 20260915114846-nao-quebrar-quando-parametros-clonagem-unica-ausentes
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição
Correção reportada pelo Thiago em teste manual na `reviewAgents` (`C:\multiplica\cypress-uteis`):
ao rodar o cenário de clonagem única (`@keycloakUsuario`, `gerenciamentoDeUsuarios.feature`) sem
informar `usuarioOrigem`, `novoUsername` e `novaSenha` via `--env`, a execução quebra com o erro:

```
[gerenciamentoDeUsuarios] Informe usuarioOrigem, novoUsername e novaSenha via --env, ex.: cypress
run --env tags=@keycloakUsuario,usuarioOrigem=fulano,novoUsername=fulano.hml,novaSenha=SenhaForte123!
```

Esse guard-rail lança erro bloqueante e interrompe a execução (relevante principalmente quando se
roda a suíte completa sem `tags=@keycloakUsuario`, já que aí os parâmetros nunca são passados de
propósito). Pedido do Thiago: se os parâmetros não forem informados, **não deve quebrar** — deve
só logar (reaproveitar a mesma mensagem orientativa, como log informativo em vez de erro) e seguir,
sem executar a clonagem. Mesmo padrão de design já aplicado na tarefa anterior
(`20260915111027-remover-clonados-fixture-lote-e-fixture-vazia-nao-quebra`), que trocou o guard-rail
de fixture vazia no modo em lote de `throw` para log + segue — aqui é o equivalente para o modo
único quando os parâmetros de `--env` estão ausentes.

## Critérios de aceite
- Rodando `npx cypress run` sem `tags=@keycloakUsuario` (suíte completa) ou rodando esse cenário
  isoladamente sem informar `usuarioOrigem`/`novoUsername`/`novaSenha`, a execução **não** lança
  erro — loga a mensagem orientativa e segue sem executar a clonagem (cenário passa/pula, não
  falha).
- Se só um subconjunto dos 3 parâmetros for informado (ex.: só `usuarioOrigem`), mesmo tratamento:
  log + segue, sem tentar clonagem parcial.
- Rodando com os 3 parâmetros informados corretamente, o comportamento de clonagem única
  permanece **inalterado** (continua exigindo e usando os 3 normalmente, incluindo a normalização
  de case já implementada).
- Modo em lote (`@clonarUsuariosEmLote`) não é afetado por esta mudança.
- `npm run lint` e `npm run test:safety` continuam passando, com casos novos cobrindo: nenhum
  parâmetro informado, e só parte dos parâmetros informados.
- `README.md`/`CLAUDE.md` do repo atualizados na seção de clonagem única refletindo o novo
  comportamento (parâmetros ausentes deixam de ser erro).

## Material de apoio
- Mensagem de erro relatada pelo Thiago (texto completo acima).
- Decisão de design já validada na tarefa `20260915111027` (ver
  `subagents/keycloakUser/docs/documentacao.md`, seção "Correção: fixture de lote 'consome'
  usuários clonados; fixture vazia deixa de ser erro") — mesmo raciocínio aplicado aqui, para o
  modo único.
