---
id: 20260915131339-criar-prospect-cedente-cnpj
modulo: mop
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-15
---

## Descrição
Primeira etapa da POC do fluxo comercial completo (Prospect → esteira → pleito → demais etapas,
que serão refinadas e registradas como tarefas separadas nos próximos passos — **não implementar
nada além do que está descrito aqui**).

Automatizar a criação de um Prospect (cedente) a partir do CNPJ, seguindo o caminho:

```
Beyond Backoffice → Comercial → Prospect → Novo Prospect
```

Login com o perfil `master` (reaproveitar `cy.loginComoPerfil('master')`, já implementado pelo
módulo `geral` — não reimplementar login). Reaproveitar também a navegação até o dashboard
Comercial já mapeada na tarefa do Monitor Diário (ver `docs/documentacao.md` deste módulo, seção
"Navegação até a tela Comercial").

No formulário de "Novo Prospect", preencher **apenas o campo de CNPJ** com o valor
`67.903.430/0001-94`. Segundo o Thiago, o sistema consulta o CNPJ e preenche automaticamente os
demais dados do cedente — não é esperado preencher nenhum outro campo manualmente nesta etapa. Se,
na prática, a tela exigir outro campo obrigatório além do CNPJ, registrar como dúvida bloqueante em
vez de inventar um valor.

## Critérios de aceite
- Login como `master` e navegação completa até a tela "Novo Prospect" (Beyond Backoffice →
  Comercial → Prospect → Novo Prospect).
- Preenchimento do CNPJ `67.903.430/0001-94` e submissão do formulário.
- Validação de sucesso: o cedente criado deve aparecer na tabela/listagem de cedentes (confirmar
  com o Thiago via dúvida, se necessário, o nome exato da tela/rota dessa listagem, caso não seja
  óbvio a partir da navegação).
- Autoteste rodado ao final (`cypress run` no spec criado), com vídeo gerado normalmente em
  `cypress/videos/` (o Thiago quer acompanhar essa etapa pelo vídeo).
- Seguir o padrão de arquitetura já estabelecido no repositório (Page Object da tela de Prospect,
  Etapa/Esteira conforme o padrão já usado no Monitor Diário, camada fina de Cucumber).

## Fora de escopo (não implementar nesta tarefa)
- Qualquer etapa da esteira posterior à criação do Prospect.
- Preenchimento de "pleito" ou qualquer tela subsequente.
- Essas etapas virão como tarefas novas, uma de cada vez, depois que esta for validada.

## Material de apoio
- CNPJ de teste: `67.903.430/0001-94`.
- Caminho de navegação: Beyond Backoffice → Comercial → Prospect → Novo Prospect (mesmo dashboard
  Comercial já mapeado pela tarefa do Monitor Diário — ver seção "Navegação até a tela Comercial"
  em `docs/documentacao.md` deste módulo).
