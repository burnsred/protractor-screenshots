## Quick overview
Install with
```
npm install protractor-screenshots
```

At the top of the test spec you need
```js
var screenshots = require('protractor-screenshots');
```

During a test, run
```
screenshots.checkScreenshot('my-screenshot-name')
```

If screenshots do not exist, or do not match, test output will show
```
Expected false to be true, 'numbers-added - 768x1024 on mac-phantomjs-1.9.7: differed by 2.06%'
Expected false to be true, 'empty-memory - 768x1024 on mac-phantomjs-1.9.7: missing'.
```
and failed or missing screenshots will be created and categorised by name,
suite, spec, size, browser, browser version and platform under the screenshot
base path.

## Options
You probably want to configure protractor.conf.js to say where to put the
screenshots:

```
exports.config = {
	params: {
		screenshotsBasePath: 'test/e2e/screenshots'
	}
};
```

You can set the size of the screenshots to be taken according to each
capability:
```
exports.config = {
	params: {
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
		]
	}
}
```
Entries are matched to capabilities in order of their appearance in this list.
For instance, if the current browser has the capability 'phantomjs', it will
match the first size configuration in the above list. If there was a later
configuration with browserName set to phantomjs it would be ignored.

You can also disable screenshots with the parameter 'disableScreenshots'.
This is particularly useful when called from the command line:
```
protractor protractor.conf.js --params.disableScreenshots
```
