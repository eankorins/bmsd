require 'socket'

class GetClient
	attr_accessor :host, :port

	def initialize(host = 'localhost', port = 1234, key = 1)
		@port = port
		@host = host
		get(key)
	end

	def get(key)
		node_socket = UDPSocket.new
		node_socket.send "GET(#{key},@host, @port)", 0, @host, @port
		
		while true
			text, sender = node_socket.recvfrom(1024)
			remote_host = sender[3]

			msg_type = "unknown"
			msg_type = "PUT" if text.include?("PUT")

			puts "Received msg: #{text} from remote #{remote_host}"
		end
	end
end

host, port, key = ARGV

GetClient.new(host, port, key)