---
tema: contratos-qcertifica
criado_em: 2026-09-17
atualizado_em: 2026-09-18
solicitado_por: Thiago
---

## Contexto de negócio
Fluxo end-to-end de cadastro de um cedente (Beyond Banking) — pessoas ligadas, documentos,
papéis de assinatura e fundos — culminando no envio do cadastro do cedente para a **QCertifica**
e, na sequência, no envio do contrato mãe para assinatura. Documento de origem completo:
`material/fluxo-integrado-cadastro.docx` (fornecido pelo Thiago em 2026-09-18).

## Gatilho / fluxo
Roteiro (Beyond Banking, tela do cedente → Contratos > aba QCERTIFICA):

1. **Cadastro do cedente**: o CNPJ retornado pela query abaixo **não é necessariamente um cedente
   já existente** — é só uma empresa matriz qualquer recém-cadastrada em produção, usada como CNPJ
   "limpo" (sem cadastro/conflito prévio em HML). O subAgent cadastra esse CNPJ como cedente **do
   zero, diretamente na UI do Beyond em HML** (não depende do módulo `cedente` do
   `SupAutomacaoUteis`, que faz sincronização PROD→HML para outro propósito). Cedente precisa ter
   cadastro completo: nome fantasia, razão social, endereço. Query de apoio (produção) pra achar
   candidato PJ:
   ```sql
   select cnpjCpf from MC_CAD_PESSOA
   where tipoPessoa = 'j' and tipoEmpresa = 'MATRIZ' and dataCadastro >= getDate() - 5
   order by 1 DESC;
   ```
2. **Aprovação do cadastro de cedente**: aprovação do novo cedente com os dados básicos (razão
   social, nome fantasia, endereço com número, etc.). Queries de apoio (conferir dados já
   propagados): `MC_CED_CEDENTE` join `MC_CAD_PESSOA_CONTATO` / `MC_CAD_PESSOA_TELEFONE` /
   `MC_CAD_PESSOA_ENDERECO` por `idPessoa`.
3. **Cadastro de pessoas ligadas** ao cedente — papéis possíveis: FIADOR, DEVEDOR SOLIDÁRIO, FIEL
   DEPOSITÁRIO, REPRESENTANTE, PROCURADOR (documento cita também ADVOGADO, RECLAMADA, Testemunha,
   TERCEIRO GARANTIDOR, ENDOSSANTE na tela de papéis por documento, passo 4). Para DEVEDOR
   SOLIDÁRIO, a pessoa ligada pode ser uma PJ. Query de apoio pra achar candidatos (PJ ou PF)
   recém-cadastrados em produção: mesma query do passo 1, trocando `tipoPessoa = 'f'` para pessoa
   física.
4. **Seleção de documentos e papéis por pessoa ligada**: para cada pessoa ligada, define-se quais
   documentos ela assina e, por documento, com qual papel assina (modal "Assinaturas no documento
   <X>"). **Só importam, por ora, os documentos da seção "Documentos Contratuais"** (não os
   "Documentos Operacionais").
5. **Busca recursiva de assinante quando a pessoa ligada é PJ devedor solidário**: o sistema busca
   quem assina pela PJ (a própria PJ tem sua pessoa ligada tipo REPRESENTANTE cadastrada),
   agregando essa pessoa à lista geral de assinantes do documento. Query de referência:
   ```sql
   select * from MC_CED_CEDENTE a
   join MC_CAD_PESSOA_LIGADA b on a.idPessoa = b.idPessoaLigada
   join MC_CAD_TIPO_PESSOA_LIGADA b2 on b.idTipoPessoaLigada = b2.id and b2.descricao = 'DEVEDOR SOLIDÁRIO'
   join MC_CAD_PESSOA c on b.idPessoa = c.id and c.tipoPessoa = 'j'
   join MC_CAD_PESSOA_LIGADA d on c.id = d.idPessoaLigada
   join MC_CAD_TIPO_PESSOA_LIGADA e on d.idTipoPessoaLigada = e.id and e.descricao = 'REPRESENTANTE';
   ```
6. **Adição de fundos**: vincular o(s) fundo(s) à operação. Em HML, usar **somente** o fundo
   "Multiplica" (nome exato observado na tela: "MULTIPLICA FUNDO DE INVESTIMENTO EM D") — não há
   outro fundo cadastrado no QCertifica de HML.
