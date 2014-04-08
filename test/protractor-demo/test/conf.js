// Tests for the calculator.
exports.config = {
  specs: [
    'spec.js'
  ],

  multiCapabilities: [
    {
      'browserName': 'phantomjs',
      'phantomjs.binary.path': '../../node_modules/phantomjs/bin/phantomjs',
    },
    {
      'browserName': 'chrome'
    }
  ],

  params: {
    'screenshots-base-path': 'test/screenshots'
  },

  baseUrl: 'http://localhost:8888',
};
