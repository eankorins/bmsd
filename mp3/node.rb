require 'socket'


class Node
	Request = Struct.new(:key, :host, :port)
	
	attr_accessor :port, :socket, :neighbour_socket, :request_queue, :resource_table, :regex

	def initialize(port, neighbour_ip = nil, neighbour_port = nil)
		@port = port
		@neighbour_socket = UDPSocket.new(neighbour_ip, neighbour_port) unless neighbour_ip.nil?
		@socket = UDPSocket.new
		@request_queue = []
		@resource_table = {}
		@regex = /(GET|PUT)\((.*)\)/
		start_listening
	end

	def start_listening
		@socket.bind(nil, @port)
		while true
			text, sender = @socket.recvfrom(1024)
			remote_host = sender[3]

			msg_type, arguments = text.scan(@regex).first

			if msg_type == "GET"
				key, host, port = arguments.split(', ')
				get(key.to_i, host, port)
			elsif msg_type == "PUT"
				key, value = arguments.split(', ')
				put(key.to_i, value)
			end
			puts "#{resource_table}"
			puts "Received msg: #{msg_type} from remote #{remote_host}"
		end
	end

	#Reloves all pending requests made by clients and sends response, doesn't care if client still exists
	def resolve_queue(key)
		waiting = request_queue.select { |req| req.key == key }
		waiting.each do |w|
			s = UDPSocket.new
			s.send "PUT(#{key}, #{resource_table[key]})", 0, w.host, w.port
			s.close
			request_queue - [w]
		end
	end

	#Puts the new resource into the resource_table and resolves_queue sending to all pending requests
	def put(key, value)
		@resource_table[key] = value unless @resource_table.has_key?(key)
		puts "Putting #{key}"
		resolve_queue(key)
	end

	#Returns to client if the resource exists, otherwise is added to the request queue
	def get(key, host, port)
		if resource_table.has_key?(key)
			s = UDPSocket.new
			puts "Returning resource #{key} to #{host}:#{port}"
			s.send "PUT(#{key}, #{resource_table[key]})", 0, host, port
			s.close
		else
			@request_queue.push Request.new(key, host, port)
		end
	end
end

port, neighbour_ip, neighbour_port = ARGV 

Node.new(port, neighbour_ip, neighbour_port)