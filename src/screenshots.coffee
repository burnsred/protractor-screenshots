fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
slug = require 'slug'
resemble = require('resemble').resemble

browserName = ''
browser.getCapabilities().then (capabilities) ->
    browserName = capabilities.caps_.browserName.toLowerCase()

disableScreenshots = browser.params['disable-screenshots']
screenshotBase = browser.params['screenshots-base-path'] || ''

getPath = (suiteName) ->
    return screenshotBase + '/' + slug(suiteName) + '/' + browserName

screenshotMatchers = {
    toMatchScreenshots: (name) ->
        if disableScreenshots
            return true

        me = this

        path = getPath(me.spec.suite.description)

        matchScreenshot = (screenshot) ->
            matches = false

            filename = "#{slug(me.spec.description + " " + name)}-#{screenshot.label}-#{screenshot.width}x#{screenshot.height}.png"

            try
                matches = (screenshot.data == fs.readFileSync(path + '/' + filename).toString('base64'))
            catch e
                ''

            if !matches
                mkdirp.sync(path + '/failed')

                fs.writeFileSync(
                    path + '/failed/' + filename,
                    screenshot.data,
                    { encoding: 'base64' }
                )

                try
                    mkdirp.sync(path + '/diff')

                    originalData = new Buffer(screenshot.data, 'base64')
                    expectedData = fs.readFileSync(path + '/' + filename)

                    resemble(originalData)
                    .compareTo(expectedData)
                    .onComplete (out) ->
                        output = out.getImageDataUrl().substr(22)
                        fs.writeFileSync(
                            path + '/diff/' + filename + '-diff.png',
                            output,
                            { encoding: 'base64' }
                        )
                catch e
                    ''

            return matches

        # HACK(mike): Take a copy of it or it ends up writing '<screenshot>'
        if !me.actualOriginal
            me.actualOriginal = me.actual

        allMatch = true
        failures = []
        me.actualOriginal.forEach (screenshot) ->
            matches = matchScreenshot(screenshot)
            if !matches
                failures.push "#{screenshot.label}-#{screenshot.width}x#{screenshot.height}"

            allMatch = allMatch && matches

        # Suppress actual huge string
        me.actual = '<screenshots>'

        me.message = (name) ->
            return "screenshots [#{failures.join(", ")}] for #{name} did not match"

        return allMatch
}

exports.sizes = [
    {
        label: 'desktop',
        width: 1280,
        height: 1000
    },
    {
        label: 'ipad-landscape'
        width: 1024
        height: 1000
    },
    {
        label: 'ipad-portrait'
        width: 768
        height: 1000
    },
    {
        label: 'iphone-landscape'
        width: 480
        height: 1000
    },
    {
        label: 'iphone-portrait'
        width: 320
        height: 1000
    }
]

###
Public API
###

# To be called during test suite setup
exports.initializeSuite = (suite) ->
    path = getPath(suite.description)

    # Clear the old failure shots
    rimraf.sync(path + '/failed')
    rimraf.sync(path + '/diff')

    beforeEach () ->
        this.addMatchers(screenshotMatchers)

# Call to take an array of screenshots during tests
exports.takeScreenshots = () ->
    if disableScreenshots
        return ''

    setScreenSize = (width, height) ->
        return browser.driver.manage().window().setSize(width, height)

    screenshots = []

    # Take a copy of the global sizes
    sizes = [].concat(exports.sizes)

    takeNextShot = () ->
        if sizes.length > 0
            size = sizes.shift()

            return setScreenSize(size.width, size.height)
            .then () ->
                return browser.takeScreenshot()
            .then (screenshot) ->
                screenshots.push {
                    label: size.label,
                    width: size.width,
                    height: size.height,
                    data: screenshot
                }

                return takeNextShot()
        else
            return screenshots

    return takeNextShot()
