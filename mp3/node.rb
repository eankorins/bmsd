require 'socket'
require 'stringio'

class Node
	Request = Struct.new(:key, :host, :port)
	NodeInfo = Struct.new(:host, :port)

	attr_accessor :info, :socket, :neighbour_nodes, :request_queue, :resource_table

	def initialize(port, neighbour_ip = nil, neighbour_port = nil)
		@socket = UDPSocket.new
		host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
		@info = NodeInfo.new(host, port)
		puts "#{info}"
		@neighbour_nodes = [] 
		@request_queue = []
		@resource_table = {}
		t = Thread.new{start_listening}
		send_neighbour(neighbour_ip, neighbour_port) unless neighbour_ip.nil?

		t.join
	end

	def start_listening
		@socket = UDPSocket.new
		@socket.bind(@info.host, @info.port)
		while true
			text, sender = @socket.recvfrom(1024)

			t = Thread.new { 
				arguments = Marshal.load(text)
				msg_type = arguments.shift
				
				puts "Received msg: #{msg_type}, #{arguments} from remote #{sender}"

				if msg_type == "GET"
					key, host, port = arguments
					get(key.to_i, host, port)
				elsif msg_type == "PUT"
					key, value = arguments
					put(key.to_i, value)
				elsif msg_type == "NEW_NODE"
					new_node_info = arguments.first
					new_network_node(new_node_info)
				elsif msg_type == "ADD_NODE"
					info = arguments.first
					@neighbour_nodes << info
				elsif msg_type == "DROP_NODE"
					info = arguments
					@neighbour_nodes - info
				elsif msg_type == "RESOURCE_TABLE"
					@route_table = arguments.first
				elsif msg_type == "ADD_RESOURCE"
					resource = arguments.first
					@resource_table.merge!(resource)
					resolve_queue(resource.key)
				end 
			}
		end
	end

	def new_network_node(new_node)
		node = NodeInfo.new(new_node.host, new_node.port)

		@neighbour_nodes.each do |n|
			send_message ["ADD_NODE", node], 0, n.host, n.port
			send_message ["ADD_NODE", n], 0, node.host, node.port
		end
		
		@neighbour_nodes << node
		send_message ["RESOURCE_TABLE", @resource_table], 0, node.host, node.port
	end

	def send_neighbour(host, port)
		host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address if host == "localhost"
		node = NodeInfo.new(host, port)
		@neighbour_nodes << node
		send_message ["NEW_NODE", @info], 0, host, port	
	end

	def send_new_resource(key)
		@neighbour_nodes.each do |node|
			send_message ["ADD_RESOURCE", node.host, node.port]
		end
	end
	#Puts the new resource into the resource_table and resolves_queue sending to all pending requests
	def put(key, value)
		unless @resource_table.has_key?(key)
			@resource_table[key] = [value, @info] 
			new_resource = { key => [value, @info] }

			@neighbour_nodes.each do |n|
				send_message ["ADD_RESOURCE", new_resource], 0, n.host, n.port
			end

			puts "#{resource_table}"
			resolve_queue(key)
		end
	end

	#Returns to client if the resource exists, otherwise is added to the request queue
	def get(key, host, port)
		if resource_table.has_key?(key)
			s = UDPSocket.new
			puts "Returning resource #{key} to #{host}:#{port}"
			serialized = Marshal.dump(["PUT", key, @resource_table[key]])
			s.send serialized, 0, host, port
			s.close
		else
			@request_queue.push Request.new(key, host, port)
		end
	end

	#Reloves all pending requests made by clients and sends response, doesn't care if client still exists
	def resolve_queue(key)
		waiting = request_queue.select { |req| req.key == key }
		waiting.each do |w|
			send_message ["PUT", key, resource_table[key]], 0, w.host, w.port
			request_queue - [w]
		end
	end

	def send_message(data, flag, host, port)
		socket = UDPSocket.new
		serialized = Marshal.dump(data)
		socket.send serialized, flag, host, port
		socket.close
		puts "Sending #{data} to #{host}:#{port}"
		sleep(0.025)
	end
end


#Initializes the nodes with given cmd line arguments 
port, neighbour_ip, neighbour_port = ARGV 

node = Node.new(port, neighbour_ip, neighbour_port)