require 'socket'
require 'stringio'
require 'timeout'

class Node
	Request = Struct.new(:key, :host, :port)
	NodeInfo = Struct.new(:host, :port)

	attr_accessor :info, :socket, :neighbour_nodes, :request_queue, :resource_table, :waiting
	def initialize(port, neighbour_ip = nil, neighbour_port = nil)
		@socket = UDPSocket.new
		host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
		@info = NodeInfo.new(host, port)
		puts "#{info}"
		@neighbour_nodes = [] 
		@request_queue = []
		@resource_table = {}
		t = Thread.new{start_listening}
		#pinger = Thread.new{ping_nodes}
		send_neighbour(neighbour_ip, neighbour_port) unless neighbour_ip.nil?

		t.join
	end

	# Main listening method, takes any package received 
	# and starts a new thread computing depending on message type
	def start_listening
		@socket = UDPSocket.new
		@socket.connect(@info.host, @info.port)
		while true
			text, sender = @socket.recvfrom(1024)

				arguments = Marshal.load(text)
				msg_type = arguments.shift
				
				puts "Received msg: #{msg_type}, #{arguments} from remote #{sender}"

				if msg_type == "GET"
					key, host, port = arguments
					get(key.to_i, sender[3], @info.port)
				elsif msg_type == "PUT"
					key, value = arguments
					put(key.to_i, value)
				elsif msg_type == "PING"
					node = arguments.first
					send_message ["OK"], 0, node.host, node.port
				elsif msg_type == "OK"
					@waiting = false
				elsif msg_type == "NEW_NODE"
					new_node_info = arguments.first
					new_network_node(new_node_info)
				elsif msg_type == "ADD_NODE"
					info = arguments.first
					@neighbour_nodes << info
				elsif msg_type == "DROP_NODE"
					info = arguments
					to_delete = @neighbour_nodes.select { |n| n.host == info.host and n.port == info.port}
					@neighbour_nodes - to_delete
				elsif msg_type == "RESOURCE_TABLE"
					@resource_table = arguments.first
				elsif msg_type == "ADD_RESOURCE"
					resource = arguments.first
					@resource_table.merge!(resource)
					puts "#{resource.to_a}"
					puts "#{request_queue}"
					resolve_queue(resource.to_a[0][0])
				end 
		end
	end
	def waiting?
		@waiting
	end

	#Initial version odf heartbeat *(not functional or part of final solution)
	def ping_nodes
		while true
			sleep(rand(60))
			n = rand(@neighbour_nodes.count)
			node = @neighbour_nodes[n]
			s = UDPSocket.new
			begin
				Timeout::timeout(10){ 
					puts "Pinging #{node}"
					send_message ["PING", @info], 0, node.host, node.port
					@waiting = true
					while waiting?
						sleep(0.2)
					end
				}
			rescue Timeout::Error => ex
				if waiting?
					puts "Conenction to #{node} timed out, sending DROP_NODE to all remaining nodes"
					@neighbour_nodes - [node]
					@neighbour_nodes.each do |n|
						send_message ["DROP_NODE", node], 0, n.host, n.port
					end
				end
			rescue Socket::Error => ex
				puts "Connection to #{node} failed, trying again in 60 seconds"
			rescue => ex
				puts ex.message
			end
		end
	end
	
	def new_network_node(new_node)
		sleep(0.25)
		node = NodeInfo.new(new_node.host, new_node.port)

		@neighbour_nodes.each do |n|
			send_message ["ADD_NODE", node], 0, n.host, n.port
			send_message ["ADD_NODE", n], 0, node.host, node.port
		end
		
		@neighbour_nodes << node
		send_message ["RESOURCE_TABLE", @resource_table], 0, node.host, node.port
	end

	#Sends notification to initially provided ip/port
	def send_neighbour(host, port)
		host = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address if host == "localhost"
		node = NodeInfo.new(host, port)
		@neighbour_nodes << node
		send_message ["NEW_NODE", @info], 0, host, port	
	end

	#Sends any new resource to all nodes in the system
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
			puts "Returning resource #{key} to #{host}:#{port}"
			data = ["PUT", key, @resource_table[key][0]]
			send_message Marshal.dump(data), 0, host, port
		else
			puts "Get Queued"
			@request_queue.push Request.new(key, host, port)
		end
	end

	#Reloves all pending requests made by clients and sends response, doesn't care if client still exists
	def resolve_queue(key)
		waiting = request_queue.select { |req| req.key == key.to_i }
		waiting.each do |w|
			puts "resolving queue #{request_queue}"
			send_message ["PUT", key, resource_table[key][0]], 0, w.host, w.port
			request_queue - [w]
		end
	end
	#Main send message methods, serializes a 
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