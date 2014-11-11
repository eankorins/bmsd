require 'socket'

class GetClient
	attr_accessor :remote_host, :port, :host, :regex

	def initialize(remote_host = 'localhost', port = 1234, key = 1)
		@regex = /(\w*)\((.*)\)/
		@port = port
		@remote_host = remote_host
		get(key)
	end

	def get(key)
		node_socket = UDPSocket.new
		node_socket.bind(@host, @port)
		serialized = Marshal.dump(["GET", key, @host, @port])
		node_socket.send serialized, 0, @remote_host, @port
		
		while true
			text, sender = node_socket.recvfrom(1024)
			arguments = Marshal.load(text)

			remote_host = sender[3]

			puts "Received msg: #{arguments} from remote #{remote_host}"
			puts "Closing"

			node_socket.close
			break
		end
	end
end

host, port, key = ARGV

GetClient.new(host, port, key)