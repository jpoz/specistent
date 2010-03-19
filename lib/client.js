var tcp = require('tcp'),
    sys = require('sys'),
    fs  = require("fs")

var settings = ["sirius.local:8081","sirius.local:8082","sirius.local:8083"];

var serverFiles = [null];

function makeClientCallback(con, index) {
  return function() {
    writeTo(con, index);
  };
}

function saveToBranch(callback) {
  sys.exec("git stash save && git checkout -b tmp_test_branch && git stash apply && git commit -am 'test commit' && git checkout @{-1} && git stash pop",   
  function (err, stdout, stderr) {
    findFiles()
  });
}
 
var writeTo = function(con, index) {
    if (con.readyState == 'open') {
      con.write(serverFiles[index].join(' '))
    } else {
      setTimeout(writeTo, 100, con, index);
    }
 }
 
var readFrom = function(data) {
  sys.print(data);
}

var closeConnection = function() {
  this.close();
}

var connect = function() {
  for( var i in settings) {
    var server = settings[i].split(":");
    var connection = tcp.createConnection(server[1], server[0]);
    var callback = makeClientCallback(connection, i);
    connection.addListener('connect', callback);
    connection.addListener('data', readFrom);
    connection.addListener('end', readFrom);
  }
}

function findFiles() {
  sys.exec("ls -l spec/**/*_spec.rb | awk '{print $9}'", function (err, stdout, stderr) {
    if (err) throw err;
    sys.puts(stdout);
    var files = stdout.split("\n");
    files.pop();
    sys.puts(settings.length + " servers");

    sys.puts("Found "+files.length+" spec files");
  
    for( var i in files) {
      var serverIndex = (i % settings.length);
      if (!serverFiles[serverIndex]) serverFiles[serverIndex] = [];
    
      serverFiles[serverIndex].push(files[i]);
    }
  
    sys.puts("≈ "+serverFiles[0].length + " files per server");
  
    connect();
  });
}

saveToBranch();


