var tcp = require('tcp'),
    sys = require('sys'),
    fs  = require("fs");
    
var port = process.argv[2];


var server = tcp.createServer(function (socket) {
  socket.setEncoding("utf8");
  socket.addListener("connect", function () {
    socket.write("master connected\r\n");
  });
  socket.addListener("data", function (data) {
    var path = data;
    
    // var spec = process.createChildProcess("ruby -e' $stdout.sync = true; puts `cd " + path + " && rake spec` '", []);
    var ruby = "cd " + path + " && rake spec"
    var spec = process.createChildProcess("/bin/sh", ["-c", ruby]);
   
    spec.addListener("output", function (d) {
      sys.puts("output" + d);
      socket.write(d);
    });
    
    spec.addListener("error", function (d) {
      sys.puts("error" + d);
    });
    
    spec.addListener("exit", function (d) {
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