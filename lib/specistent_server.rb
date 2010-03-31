require 'rubygems'
require 'eventmachine'
require 'logger'
require 'git'

module SpecProcess
  
  def initialize(socket)
    @socket = socket
  end
  
  def receive_data(data)
    puts "sent #{data}"
    @socket.send_data(data)
  end
  
end

class SpecistentServer < EM::Protocols::LineAndTextProtocol
  include EM::Protocols::LineText2
  
  def initialize
    @databuf = []
    @g = nil
    @directory = nil
  end
  
  def command(cmd)
    case cmd
    when /run\s(\w*)\/(\w*)\s(.*)/
      @g = Git.open(Dir.pwd)
      puts @g.pull($1, "#{$1}/#{$2}", "#{$1} pull")
      EM.popen("/bin/sh -c 'RAILS_ENV=#{RENV} spec #{$3}'", SpecProcess, self)
    else
      send_data("unknown command #{cmd.inspect}\r\n")
    end
  end

  def receive_data(data)
    @databuf << data
    puts data
    if (/(.*)\;/ =~ @databuf.to_s)
      command($1)
      reset_databuf()
    end
  end

  private
  def reset_databuf
    @databuf = []
  end
end

