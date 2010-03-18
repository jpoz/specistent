require 'lib/server'

port = ARGV[0] || 8081

EventMachine::run {
  EventMachine::start_server "127.0.0.1", port, SpecistentServer
}