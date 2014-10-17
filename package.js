// phantomjs-persistent-server
// MIT License ben@latenightsketches.com

Package.describe({
  summary: "PhantomJS Persistent Server",
  version: "0.0.6",
  git: "https://github.com/numtel/phantomjs-persistent-server.git"
});

var Future = Npm.require('fibers/future');
var shell = Npm.require('child_process');

var isPhantomInstalled = function() {
  var fut = new Future();
  var phantom = shell.exec('phantomjs -v', function(error, stdout, stderr){
    fut['return'](!error);
  });
  return fut.wait();
};

var packageContents = function(api) {
  api.use('underscore');
  api.use('http');
  if(isPhantomInstalled()){
    // Use installed phantomjs
    console.log('phantomjs installed');
    api.addFiles('src/phantomInstalled.js', 'server');
  }else{
    // Install it
    console.log('missing phantomjs');
    api.use('gadicohen:phantomjs@0.0.2');
  };
  api.addFiles('assetKey.js', 'server', {isAsset: true});
  api.addFiles('assetKey.js', 'server');

  api.addFiles('src/phantom-server.js', 'server', {isAsset: true});
  api.addFiles('src/main.js', 'server');
  api.export('phantomLaunch');
  console.log('hoooo');
};

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.3.1');
  packageContents(api);
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('test-helpers');
  api.use('coffeescript');
  api.use('underscore');
  packageContents(api);
  api.addFiles('test/main.coffee', 'server');
});
