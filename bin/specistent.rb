$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'specistent_server'
require 'specistent_client'

arg = "Specistent" + (ARGV[0]|| "Server").capitalize 
klass = Kernel.const_get( arg )
port = ARGV[1] || 8081

servers = [['localhost',8081,[]],['localhost',8082,[]],['localhost',8083,[]]]

if (SpecistentServer == klass) 
  puts "Starting server on port #{port}"
  EventMachine::run {
    EventMachine::start_server "127.0.0.1", port, SpecistentServer
  }
else
  EM.run {
    queue = EM::Queue.new
    processor = proc{ |connection_array| 
      EventMachine::connect( connection_array[0], connection_array[1], klass ) { |c|
        c.files = connection_array[2]
        puts c.files
        c.start_spec
      }
      queue.pop(&processor)
    }
    queue.pop(&processor)
    
    files = Dir.glob("spec/**/*_spec.rb")
    files.each_with_index do |f, i|
      server_index = (i % servers.size)
      servers[server_index][2] << f
    end
    
    servers.each do |s|
      queue.push(s)
    end
  }
end