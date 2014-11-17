require 'socket'

class Subscriber
	attr_reader :ip, :port
	attr_accessor :server, :client

	def initialize(port)
		@port = port
		@server = TCPServer.new port
	end

	def start
		begin
			Thread.start(@server.accept) do |client|
				@client = client
				break;
			end
		end
	end
end

class Publisher
	attr_reader :ip, :port
	attr_accessor :socket

	def initialize(ip, port)
		@ip = ip
		@port = port
		@socket = TCPSocket.new @ip, port
	end

	def start(subscribers)
		while line = @socket.gets
			subscribers.each do |sub|
				sub.socket.puts line
			end
		end
	end
end

class Server
	attr_accessor :publishers, :subscribers

	def add_publisher

	end

	def add_subscriber

	end

end