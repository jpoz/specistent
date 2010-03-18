require 'lib/server'

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 8081, SpecistentServer
}