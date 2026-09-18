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
   é uma garantia informal de que ele ainda não existe em homologação/HML.
2. **Cadastro das pessoas ligadas** ao cedente. Tipos possíveis: FIADOR, DEVEDOR SOLIDÁRIO, FIEL
   DEPOSITÁRIO, REPRESENTANTE, PROCURADOR, ADVOGADO, RECLAMADA, Testemunha, TERCEIRO GARANTIDOR,
   ENDOSSANTE (ou outro papel equivalente). Para DEVEDOR SOLIDÁRIO, a pessoa ligada pode ser uma
   PJ (não só pessoa física).
3. Para cada pessoa ligada, na seção "Documentos para assinatura", selecionar quais documentos
   ela assina (mover de "Não assina" para "Assina").
4. Ao adicionar um documento a uma pessoa ligada, definir com qual papel ela assina aquele
   documento especificamente (modal "Assinaturas no documento <nome do documento>" — ex.:
   REPRESENTANTE, PROCURADOR etc.). **Importante**: representantes/devedores solidários que vão
   assinar o contrato devem assinar o MESMO documento selecionado no passo 6.
5. Adicionar fundos ao cedente/operação (seção "Fundos" dos Parâmetros da Operação) — usar
   **somente** "MULTIPLICA FUNDO DE INVESTIMENTO EM D" (não há outro fundo cadastrado no Qcertifica
   de HML).
6. Criar um ou mais contratos: tela Contratos > aba QCERTIFICA > "Novo Contrato" — selecionar
   Documento (ex.: "CONTRATO MAE HIBRIDO COOBRIGACAO"), Data Inicial, Data Contrato Mãe, e o Fundo
   do passo 5. Salvar.
7. Enviar o cadastro do cedente para a Qcertifica: no menu de ações (⋮) do contrato criado, usar
   "Envio de cadastro de cedente" (ou "Enviar Todos" para enviar todos de uma vez). Confirmar as
   mensagens de sucesso (ex.: "Endereço: Alteração realizada com sucesso", "Cedente Contrato:
   Arquivo recebido com sucesso") e o status mudando para "Enviado" na listagem.
8. Certificar o contrato: menu de ações (⋮) > "Certificar" — abre o modal "Assinantes do
   Documento", que lista, por parte (Cedente, Consultoria Especializada, Gestora, Administradora),
   quem está configurado como assinante daquele documento.
9. **Antes de clicar em "Certificar"** (envio para assinatura), garantir que todas as partes têm
   assinante configurado:
   - **Consultoria, Gestora, Administradora**: assinantes já devem existir como representantes
     cadastrados dessas entidades — verificar/cadastrar se faltar.
   - **Cedente**: quem assina é a pessoa ligada (passo 2-4) que tem aquele documento específico na
     sua lista de documentos para assinatura.
   - **Se a pessoa ligada do cedente for um Devedor Solidário PJ**: buscar quem assina aquele
     mesmo documento como pessoa ligada dessa pessoa jurídica (assinante "aninhado" — a PJ também
     precisa ter sua própria pessoa ligada configurada para aquele documento).
   - Se qualquer parte não tiver assinante, o modal mostra um aviso e desabilita o botão
     "Certificar" (mensagem tipo "A(s) parte(s) <nome> não tem nenhum assinante indicado para o
     documento").

## Critérios de aceite
- Cedente cadastrado com sucesso: pessoas ligadas, documentos por pessoa, papel de assinatura por
  documento (passo 4), e fundo `MULTIPLICA FUNDO DE INVESTIMENTO EM D` (passo 5) salvos sem erro.
- Contrato criado (passo 6) e cadastro do cedente enviado ao Qcertifica sem erro, com confirmação
  visível ("Arquivo recebido com sucesso" e/ou status "Enviado" na listagem) — passo 7.
- Modal "Assinantes do Documento" (passo 8) mostra corretamente os assinantes de
  Cedente/Consultoria/Gestora/Administradora, sem aviso de parte sem assinante indicado.
- Certificação/envio para assinatura (passo 9) concluído sem erro, incluindo o caso de Devedor
  Solidário PJ com assinante "aninhado" resolvido corretamente.
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
- `../../../../AgenteEspecificacao/especificacoes/contratos-qcertifica/especificacao.md`
  (levantamento ainda em andamento com o Thiago no momento da criação desta tarefa)
