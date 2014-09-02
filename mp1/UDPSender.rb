require 'socket'

sender = UDPSocket.new
10.times do
	sender.send("Hello", 0, 'localhost', 1234)
end