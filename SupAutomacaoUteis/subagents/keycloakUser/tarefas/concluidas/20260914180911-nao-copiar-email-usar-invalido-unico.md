---
id: 20260914180911-nao-copiar-email-usar-invalido-unico
modulo: keycloakUser
tipo: automacao-uteis
solicitado_por: Thiago
data: 2026-09-14
---

## Descrição

Correção de comportamento pedida pelo Thiago sobre a clonagem de usuário Keycloak PROD→HML: o
**email não pode ser copiado do usuário original** para o novo usuário em HML, porque isso causa
conflito de criação quando o mesmo email já existe em HML (já era um dos casos de dúvida bloqueante
da tarefa original). Em vez de copiar o email e tratar a colisão como dúvida, o novo usuário em HML
deve sempre receber um **email inválido/não-real e único**, gerado automaticamente — nunca o email
do usuário de PROD.

**Vale para os dois modos** (confirmado explicitamente pelo Thiago):
- Modo de execução única via `--env` (tarefa original `20260914115110-clonar-usuario-keycloak-prod-hml`,
  já implementada e mergeada em `reviewAgents`) — precisa de correção no código já existente.
- Modo em lote (tarefa `20260914174624-clonar-usuarios-em-lote`) — se essa tarefa **ainda estiver em
  andamento** quando esta for pega, aplique o comportamento correto diretamente nela em vez de
  corrigir depois; se já tiver sido concluída/mergeada antes desta tarefa começar, trate como uma
  correção separada nela também.

### Formato sugerido do email gerado

Não existe uma exigência de formato específica do Thiago além de "aleatório e inválido, não repete
nunca". Sugestão (ajuste se encontrar algo mais alinhado ao padrão do projeto): combinar o
`novoUsername` (que já é exigido único em HML) com um sufixo aleatório e um domínio claramente não
real, ex. `{novoUsername}.{sufixoAleatorio}@invalido.multiplica.local` — garante unicidade mesmo em
reexecuções e deixa óbvio, pra quem olhar o cadastro em HML, que não é um email real/alcançável.

### O que isso muda na tarefa original

O caso de dúvida bloqueante "o email do usuário original já existe em HML" (seção "Casos que NÃO
devem ser decididos sozinhos" da tarefa original) deixa de fazer sentido — o email nunca mais vem do
usuário original, então não tem mais como colidir com o dele. O conflito que ainda importa é só o de
**username** (esse continua sendo dúvida bloqueante normalmente).

## Critérios de aceite

- Clonar um usuário (nos dois modos) nunca grava, em HML, o email do usuário original — sempre um
  email gerado, inválido/não-real, único por execução.
- Rodar a clonagem várias vezes (usernames diferentes) nunca gera conflito de email em HML.
- Autoteste cobre: dois clones seguidos (ou dois itens da lista, no modo em lote) confirmando que os
  emails gerados são diferentes entre si e diferentes do email original do usuário de PROD.
- `README.md`/`CLAUDE.md` do repositório atualizados refletindo que o email não é mais copiado do
  usuário original.

## Material de apoio

- Tarefa original (modo único): `../concluidas/20260914115110-clonar-usuario-keycloak-prod-hml.md`.
- Tarefa do modo em lote (pode estar em `executando/` ou `concluidas/` dependendo de quando esta for
  processada): `20260914174624-clonar-usuarios-em-lote.md`.
