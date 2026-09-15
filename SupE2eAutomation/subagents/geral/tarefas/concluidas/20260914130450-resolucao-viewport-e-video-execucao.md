---
id: 20260914130450-resolucao-viewport-e-video-execucao
modulo: geral
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-14
---

## Descrição
Hoje o `cypress.config.js` do repositório não define `viewportWidth`/`viewportHeight`, então o
Cypress usa o padrão (1000x660) — janela pequena/cortada, que fica com aparência estranha quando
alguém assiste a execução visual (`cypress open` ou vídeo gravado). Configurar explicitamente
`viewportWidth: 1920` e `viewportHeight: 1080` no bloco `e2e` de `cypress.config.js`, pra a UI
aparecer no tamanho real que um usuário veria.

Além disso, o Thiago sugeriu uma melhoria de fluxo: em vez de precisar abrir o Cypress
interativamente (`cypress open`) pra acompanhar uma execução ao vivo, prefere receber um vídeo
gravado da execução pra assistir depois. Hoje `video` também não está configurado explicitamente
no `cypress.config.js` (fica no valor padrão do Cypress instalado) — confirme o valor padrão da
versão instalada (15.20.1) e, se não for `true`, defina `video: true` explicitamente no bloco
`e2e`. Rode um teste real (`npm test` ou `npx cypress run --spec <algum spec existente>`) depois
da mudança e confirme que um `.mp4` aparece em `cypress/videos/` (já está no `.gitignore`, então
não deve ser commitado — é só material de acompanhamento, não faz parte do código).

## Critérios de aceite
- `cypress.config.js` define `viewportWidth: 1920` e `viewportHeight: 1080` no bloco `e2e`.
- `cypress.config.js` define `video: true` explicitamente no bloco `e2e` (mesmo que já fosse o
  padrão — deixar explícito pra não depender do default da versão instalada).
- Rodar qualquer spec existente (`npm test` ou `npx cypress run --spec <spec>`) e confirmar que
  gera um `.mp4` em `cypress/videos/` na resolução configurada.
- `README.md`/`CLAUDE.md` do repo mencionam, na seção de comandos ou de arquitetura, que as
  execuções ficam gravadas em `cypress/videos/` pra quem quiser assistir sem rodar o Cypress
  interativamente (só uma linha, não precisa de seção nova).

## Material de apoio
- Nenhum link/arquivo externo — mudança de configuração local (`cypress.config.js`), sem
  dependência de credenciais ou variável de ambiente nova.
