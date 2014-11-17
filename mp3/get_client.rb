require 'socket'

class GetClient
	Request = Struct.new(:key, :host, :port)
	NodeInfo = Struct.new(:host, :port)
	attr_accessor :remote_host, :port, :host, :local_port, :regex

	def initialize(remote_host = 'localhost', port = 1234, key = 1)
		@regex = /(\w*)\((.*)\)/
		@port = port
		@local_port = port.to_i + 4234
		@remote_host = remote_host
		get(key)
	end

	def get(key)
		node_socket = UDPSocket.new
		node_socket.setsockopt(:SOCKET, :REUSEADDR, true)
		puts "Connecting on #{@remote_host} #{@local_port}"
		node_socket.bind(@remote_host, @local_port)
		serialized = Marshal.dump(["GET", key, @local_port])
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
host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address if host == "localhost"
GetClient.new(host, port, key)