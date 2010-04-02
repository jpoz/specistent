require 'rubygems'
require 'eventmachine'
require 'logger'
require 'git'

module SpecistentClient
  
  attr_accessor :files, :branch, :remote
  attr_reader   :connected
  
  def initialize()
    @connected = true
  end

  def start_spec 
    return puts "NO files" if files.empty?
    send_data "run #{remote}/#{branch} #{files.join(' ')};"
  end

  def receive_data(data)
    print data
    STDOUT.flush
  end

  def unbind
    @connected = false
  end

end

