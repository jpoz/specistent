var tcp = require('tcp'),
    sys = require('sys'),
    fs  = require("fs")

var settings = [8081,8082,8083]
 
var writeTo = function() {
    var con = this;
    if (con.readyState == 'open') {
      con.write('/Code/Ruby/almaz')
    } else {
      setTimeout(writeTo, 100, con);
    }
 }
 
 var readFrom = function(data) {
    sys.puts(data);
 }

for( var i in settings) {
  var connection = tcp.createConnection(settings[i]);
  connection.addListener('connect', writeTo);
  connection.addListener('data', readFrom);
}


