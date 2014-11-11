require 'socket'


class Node
	Request = Struct.new(:key, :host, :port)
	attr_accessor :port, :socket, :neighbour_socket, :request_queue, :resource_table

	def initialize(port, neighbour_ip = nil, neighbour_port = nil)
		@port = port
		@neighbour_socket = UDPSocket.new(neighbour_ip, neighbour_port) unless neighbour_ip.nil?
		@socket = UDPSocket.new
		@request_queue = []
		@resource_table = {}
		start_listening
	end

	def start_listening
		@socket.bind(nil, @port)
		while true
			text, sender = @socket.recvfrom(1024)
			remote_host = sender[3]

			msg_type = "unknown"
			msg_type = "GET" if text.include?("GET") 
			msg_type = "PUT" if text.include?("PUT")

			puts "Received msg: #{msg_type} from remote #{remote_host}"
		end
	end

	def put(key, value)
		@resource_table[key] = value if @resource_table[key].nil?
	end

	def get(key, client_addr_info)
		client_port = client_addr_info[1]
		client_host = client_addr_info[3]
		@request_queue.push Request.new(key, client_port, client_host)
	end
end

port, neighbour_ip, neighbour_port = ARGV 

Node.new(port, neighbour_ip, neighbour_port)