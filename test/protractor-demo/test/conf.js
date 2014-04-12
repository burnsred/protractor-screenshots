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
    screenshotsBasePath: 'test/screenshots',
    screenshotSizes: [
        {
          browserName: 'phantomjs',
          sizes: [
            { width: 320, height: 480 }, // iPhone portrait
            { width: 768, height: 1024 } // iPad landscape
          ]
        },
        {
          browserName: 'chrome',
          sizes: [
            { width: 500, height: 500 },
          ]
        }
    ],
  },

  baseUrl: 'http://localhost:8888',
};
