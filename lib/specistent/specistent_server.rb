require 'rubygems'
require 'eventmachine'
require 'logger'
require 'git'

module SpecProcess
  
  def initialize(socket)
    @socket = socket
  end
  
  def receive_data(data)
    print data
    @socket.send_data(data)
  end
  
  def unbind
    @socket.worker_completed
  end
  
end

class SpecistentServer < EM::Protocols::LineAndTextProtocol
  include EM::Protocols::LineText2
  
  attr_accessor :workers, :migrate
  
  def initialize
    @workers = 1
    @migrate = true
    @databuf = []  
    @g = nil
    @directory = nil
    @files = []
    @worker_files = []
    @running_workers = 0
  end
  
  def command(cmd)
    case cmd
    when /workers/
      send_data(@workers)
    when /run\s(\w*)\/(\w*)\s(.*)/
      @g = Git.open(Dir.pwd)
      puts @g.pull($1, "#{$1}/#{$2}", "#{$1} pull")
      @files = $3.split(' ')
      run_enviroments
    else
      send_data("unknown command #{cmd.inspect}\r\n")
    end
  end

  def receive_data(data)
    @databuf << data
    if (/(.*)\;/ =~ @databuf.to_s)
      command($1)
      reset_databuf()
    end
  end
  
  def run_enviroments
    split_files
    @workers.times do |i|
      test_env_number = i < 1 ? nil : i
      puts system("RAILS_ENV=test TEST_ENV_NUMBER=#{test_env_number} rake db:migrate") if @migrate
      EM.popen("/bin/sh -c 'TEST_ENV_NUMBER=#{test_env_number} spec #{@worker_files[i].join(' ')}'", SpecProcess, self)
      @running_workers += 1
    end
  end
  
  def split_files
    @workers.times { @worker_files << [] }
    @files.each_with_index do |f, i|
      worker_index = (i % @workers)
      @worker_files[worker_index] << f
    end
  end
  
  def worker_completed
    @running_workers -= 1
    puts "Working Completed #{@running_workers}"
    if 0 == @running_workers
      close_connection(true)
    end
  end

  private
  def reset_databuf
    @databuf = []
  end
end

