fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
slug = require 'slug'
resemble = require('resemble').resemble
Q = require 'q'
_ = require 'lodash'

capabilityString = ''
capabilities = null
browser.getCapabilities().then (returnValue) ->
    capabilities = returnValue.caps_

    browserName = returnValue.caps_.browserName.toLowerCase()
    platform = returnValue.caps_.platform.toLowerCase()
    version = returnValue.caps_.version.toLowerCase()

    capabilityString = "#{platform}-#{browserName}-#{version}"

disableScreenshots = browser.params['disableScreenshots']
screenshotBase = browser.params['screenshotsBasePath'] || '.'

screenshotSizes = browser.params['screenshotSizes'] 

matchesCapabilities = (other) ->
    excludeKeys = ['sizes']

    return _.every other, (value, key) ->
        if excludeKeys.indexOf(key) != -1
            return true

        return capabilities[key] == value

getPath = (suite) ->
    buildName = (suite) ->
        prefix = ''
        if suite.parentSuite
            prefix = "#{buildName(suite.parentSuite)} "
        return "#{prefix}#{suite.description}"

    return "#{screenshotBase}/#{slug(buildName(suite))}/#{slug(capabilityString)}"

matchScreenshot = (spec, screenshotName, screenshot) ->
    path = getPath(spec.suite)

    label = "#{screenshotName} - #{screenshot.width}x#{screenshot.height}"
    filename = "#{slug(spec.description + " " + screenshotName)}-#{screenshot.width}x#{screenshot.height}.png"

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

        expect(result.match).toBe(true, "#{result.label} on #{capabilityString}: #{result.reason}")

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

takeScreenshot = (spec, screenshotName) ->
    setScreenSize = (width, height) ->
        return browser.driver.manage().window().setSize(width, height)

    screenSizes = _.find(screenshotSizes, matchesCapabilities)?.sizes

    actualTakeScreenshot = () ->
        browser.driver.manage().window().getSize()
        .then (screenSize) ->
            browser.takeScreenshot()
            .then (data) ->
                matchScreenshot(spec, screenshotName, {
                    width: screenSize.width,
                    height: screenSize.height,
                    data: data
                })

    if screenSizes?.length > 0
        screenSizes.reduce (soFar, size) ->
            soFar.then(
                setScreenSize(size.width, size.height)
                .then () ->
                    return actualTakeScreenshot()
            )
        , Q(true)
    else
        return actualTakeScreenshot()

###
Public API
###

exports.checkScreenshot = (spec, screenshotName) ->
    if disableScreenshots
        return

    return takeScreenshot(spec, screenshotName)
