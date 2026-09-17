---
id: 20260917111432-migrar-video-para-relatorio-pdf
modulo: geral
branch: feature/migrar-video-para-relatorio-pdf
---

## O que fazer

Merge de teste local contra `reviewAgents`, rodar suíte, se passar: merge direto + push na
`reviewAgents` (fluxo atual, sem PR por tarefa).

## Resumo da mudança

- `cypress.config.js`: `video: false` (era `true`).
- `cypress/support/etapas/EtapaBase.js`: novo método `this.passo(descricao, acao)` — tira
  screenshot antes/depois de `acao()`, nome do arquivo inclui o cenário (via
  `Cypress.currentTest.title`) e o número do passo.
- `cypress/support/etapas/mop/EtapaAnalisarOperacaoMonitorDiario.js`: migrada para usar `passo()`
  nas ações relevantes (exemplo de referência para outros módulos).
- Novo `scripts/gerar-relatorio-pdf.cjs` (dependência nova: `pdfkit@0.20.2`, em `dependencies`):
  agrupa os screenshots por cenário e gera `relatorios/<cenario>.pdf`. Rodado automaticamente após
  `cypress run` via `"test": "cypress run & node scripts/gerar-relatorio-pdf.cjs"` (usa `&`, não
  `&&`, para gerar o PDF mesmo quando a suíte falha). Também disponível via `npm run relatorio`.
- `CLAUDE.md`/`README.md` atualizados descrevendo o novo mecanismo (nova seção "PDF execution
  report" no `CLAUDE.md`).
- `relatorios/*.pdf` **não está no `.gitignore`** (decisão: versionar, conforme recomendação do
  próprio pedido da tarefa) — `cypress/screenshots/`/`cypress/videos/` seguem gitignored.
- Nenhuma variável de `.env` nova.

## Autoteste já feito pelo subAgent (não precisa repetir do zero)

- `npm test` rodado 2x contra HML: ambas as vezes esbarraram em instabilidade de HML/login já
  catalogada em `../docs/conhecimento-geral.md` (não relacionada a esta mudança) — 1ª tentativa
  chegou a capturar 1 screenshot real via `passo()` e gerar 1 PDF real antes de falhar num clique
  de menu coberto por backdrop; 2ª tentativa falhou já no login/sessão. Não retentei uma 3ª vez
  seguida (protocolo já estabelecido para essa instabilidade).
- Para validar a lógica do script em si (agrupamento/ordenação por passo, múltiplas páginas) sem
  depender do ambiente HML, gerei screenshots sintéticos (3 passos x antes/depois) e rodei
  `npm run relatorio` — PDF de 6 páginas gerado corretamente, depois removido (não commitado).
- Recomendo ao Agent Master: ao rodar a suíte antes do merge, se esbarrar na mesma instabilidade de
  HML/login, tratar como o mesmo tipo de evento já catalogado (dúvida bloqueante, sem insistir em
  sequência) — não é causado por esta mudança.