7. **Vínculo de representantes das entidades**: Consultoria Especializada, Gestora e Administradora
   precisam ter, cada uma, seu próprio representante cadastrado (tipo REPRESENTANTE). Query de
   referência (junta os três representantes de uma vez a partir do cedente/fundo):
   ```sql
   select distinct m.nome as representante_administradora, n.nome as representante_consultoria,
     o.nome as representante_gestora
   from MC_CED_CEDENTE a
   join MC_CED_FUNDO b on a.id = b.idCedente
   join MC_CAD_FUNDO c on b.idFundo = c.id
   join MC_CAD_ADMINISTRADORA d on c.idAdministradora = d.id
   join MC_CAD_PESSOA_LIGADA e on d.idPessoa = e.idPessoaLigada
   join MC_CAD_TIPO_PESSOA_LIGADA f on e.idTipoPessoaLigada = f.id and f.descricao = 'REPRESENTANTE'
   join MC_CAD_PESSOA m on m.id = e.idPessoa
   join MC_CAD_CONSULTORIA_ESPECIALIZADA g on c.idConsultoriaEspecializada = g.id
   join MC_CAD_PESSOA_LIGADA h on g.idPessoa = h.idPessoaLigada
   join MC_CAD_TIPO_PESSOA_LIGADA i on h.idTipoPessoaLigada = i.id and i.descricao = 'REPRESENTANTE'
   join MC_CAD_PESSOA n on n.id = h.idPessoa
   join MC_CAD_GESTORA j on c.idGestora = j.id
   join MC_CAD_PESSOA_LIGADA k on j.idPessoa = k.idPessoaLigada
   join MC_CAD_TIPO_PESSOA_LIGADA l on k.idTipoPessoaLigada = l.id and l.descricao = 'REPRESENTANTE'
   join MC_CAD_PESSOA o on o.id = k.idPessoa;
   ```
8. **Criação de contrato(s)**: tela Contratos > aba QCERTIFICA > "Novo Contrato" — Documento (ex.:
   "CONTRATO MAE HIBRIDO COOBRIGACAO"), Data Inicial, Data Contrato Mãe, Fundo (passo 6). Salvar.
9. **Envio do cadastro do cedente para a QCertifica**: menu de ações do contrato > "Envio de
   cadastro de cedente" (ou "Enviar Todos"). Antes do envio, o sistema roda validações
   pré-envio — ver "Casos de erro conhecidos" abaixo. Sucesso: mensagens tipo "Endereço: Alteração
   realizada com sucesso" / "Cedente Contrato: Arquivo recebido com sucesso" e status "Enviado".
10. **Envio do contrato para assinatura**: menu de ações > "Certificar" — abre modal "Assinantes
    do Documento", com os assinantes esperados por parte (Cedente, Consultoria Especializada,
    Gestora, Administradora). Regras de quem assina, ver seção "Regras de negócio" abaixo. Se
    faltar assinante de alguma parte, o botão "Certificar" fica desabilitado com aviso.

## Mecânica técnica
- Fluxo é majoritariamente síncrono do ponto de vista da UI: cada ação (enviar cadastro, certificar)
  retorna uma confirmação/erro imediato na tela (toast de sucesso ou mensagem de validação).
- **Validação do lado da QCertifica é manual, fora do escopo de automação**: o Thiago pediu
  explicitamente para não automatizar acesso a outro ambiente (QCertifica) — o subAgent deve se
  limitar a documentar as variações/cenários testados (o que foi enviado, com quais dados, qual
  resultado apareceu no Beyond), e o Thiago confere manualmente do lado da QCertifica como esses
  cadastros foram recebidos.
- Há queries SQL de apoio para localizar candidatos (CNPJs/pessoas recém-criados em produção) e
  para conferir dados já propagados — ver seção "Gatilho / fluxo". **O subAgent já tem acesso
  direto ao SQL Server** e pode rodar essas queries sozinho (confirmado pelo Thiago, 2026-09-18).

## Ambiente
- HML (Beyond Banking). Perfil de login: "master".
- Endpoint/URL específico da QCertifica em HML: não levantado ainda (não deveria ser necessário
  para o subAgent, já que a validação do lado da QCertifica não é automatizada).

## Casos de erro conhecidos
Validações de pré-envio (antes de enviar o cadastro do cedente para a QCertifica):
- Erro se o cedente não tiver cadastro de pessoa de contato ("Cad Pessoa Contato").
- Erro se houver caractere não numérico no campo `num_endereco` do cedente.
- Erro se o cedente não possuir nome fantasia, razão social ou endereço preenchidos.
- Erro se houver campos obrigatórios em branco.
- Demais cenários encontrados durante a execução devem ser adicionados aqui (e em
  `docs/documentacao.md` do módulo `contratos`).

## Regras de negócio para assinantes
- Representantes/devedores solidários que assinam o contrato devem assinar exatamente o mesmo
  documento selecionado pra eles na etapa de cadastro de pessoas ligadas.
- No envio para assinatura, devem constar obrigatoriamente os assinantes de Consultoria, Gestora e
  Administradora — cada um cadastrado como representante da respectiva entidade.
- Quem assina pelo Cedente é a pessoa ligada que tem aquele documento na sua lista de documentos.
- Se a pessoa ligada for um devedor solidário PJ, buscar recursivamente quem assina aquele
  documento como pessoa ligada da própria PJ.

## Material de apoio adicional
- `material/fluxo-integrado-cadastro.docx` — documento original fornecido pelo Thiago (2026-09-18),
  com o roteiro completo e as queries SQL de apoio.

## Consumido por
- `SupTestesFrontEnd`, módulo `contratos` — tarefa
  `20260917115830-envio-contrato-mae-qcertifica.md` (QA exploratório validando o cadastro de
  cedente e o envio do contrato mãe para a QCertifica).
