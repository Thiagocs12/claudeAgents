---
id: 20260914130450-resolucao-viewport-e-video-execucao
modulo: geral
branch: feature/resolucao-viewport-e-video-execucao
---

## Resumo
`cypress.config.js` (bloco `e2e`) agora define explicitamente `viewportWidth: 1920`,
`viewportHeight: 1080` e `video: true` (commit `792e06f`, já estava no repo antes da retomada desta
tarefa). Nesta retomada, foi só adicionada documentação: `README.md` e `CLAUDE.md` documentam que a
resolução do `.mp4` gravado **não** bate com o viewport configurado — é uma limitação conhecida do
Cypress (o vídeo é um pipeline de captura interno, separado da renderização do viewport, sem opção
de config para resolução). Resolução real medida por modo/browser (lendo o box `tkhd` do `.mp4`):

| Modo | Resolução do vídeo |
| --- | --- |
| Electron headless (padrão `npm test`/`cypress run`, usado pelas automações) | 1280x720 |
| Chrome headless (`--browser chrome --headless`) | 1264x624 |
| Electron `--headed` (uso manual) | 1920x982 |

Decisão do Thiago (via `duvidas.md`): considerar a tarefa concluída assim mesmo — o viewport
1920x1080 é o que importa pro app renderizar certo durante o teste; não vale a pena investigar mais
fundo a resolução do vídeo agora.

## Autoteste
`npx cypress run --spec cypress/e2e/features/shared/login.feature` rodado 2x após a mudança: 1ª
execução teve 1 falha transiente de rede no `cy.origin()` (já documentado como intermitente em
tarefa anterior, não relacionado a esta mudança); 2ª execução passou 2/2. `.mp4` gerado normalmente
em `cypress/videos/` em ambas.
