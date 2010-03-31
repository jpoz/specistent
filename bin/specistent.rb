$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'specistent_server'
require 'specistent_client'
require 'optparse'

options = {
  :klass => SpecistentClient,
  :port => 8081,
  :env => 'test',
  :remote => 'origin'
}
OptionParser.new do |opts|
  opts.banner = "Usage: specistent [options]"

  opts.on("-s","--server", "Run as Server") do |v|
    options[:klass] = SpecistentServer 
  end
  
  opts.on("-p","--port PORT", "Port") do |p|
    options[:port] = p.to_i
  end
  
  opts.on("-e","--env ENV", "Environment") do |e|
    options[:env] = e
  end
  
  opts.on("-b","--branch BRANCH", "git branch to pull from (defaults to current branch)") do |b|
    options[:branch] = b
  end
  
  opts.on("-r","--remote REMOTE", "git remote to pull from (default origin)") do |b|
    options[:remote] = b
  end

end.parse!

puts options.inspect

servers = [['localhost',8081,[]],['localhost',8082,[]]]

if (SpecistentServer == options[:klass])
  g = Git.open(Dir.pwd)
  RENV = options[:env]
  EventMachine::run {
    puts "Started server on port #{options[:port]}"
    EventMachine::start_server "127.0.0.1", options[:port], SpecistentServer
  }
else
  options[:branch] ||= Git.open(Dir.pwd).branch.name
  EM.run {
    queue = EM::Queue.new
    processor = proc{ |connection_array| 
      EventMachine::connect( connection_array[0], connection_array[1], SpecistentClient ) { |c|
        c.files = connection_array[2]
        c.branch = options[:branch]
        c.remote = options[:remote]
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