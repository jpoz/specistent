var tcp = require('tcp'),
    sys = require('sys'),
    fs  = require("fs");
    
var port = process.argv[2];
var env = process.argv[3];

process.addListener('uncaughtException', function(exception) {
  sys.puts("ERROR: " + exception);
});

var server = tcp.createServer(function (socket) {
  socket.setEncoding("utf8");
  socket.setTimeout(0);
  
  socket.addListener("connect", function () {
    socket.write("connected\r\n");
  });
  socket.addListener("data", function (files) {
    // var path = data;
    // var spec = process.createChildProcess("ruby -e' $stdout.sync = true; puts `cd " + path + " && rake spec` '", []);
    var command = "RAILS_ENV=" + env + " spec " + files
    // sys.puts(command);
    
    var spec = process.createChildProcess("/bin/sh", ["-c", command]);
   
    spec.addListener("output", function (d) {
      sys.print(d);
      socket.write(d);
    });
    
    spec.addListener("error", function (d) {
      sys.print("ERROR" + d);
    });
    
    spec.addListener("exit", function (d) {
      socket.close();
      sys.puts("exit" + d);
    });
    
  });
  socket.addListener("end", function () {
    socket.write("master goodbye\r\n");
    socket.close();
  });
});

server.listen(port);

sys.puts("listening on port "+port);