require 'socket'

class GetClient
	Request = Struct.new(:key, :host, :port)
	NodeInfo = Struct.new(:host, :port)
	attr_accessor :remote_host, :port, :host, :regex

	def initialize(remote_host = 'localhost', port = 1234, key = 1)
		@regex = /(\w*)\((.*)\)/
		@port = port
		@remote_host = remote_host
		@host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
		get(key)
	end

	def get(key)
		node_socket = UDPSocket.new
		puts "Connecting on #{@host} #{@port}"
		node_socket.bind(@host, @port)
		serialized = Marshal.dump(["GET", key])
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