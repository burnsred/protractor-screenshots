## Quick overview
Install with
```
npm install protractor-screenshots
```

When starting a test suite, initialize for screenshots
```js
screenshots = require('protractor-screenshots');

describe('apps', function() {
    screenshots.initializeSuite(this);
});
```

During a test, run
```
expect(screenshots.takeScreenshots()).toMatchScreenshots('my-screenshot-name')
```

If screenshots do not exist, or do not match, test output will show
```
screenshots [desktop-1280x1000, ipad-landscape-1024x1000, ipad-portrait-768x1000, iphone-landscape-480x1000, iphone-portrait-320x1000] for login-failed did not match
```
and failed screenshots will be created and categorised by name, suite, spec,
size and browser under the screenshot base path.

## Configure new/different screen sizes

Modify `screenshots.sizes`.

## Options
You probably want to configure protractor.conf.js to say where to put the
screenshots:

```
exports.config = {
	params: {
		'screenshots-base-path': 'test/e2e/screenshots'
	}
};
```

You can also disable screenshots with the parameter 'disable-screenshots'.
This is particularly useful when called from the command line:
```
protractor protractor.conf.js --params.disable-screenshots
```
