---
id: 20260911214610-monitor-diario-analisar-operacao
modulo: mop
tipo: automacao-ui
solicitado_por: Thiago
data: 2026-09-11
---

## Descrição

Implementar a automação de UI para o fluxo de acesso ao **Monitor Diário** do MOP e análise de
uma operação a partir dele. O fluxo é:

1. Logar com o usuário `master` (reaproveitar `cy.loginComoPerfil('master')`, já implementado pelo
   módulo `geral` — não reimplementar login).
2. Acessar a tela **Monitor Diário**, pelo caminho: **Beyond Backoffice → Comercial → Monitor
   Diário**.
3. Localizar uma operação que **não** esteja no status **"Inclusão OPE"** — idealmente uma
   operação "em middle" (em algum estágio intermediário da esteira, não no estágio inicial).
4. **Antes de abrir a operação**, capturar/ler na própria linha do Monitor Diário o nome do
   **cedente** daquela operação (a coluna/campo que identifica a empresa cedente na listagem).
5. Acessar essa operação via a ação **"Analisar Operação"**.
6. Validar que a tela de análise abriu corretamente **comparando o nome de empresa exibido no
   topo da tela de análise com o nome do cedente capturado no passo 4** — devem ser o mesmo
   (confirma que abriu a operação certa, não só que abriu "uma" tela).

## Observação importante (repassada pelo Thiago)

O Monitor Diário pode não trazer operações "em middle" na data padrão em que a tela carrega —
pode ser necessário pesquisar em outras datas para localizar uma. **O limite de busca do Monitor
Diário é uma janela de 29 dias.** A automação deve lidar com isso: se não encontrar uma operação
fora de "Inclusão OPE" na data/filtro padrão, ajustar a busca por data dentro dessa janela de 29
dias até localizar uma.

Não há prints/spec prontos para essa tela — o subAgent deve investigar sozinho o ambiente HML
(navegando logado como `master`) para descobrir a estrutura real da tela (seletores, filtros de
data, coluna/indicador de status, botão "Analisar Operação").

## Critérios de aceite

- Login reaproveitado da fundação existente (`cy.loginComoPerfil`), sem duplicar lógica de login.
- Navegação implementada como Page Object seguindo exatamente o caminho **Beyond Backoffice →
  Comercial → Monitor Diário** (`cypress/support/pages/mop/`, seguindo o padrão Pages/Etapas/
  Esteiras do `README.md`/`CLAUDE.md` do repositório).
- Lógica de localizar uma operação fora do status "Inclusão OPE", incluindo o ajuste de data
  dentro da janela de 29 dias do Monitor Diário quando a data padrão não tiver uma operação assim.
- Antes de abrir a operação, captura do nome do cedente diretamente na linha/listagem do Monitor
  Diário (não hardcoded — lido dinamicamente da tela, já que a operação escolhida pode variar).
- Ação "Analisar Operação" executada sobre essa operação.
- **Critério de sucesso**: o nome de empresa exibido no topo da tela de análise é **igual** ao
  nome do cedente capturado no Monitor Diário antes de abrir a operação — essa comparação é a
  asserção (não basta o campo só existir/ter texto).
- Cenário expresso via Cucumber (`.feature` + `step_definitions`), seguindo o mesmo padrão do
  cenário de login já implementado.
- Segue o padrão de projeto do `README.md`/`CLAUDE.md` do repositório; atualizar esses arquivos se
  ficarem desatualizados após a implementação (ex.: documentar a nova Page/estrutura do MOP).
- Autoteste (`npm test` ou spec específica) executado com sucesso antes de reportar conclusão.

## Material de apoio

- Repositório: https://github.com/Thiagocs12/automacaoUiMultiplica.git (branch base:
  `reviewAgents`)
- URL aplicação: https://beyond-hml.grupomultiplica.com.br/
- Usuário de teste — perfil `master`: `automacao` / `Automacao@123` (mesmo do módulo `geral`, já
  configurado em `environments.js`/`.env.example` — não recriar)
- Sem prints/spec adicionais: investigar a tela ao vivo em HML.
