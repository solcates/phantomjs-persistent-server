# phantomjs-persistent-server
# MIT License ben@latenightsketches.com
# Main Test Runner

console.time 'phantomLaunch'
phantomExec = phantomLaunch
  debug: true
console.timeEnd 'phantomLaunch'

testAsyncMulti 'phantomjs-persistent-server - second server + kill', [
  (test, expect) ->
    exec2 = phantomLaunch
      debug: true
    exec2Port = exec2.port
    test.equal typeof exec2, 'function'
    exec2.kill()

    # Ensure port is open by starting another server
    exec2 = phantomLaunch
      debug: true
      port: exec2Port
    test.equal typeof exec2, 'function'
]

testAsyncMulti 'phantomjs-persistent-server - second server same port failure', [
  (test, expect) ->
    test.throws (->
        exec2 = phantomLaunch
          debug: true
          port: phantomExec.port
      ), 'port-in-use'
]

testAsyncMulti 'phantomjs-persistent-server - echo', [
  (test, expect) ->
    sample = {cow: 'horse'}
    echoTest = (options, callback) ->
      callback undefined, options
    result = phantomExec echoTest, sample
    test.isTrue _.isEqual result, sample
]

testAsyncMulti 'phantomjs-persistent-server - handled error', [
  (test, expect) ->
    errorTest = (options, callback) ->
      callback 'load-failure'
    try
      result = phantomExec errorTest, {}
    catch err
      test.equal err.reason,
        'Error: failed [500] {"error":500,"reason":"load-failure"}'
      test.equal err.error, 500
    test.isUndefined result
]

testAsyncMulti 'phantomjs-persistent-server - unhandled error', [
  (test, expect) ->
    errorTest = (options, callback) ->
      invalidsymbol.horse()
      callback undefined, 'success'
    try
      result = phantomExec errorTest, {}
    catch err
      test.equal err.reason, 'Error: failed [500] {"error":500,"reason":"' + \
        'ReferenceError: Can\'t find variable: invalidsymbol"}'
      test.equal err.error, 500
    test.isUndefined result
]

testAsyncMulti 'phantomjs-persistent-server - no arguments', [
  (test, expect) ->
    argTest = (callback) ->
      callback undefined, 'someval'
    result = phantomExec argTest
    test.isTrue _.isEqual result, 'someval'
]

testAsyncMulti 'phantomjs-persistent-server - many arguments', [
  (test, expect) ->
    argTest = (callback) ->
      args = Array.prototype.slice.call arguments, 0
      callback = args.pop()
      sum = args.reduce (prev, cur) ->
        return prev + cur
      callback undefined, sum
    result = phantomExec argTest, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    # result is the sum of 1..13
    max = 13
    test.isTrue _.isEqual result, (max * (max + 1)) / 2
]

titleTest = (url, callback) ->
  webpage = require 'webpage'
  page = webpage.create()
  page.open url, (status) ->
    if status == 'fail'
      callback 'load-failure'
    else
      title = page.evaluate ()->
        return document.title
      callback undefined, title

testAsyncMulti 'phantomjs-persistent-server - get page title (success)', [
  (test, expect) ->
    result = phantomExec titleTest, 'http://google.com/'
    test.isTrue _.isEqual result, 'Google'
]

testAsyncMulti 'phantomjs-persistent-server - get page title (failure)', [
  (test, expect) ->
    try
      result = phantomExec titleTest, 'http://asjdfoafm/'
    catch err
      test.equal err.reason,
        'Error: failed [500] {"error":500,"reason":"load-failure"}'
      hadError = true
    finally
      test.isTrue hadError
]
