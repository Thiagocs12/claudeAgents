---
id: 20260917115830-envio-contrato-mae-qcertifica
modulo: contratos
tipo: testes-frontend
solicitado_por: Thiago
data: 2026-09-17
---

## Objetivo
Validar a integração de envio do contrato mãe do sistema para o Qcertifica: completar o fluxo que
dispara esse envio (a partir da tela/ação correspondente, ver material de apoio) e confirmar que o
envio ocorre e é reconhecido como bem-sucedido pelo sistema. Objetivo amplo — o subAgent narra o
que tentar e o que acontece; refinar critérios de aceite conforme a especificação de apoio for
completada.

## Critérios de aceite
- A ser detalhado após a especificação em `especificacoes/contratos-qcertifica/especificacao.md`
  (Agente de Especificação) estar completa. Como piso mínimo: o contrato mãe deve ser enviado sem
  erro visível no sistema de origem, e deve haver alguma confirmação (na tela, em log acessível, ou
  outro sinal a definir) de que o envio ao Qcertifica foi concluído.

## Ambiente / perfil de login
HML, perfil "master". Bloqueado enquanto `PAUSA-HML.flag` existir na raiz do repo (ambiente HML
fora do ar desde 2026-09-16) — não tentar executar até a flag ser removida.

## Material de apoio
- `../../../../AgenteEspecificacao/especificacoes/contratos-qcertifica/especificacao.md`
  (levantamento ainda em andamento com o Thiago no momento da criação desta tarefa)
