const { defineConfig } = require('cypress');
require('dotenv').config();

module.exports = defineConfig({
  video: false,
  screenshotsFolder: 'cypress/screenshots',
  e2e: {
    specPattern: 'cypress/e2e/**/*.cy.js',
    supportFile: 'cypress/support/e2e.js',
    setupNodeEvents(on, config) {
      config.env = { ...config.env, ...process.env };
      return config;
    },
  },
});
