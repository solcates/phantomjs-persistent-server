var Future = Npm.require('fibers/future');
var phantomjs = Npm.require('phantomjs');
var shell = Npm.require('child_process');

// methods: array of filenames relative to package asset directory
//          each file should append entries to the methods object like so:
//          methods.example = function(options, callback){
//            if(error) callback(error);
//            else callback(undefined, output);
//          }
// port:    optionally, specify a port number. Undefined will auto-select a port.
phantomLaunch = function(methods, port){
  var portStatus;
  if(!port){
    // An unspecified port will automatically select a port
    port = 13470; // Default port
    while(getPortStatus(port) !== undefined){
      port++;
    };
  };
  // Function to return for executing methods on this server
  var executive = function(method, options){
    var url = 'http://localhost:' + port + '/';
    console.log('Post to', url, options);
    return HTTP.post(url, {
      headers: {method: method},
      params: options
    });
  };
  
  var fut = new Future();
  portStatus = getPortStatus(port);
  if(portStatus === 'in-use'){
    // Port in use by a different server
    throw new Meteor.Error(500, 'port-in-use');
  }else if(portStatus === undefined){
    var command = shell.spawn(phantomjs.path,
      [assetDir + 'phantom-server.js', port, methods.join(',')]);
    command.stdout.pipe(process.stdout);
    command.stderr.pipe(process.stderr);
    command.stdout.on('data', Meteor.bindEnvironment(function(data){
      data = String(data).trim();
      if(data === 'Ready.'){
        fut['return'](executive);
      };
    }));
    command.on('exit', Meteor.bindEnvironment(function(code){
      // Restart on exit
      phantomLaunch(port, methods);
    }));
  };
  return fut.wait();
};

// Return undefined if port open, 
//        'in-use'  if port occupied by other server
//        pid       if port occupied by phantomjs server
var getPortStatus = function(port){
  var fut = new Future();
  var command  = shell.spawn('lsof', ['-i:' + port]);
  command.stdout.on('data', Meteor.bindEnvironment(function(data){
    if(!fut.isResolved()){
      data = String(data).split('\n');
      if(data.length < 3){
        return fut['return'](undefined);
      };
      var infoLine = data[1].split(' ');
      if(infoLine[0] === 'phantomjs'){
        return fut['return'](infoLine[1]);
      };
      fut['return']('in-use');
    };
  }));
  command.stderr.on('data', Meteor.bindEnvironment(function(data){
    if(!fut.isResolved()){
      data = String(data);
      fut['throw'](data);
    };
  }));
  command.on('exit', Meteor.bindEnvironment(function(code){
    Meteor.setTimeout(function(){
      if(!fut.isResolved()){
        fut['return'](undefined);
      };
    }, 100);
  }));
  return fut.wait();
};