require 'socket'

listener = UDPSocket.new
listener.bind('172.16.28.176', 2345)

while true
	text, sender = listener.recvfrom(1024)
	puts text
end