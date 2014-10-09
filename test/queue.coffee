testAsyncMulti 'phantomjs-queue - echoExample', [
  (test, expect) ->
    phantomExec = phantomLaunch(['methods/echoExample.js'])
    result = phantomExec('echo', {cow: 'horse'})
    test.equal result.cow, 'horse'
    test.equal result.echoed, "fo'sho"
]

testAsyncMulti 'phantomjs-queue - getSheetsFromUrl', [
  (test, expect) ->
    phantomExec = phantomLaunch([
      'test/methods/samplePageServer.js',
      'methods/getSheetsFromUrl.js'
    ])
    port = 32459
    phantomExec 'startServer', {port: port}

    # Test success case
    sheetsExpected = [
      '<link rel="stylesheet" media="" ' +
        'href="http://localhost:' + port + '/sample.css" type="">',
      '<style>h2 { color: #00f; }</style>'
    ]
    sheetsOutput = phantomExec 'getSheetsFromUrl', {url: 'http://localhost:' + port}
    sheetsExpected.forEach (exp) ->
      test.isTrue sheetsOutput.indexOf(exp) > -1

    phantomExec 'stopServer'

    # Test failure case
    sheetsFailOutput = phantomExec 'getSheetsFromUrl', {url: 'http://localhost:' + port}
    test.equal sheetsFailOutput.error, 500
    test.equal sheetsFailOutput.reason.code, 'load-failure'
    
]