require 'socket'

class GetClient
	attr_accessor :remote_host, :port, :host

	def initialize(remote_host = 'localhost', port = 1234, key = 1)
		@port = port
		@remote_host = remote_host
		@host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
		get(key)
	end

	def get(key)
		node_socket = UDPSocket.new
		node_socket.bind(@host, @port)
		node_socket.send "GET(#{key}, #{@host}, #{@port})", 0, @remote_host, @port
		
		while true
			text, sender = node_socket.recvfrom(1024)
			remote_host = sender[3]

			msg_type = "unknown"
			msg_type = "PUT" if text.include?("PUT")

			puts "Received msg: #{text} from remote #{remote_host}"
			puts "Closing"

			node_socket.close
			break
		end
	end
end

host, port, key = ARGV

GetClient.new(host, port, key)