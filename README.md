## Quick overview
Install with
```
npm install protractor-screenshots
```

At the top of the test spec you need
```js
screenshots = require('protractor-screenshots');
```

During a test, run
```
screenshots.checkScreenshots('my-screenshot-name')
```

If screenshots do not exist, or do not match, test output will show
```
Expected false to be true, 'empty-memory - iphone-landscape-480x1000: differed by 0.13%'.
Expected false to be true, 'full-memory - ipad-portrait-768x1000: missing'.
```
and failed or missing screenshots will be created and categorised by name,
suite, spec, size and browser under the screenshot base path.

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
