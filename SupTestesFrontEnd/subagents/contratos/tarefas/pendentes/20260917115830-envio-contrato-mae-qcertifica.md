---
id: 20260917115830-envio-contrato-mae-qcertifica
modulo: contratos
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-17
---

## Objetivo
Validar a integração de envio do contrato mãe do sistema para o Qcertifica (Beyond Banking, tela
"Contratos" > aba QCERTIFICA), seguindo o roteiro abaixo (refinado com o Thiago em 2026-09-18).
Roteiro passo a passo (o subAgent pode explorar detalhes de tela não descritos aqui, mas não deve
pular etapas):

1. **Cadastro do cedente**: usar um cedente com cadastro criado em produção nos últimos dias — isso
   é uma garantia informal de que ele ainda não existe em homologação/HML. Cedente precisa ter
   nome fantasia, razão social e endereço completos. **Em aberto**: como obter/confirmar esse
   cedente em HML antes de começar (ver `duvidas.md` deste módulo — pode depender do módulo
   `cedente` do `SupAutomacaoUteis`, que sincroniza PROD→HML).
2. **Aprovação do cadastro de cedente**: aprovar o cedente novo com os dados básicos (razão
   social, nome fantasia, endereço com número, etc.).
3. **Cadastro das pessoas ligadas** ao cedente. Tipos possíveis: FIADOR, DEVEDOR SOLIDÁRIO, FIEL
   DEPOSITÁRIO, REPRESENTANTE, PROCURADOR, ADVOGADO, RECLAMADA, Testemunha, TERCEIRO GARANTIDOR,
   ENDOSSANTE (ou outro papel equivalente). Para DEVEDOR SOLIDÁRIO, a pessoa ligada pode ser uma
   PJ (não só pessoa física).
4. Para cada pessoa ligada, na seção "Documentos para assinatura", selecionar quais documentos
   ela assina (mover de "Não assina" para "Assina") — **só os da seção "Documentos Contratuais"**
   importam por ora (não "Documentos Operacionais").
5. Ao adicionar um documento a uma pessoa ligada, definir com qual papel ela assina aquele
   documento especificamente (modal "Assinaturas no documento <nome do documento>" — ex.:
   REPRESENTANTE, PROCURADOR etc.). **Importante**: representantes/devedores solidários que vão
   assinar o contrato devem assinar o MESMO documento selecionado no passo 8.
6. **Se a pessoa ligada for PJ na condição de Devedor Solidário**: o sistema busca
   recursivamente quem assina pela PJ (a própria PJ precisa ter sua pessoa ligada tipo
   REPRESENTANTE cadastrada), agregando essa pessoa à lista de assinantes do documento.
7. Adicionar fundos ao cedente/operação (seção "Fundos" dos Parâmetros da Operação) — usar
   **somente** "MULTIPLICA FUNDO DE INVESTIMENTO EM D" (não há outro fundo cadastrado no Qcertifica
   de HML).
8. Vincular representantes de Consultoria Especializada, Gestora e Administradora — cada uma
   dessas entidades precisa ter, em seu próprio cadastro, um representante (tipo REPRESENTANTE).
9. Criar um ou mais contratos: tela Contratos > aba QCERTIFICA > "Novo Contrato" — selecionar
   Documento (ex.: "CONTRATO MAE HIBRIDO COOBRIGACAO"), Data Inicial, Data Contrato Mãe, e o Fundo
   do passo 7. Salvar.
10. Enviar o cadastro do cedente para a Qcertifica: no menu de ações (⋮) do contrato criado, usar
    "Envio de cadastro de cedente" (ou "Enviar Todos" para enviar todos de uma vez). Antes do
    envio o sistema roda validações — ver "Cenários de erro conhecidos" abaixo. Sucesso: mensagens
    tipo "Endereço: Alteração realizada com sucesso", "Cedente Contrato: Arquivo recebido com
    sucesso" e status "Enviado" na listagem.
11. Certificar o contrato: menu de ações (⋮) > "Certificar" — abre o modal "Assinantes do
    Documento", que lista, por parte (Cedente, Consultoria Especializada, Gestora, Administradora),
    quem está configurado como assinante daquele documento.
12. **Antes de clicar em "Certificar"** (envio para assinatura), garantir que todas as partes têm
    assinante configurado:
    - **Consultoria, Gestora, Administradora**: assinantes já devem existir como representantes
      cadastrados dessas entidades (passo 8) — verificar/cadastrar se faltar.
    - **Cedente**: quem assina é a pessoa ligada (passos 3-5) que tem aquele documento específico
      na sua lista de documentos para assinatura.
    - **Se a pessoa ligada do cedente for um Devedor Solidário PJ**: buscar quem assina aquele
      mesmo documento como pessoa ligada dessa pessoa jurídica (assinante "aninhado", passo 6).
    - Se qualquer parte não tiver assinante, o modal mostra um aviso e desabilita o botão
      "Certificar" (mensagem tipo "A(s) parte(s) <nome> não tem nenhum assinante indicado para o
      documento").

**Fora de escopo**: confirmar o recebimento/processamento do lado da QCertifica — decisão
explícita do Thiago de não automatizar acesso a outro ambiente. O subAgent só precisa narrar
claramente cada variação testada (dados usados, ação, resultado no Beyond) para o Thiago conferir
manualmente do lado da QCertifica depois.

## Critérios de aceite
- Cedente cadastrado e aprovado com sucesso (passos 1-2): pessoas ligadas, documentos por pessoa,
  papel de assinatura por documento (passo 5), e fundo `MULTIPLICA FUNDO DE INVESTIMENTO EM D`
  (passo 7) salvos sem erro.
- Contrato criado (passo 9) e cadastro do cedente enviado ao Qcertifica sem erro, com confirmação
  visível ("Arquivo recebido com sucesso" e/ou status "Enviado" na listagem) — passo 10.
- Modal "Assinantes do Documento" (passo 11) mostra corretamente os assinantes de
  Cedente/Consultoria/Gestora/Administradora, sem aviso de parte sem assinante indicado.
- Certificação/envio para assinatura (passo 12) concluído sem erro, incluindo o caso de Devedor
  Solidário PJ com assinante "aninhado" resolvido corretamente (passo 6).
- Cenários de erro conhecidos abaixo, se reproduzidos, são achado válido (documentar na narrativa,
  não é falha do teste em si):
  - Cedente sem cadastro em "Cad Pessoa Contato" → erro ao tentar enviar/certificar.
  - Caractere não numérico no campo "num_endereco" do cedente → erro.
  - Cedente sem nome fantasia, razão social, ou endereço completo → erro (comportamento exato a
    confirmar durante a execução).
  - Qualquer outro cenário de erro descoberto durante a execução: adicionar a esta lista e a
    `docs/documentacao.md` do módulo.

## Ambiente / perfil de login
HML, perfil "master". Bloqueado enquanto `PAUSA-HML.flag` existir na raiz do repo (ambiente HML
fora do ar desde 2026-09-16) — não tentar executar até a flag ser removida.

## Material de apoio
- `../../../../AgenteEspecificacao/especificacoes/contratos-qcertifica/especificacao.md` —
  especificação completa (roteiro, queries SQL de apoio, casos de erro, regras de assinantes).
  Ainda há 2 dúvidas em aberto no `duvidas.md` do mesmo tema (acesso a SQL Server, e se o cedente
  precisa ser sincronizado PROD→HML pelo módulo `cedente` do `SupAutomacaoUteis` antes) — o
  subAgent deve registrar dúvida própria em vez de assumir, se travar exatamente nesses pontos.
