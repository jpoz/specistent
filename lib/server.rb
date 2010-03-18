require 'rubygems'
require 'eventmachine'
require 'logger'
require 'git'

class SpecistentServer < EM::Protocols::LineAndTextProtocol
  include EM::Protocols::LineText2
  
  def initialize
    @databuf = []
    @g = nil
    @directory = nil
  end
  
  def command(cmd)
    case cmd
    when "remotes"
      remotes = @g ? %Q{remotes:\r\n#{@g.remotes.map{ |r| "  " + r.name + " -> " + r.url }.join("\r\n")}} : "No git repo set use setdir\r\n"
      send_data(remotes)
    when /setdir (.*)/
      @directory = $1
      @g = Git.open($1)
      send_data("Directory set to #{$1}\r\n")
    when /fetch (.*)/
      @g.remote($1).fetch
      send_data("Pulled from #{$1}\r\n")
    when /run\s?(.*)/
      return send_data('Set a directory: setdir /path/to/git_repo') unless @directory
      ls = EventMachine::DeferrableChildProcess.open("ruby -e' $stdout.sync = true; puts `cd #{@directory} && rake spec #{$1}` '")
      ls.callback do |result|
        send_data(result)
      end
      ls.errback do |error|
        send_data(error)
      end
    when /exec\s(.*)/
      puts $1
      @directory = $1
      @g = Git.open($1)
      send_data("Directory set to #{$1}\r\n")
      return send_data('Set a directory: setdir /path/to/git_repo') unless @directory
      ls = EventMachine::DeferrableChildProcess.open("ruby -e' $stdout.sync = true; puts `cd #{@directory} && rake spec` '")
      ls.callback do |result|
        send_data(result)
      end
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

