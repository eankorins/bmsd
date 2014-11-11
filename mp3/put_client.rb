require 'socket'

class PutClient
	attr_accessor  :host, :port

	def initialize(host = 'localhost', port = 1234, key = 1, value = "Hello")
		@port = port
		@host = host
		put(key, value)
	end

	def put(key, value)
		node_socket = UDPSocket.new
		node_socket.send "PUT(#{key},#{value})", 0, @host, @port
		node_socket.close
	end
end

host, port, key, value = ARGV

PutClient.new(host, port, key, value)