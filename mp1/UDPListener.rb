require 'socket'


listener = UDPSocket.new
listener.bind('106.185.40.123', 7)

while true
	text, sender = listener.recvfrom(1024)
	puts text
	puts sender
end