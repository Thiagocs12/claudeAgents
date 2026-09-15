// Suporte mínimo — este projeto Cypress é ferramenta de execução descartável do subAgent do
// módulo "mop" (Sup TestesFrontEnd), não uma suíte persistente. Evite acumular comandos/page
// objects aqui: conhecimento reutilizável fica em texto, em ../docs/documentacao.md.

// Armadilha de ambiente já conhecida (ver SupE2eAutomation/docs/conhecimento-geral.md): o widget
// de menu (mc-menu.js, beyond-hml.grupomultiplica.com.br) às vezes lança uma exceção não tratada
// própria ao clicar em "Beyond BackOffice", que derrubaria o teste por padrão sem afetar a
// navegação visual real.
Cypress.on('uncaught:exception', (err) => {
  if (err.message.includes("Cannot read properties of undefined (reading 'content')")) {
    return false;
  }
  return true;
});
