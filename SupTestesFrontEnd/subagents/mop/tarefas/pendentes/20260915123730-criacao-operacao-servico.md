---
id: 20260915123730-criacao-operacao-servico
modulo: mop
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-15
---

## Objetivo

Criar uma operação de serviço no **Beyond Banking** e confirmar que ela avança corretamente até
aparecer concluída no Monitor Diário do **Beyond** (sistema diferente, ver seção "Ambiente"
abaixo). Este é o teste piloto do Sup TestesFrontEnd.

Roteiro de negócio (passo a passo dado pelo Thiago — a exploração real de seletores/telas é
trabalho do subAgent, isto aqui é o roteiro funcional a seguir):

1. Acessar o Beyond Banking (HML).
2. Selecionar o cedente **kenerson**.
3. Usar o **cadastro de cedente master** desse cedente (não outro cadastro/perfil que ele possa
   ter).
4. Acessar "Beyond Operação".
5. Clicar em **"Criar Operação"**.
6. Navegar até o serviço: **AQUISIÇÃO → ANTECIPAÇÃO DE DUPLICATA → DUPLICATA → SERVIÇO → BOLETO**.
7. Selecionar **qualquer conta**, aleatoriamente.
8. Incluir a operação **"por digitação"** (não por importação de arquivo).
9. Em **Cad Pessoa**, consultar **qualquer CPF** e usar essa pessoa como **sacado**.
10. Preencher os demais campos necessários (usar valores plausíveis/de teste onde não houver
    orientação específica — registrar na narrativa qualquer campo cujo valor não seja óbvio).
11. **Salvar** e **gerar a operação**.
12. Acessar o **dashboard de Operações** e **avançar a operação**.
13. Acessar o **Monitor Diário via `beyond.grupomultiplica.com.br`** (Beyond BackOffice, ver
    "Ambiente" — confirmar que caiu no ambiente HML antes de prosseguir, não em produção).
14. Verificar que a operação aparece lá, e que o **histórico mostra a etapa "Inclusão OPE" como
    concluída**.

## Critérios de aceite

- Operação criada com sucesso no Beyond Banking (sem erro bloqueante em nenhum passo 1-11).
- Operação avançada com sucesso a partir do dashboard de Operações (passo 12).
- Operação localizada no Monitor Diário do Beyond (passo 13).
- Histórico da operação no Monitor Diário mostra a etapa "Inclusão OPE" com status concluída.
- Toda tentativa (inclusive as que não deram certo de primeira) narrada passo a passo na seção
  `## Execução` deste arquivo, incluindo qualquer campo preenchido com valor não óbvio (registrar
  qual valor foi usado, para reprodutibilidade — nunca dado sensível real).

## Ambiente / perfil de login

- **Beyond Banking** (criação da operação): `https://beyondbanking-hml.grupomultiplica.com.br/`
  — HML. Login: mesmo SSO/Keycloak já mapeado (perfil `master`) — confirmar que funciona igual
  aqui; se pedir algo diferente, registrar dúvida em vez de assumir.
- **Beyond / Beyond BackOffice** (checagem no Monitor Diário): `beyond-hml.grupomultiplica.com.br`
  — HML (confirmado pelo Thiago em 2026-09-15; a menção sem `-hml` foi só um esquecimento de
  digitação, mesmo host já documentado pelo `SupE2eAutomation`).

## Material de apoio

- `docs/documentacao.md` deste módulo — login/navegação já mapeados pelo `SupE2eAutomation` no
  Beyond BackOffice (Monitor Diário), útil pro passo 13-14. Os passos 1-12 (Beyond Banking) são
  território totalmente novo, sem mapeamento prévio.
