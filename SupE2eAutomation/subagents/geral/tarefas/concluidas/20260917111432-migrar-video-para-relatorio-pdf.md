---
id: 20260917111432-migrar-video-para-relatorio-pdf
modulo: geral
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-17
---

## Descrição

Política mudou (pedido explícito do Thiago, 2026-09-17): as execuções de teste devem parar de
gravar vídeo e passar a gerar um **relatório em PDF documentando tudo o que foi feito, com
screenshots e demonstração de clique** (par de screenshots antes/depois de cada clique relevante).
Isso é infraestrutura cross-módulo (reaproveitada por `POC`, `mop` e módulos futuros), por isso
entra no módulo `geral`.

Este é o mesmo modelo já adotado no `SupTestesFrontEnd` (ver `AGENTE.md`/`CLAUDE.md` dele, seção
3.1/3.5) — pode usar como referência de formato de relatório, adaptando pro Cucumber/Page-Object
deste repositório.

Escopo do que precisa ser feito:

1. **Desabilitar vídeo**: `video: false` em `cypress.config.js` (hoje está `true`).
2. **Capturar screenshots em pontos relevantes**: adicionar um hook em `EtapaBase` (ou onde fizer
   mais sentido na arquitetura Page/Etapa/Esteira já documentada no `CLAUDE.md` deste repositório)
   que tira um screenshot (`cy.screenshot(...)`) antes e depois de cada ação relevante dentro de
   `executar()` — não precisa ser toda ação de baixo nível de uma Page, só o suficiente pra
   demonstrar visualmente o que a Etapa fez.
3. **Gerar o PDF**: um script Node reaproveitável (ex.: `scripts/gerar-relatorio-pdf.cjs`, lib
   `pdfkit` — avaliar se `cypress-mochawesome-reporter` (já cogitado no `CLAUDE.md` deste
   repositório, seção "Fora de escopo", que agora entra em escopo) resolve isso pronto, antes de
   implementar do zero) que roda depois de `npm test`/`cypress run` e gera
   `relatorios/<nome-do-cenario>.pdf` por feature/cenário executado, juntando os screenshots em
   ordem com uma legenda simples por passo.
4. **Atualizar o `CLAUDE.md` deste repositório** (`repo/CLAUDE.md`) documentando essa nova
   arquitetura de relatório (a seção "Fora de escopo por enquanto" hoje lista "relatórios
   (mochawesome/Allure)" como não pedido — atualizar isso).
5. **Atualizar o `.gitignore`** do repositório: remover a suposição de que vídeo é o artefato
   (`cypress/videos/` já está documentado como gitignored no `CLAUDE.md` — ok deixar assim, só não
   é mais gerado); decidir se `relatorios/*.pdf` deve ser versionado ou ignorado (recomendação: **versionar** — PDF é leve e é a documentação da execução, diferente do vídeo que era pesado e só local; mas confirme com o Supervisor/Thiago se tiver dúvida).
6. Rodar a suíte e confirmar que o PDF é gerado corretamente para pelo menos um cenário existente
   (`mop-monitor-diario.feature` é uma boa opção, já validado).

## Critérios de aceite

- `cypress.config.js` com `video: false`.
- Rodar `npm test` (ou um spec específico) gera pelo menos um PDF em `relatorios/` com screenshots
  legíveis mostrando as ações relevantes da Etapa executada.
- `repo/CLAUDE.md` atualizado descrevendo o novo mecanismo.
- Nenhum vídeo é mais gerado.

## Material de apoio

- Referência de formato já implementado (mesma política, outro Supervisor):
  `SupTestesFrontEnd/subagents/mop/AGENTE.md` (regras 3 e 6) e
  `SupTestesFrontEnd/CLAUDE.md` (seção 3.1, regras 3 e 6).
- Pedido original do Thiago (via Gerente, 2026-09-17): "mude a politica geral para ao invés de
  criar videos dos testes para criar arquivos pdfs documentando tudo o que foi feito com
  screenshots e demonstração de click".
