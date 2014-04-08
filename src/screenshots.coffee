fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
slug = require 'slug'
resemble = require('resemble').resemble
Q = require 'q'

browserName = ''
browser.getCapabilities().then (capabilities) ->
    browserName = capabilities.caps_.browserName.toLowerCase()

disableScreenshots = browser.params['disable-screenshots']
screenshotBase = browser.params['screenshots-base-path'] || '.'

getPath = (suite) ->
    buildName = (suite) ->
        prefix = ''
        if suite.parentSuite
            prefix = "#{buildName(suite.parentSuite)} "
        return "#{prefix}#{suite.description}"

    return screenshotBase + '/' + slug(buildName(suite)) + '/' + browserName

matchScreenshot = (spec, screenshotName, screenshot) ->
    path = getPath(spec.suite)

    label = "#{screenshotName} - #{screenshot.label}-#{screenshot.width}x#{screenshot.height}"
    filename = "#{slug(spec.description + " " + screenshotName)}-#{screenshot.label}-#{screenshot.width}x#{screenshot.height}.png"

    return Q.fcall () ->
        if not spec.suite._screenshotsInitialized
            # Clear the old failure shots
            return Q.all([
                Q.nfcall(rimraf, path + '/missing'),
                Q.nfcall(rimraf, path + '/failed'),
                Q.nfcall(rimraf, path + '/diff')
            ])
        else
            return true
    .then () ->
        spec.suite._screenshotsInitialized = true

        return Q.nfcall(fs.readFile, path + '/' + filename)
    .then (data) ->
        # Fast check via string matching
        if screenshot.data == data.toString('base64')
            return { match: true }

        # Didn't match, but now we will check using resemblejs
        deferred = Q.defer()
        resemble(new Buffer(screenshot.data, 'base64'))
        .compareTo(data)
        .onComplete (result) ->
            if result.misMatchPercentage == '0.00'
                deferred.resolve { match: true }
            else
                deferred.resolve {
                    match: false,
                    label: label,
                    path: path,
                    filename: filename,
                    actual: screenshot.data,
                    difference: result.getImageDataUrl().substr(22),
                    reason: "differed by #{result.misMatchPercentage}%"
                }

        return deferred.promise
    , (error) ->
        if error
            return Q({
                label: label,
                path: path,
                filename: filename,
                actual: screenshot.data,
                match: false,
                missing: true
                reason: 'missing'
            })

    .then (result) ->
        if !result.match
            saveFailureImages(result)

        expect(result.match).toBe(true, "#{result.label}: #{result.reason}")

saveFailureImages = (result) ->
    writeImage = (path, data) ->
        return Q.nfcall(mkdirp, path).then () ->
            return Q.nfcall(
                fs.writeFile,
                "#{path}/#{result.filename}",
                data,
                { encoding: 'base64'}
            )

    if result.missing
        return Q.all([
            writeImage("#{result.path}/missing", result.actual)
        ])
    else
        return Q.all([
            writeImage("#{result.path}/failed", result.actual)
            writeImage("#{result.path}/diff", result.difference)
        ])

takeScreenshots = (spec, screenshotName) ->
    setScreenSize = (width, height) ->
        return browser.driver.manage().window().setSize(width, height)

    matchingPromises = []
    shotsTakenPromise = exports.sizes.reduce (soFar, size) ->
        soFar.then(
            setScreenSize(size.width, size.height)
            .then () ->
                return browser.takeScreenshot()
            .then (screenshot) ->
                matchingPromises.push(
                    matchScreenshot(spec, screenshotName, {
                        label: size.label,
                        width: size.width,
                        height: size.height,
                        data: screenshot
                    })
                )
                return true
        )
    , Q(true)

    return shotsTakenPromise.then () ->
        return Q.all(matchingPromises)

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

# Call to take an array of screenshots during tests
exports.checkScreenshots = (spec, screenshotName) ->
    if disableScreenshots
        return

    return takeScreenshots(spec, screenshotName)
