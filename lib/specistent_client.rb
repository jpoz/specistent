require 'rubygems'
require 'eventmachine'
require 'logger'
require 'git'

module SpecistentClient # < EventMachine::Connection
  
  attr_accessor :files

  def start_spec 
    return puts "NO files" if files.empty?
    send_data "run #{files.join(' ')};"
  end

  def receive_data(data)
   print data
   STDOUT.flush
  end

  def unbind
   puts "A connection has terminated"
  end

end

