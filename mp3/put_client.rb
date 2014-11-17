require 'socket'

class PutClient
	Request = Struct.new(:key, :host, :port)
	NodeInfo = Struct.new(:host, :port)
	attr_accessor  :host, :port

	def initialize(host = 'localhost', port = 1234, key = 1, value = "Hello")
		@port = port
		@host = host
		put(key, value)
	end

	def put(key, value)
		puts "Sending to #{@host}:#{@port}"
		node_socket = UDPSocket.new
		serialized = Marshal.dump(["PUT", key, value])
		node_socket.send serialized, 0, @host, @port
		node_socket.close
	end
end

host, port, key, value = ARGV
host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address if host == 'localhost'
PutClient.new(host, port, key, value)