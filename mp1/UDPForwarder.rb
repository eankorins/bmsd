require 'socket'
require_relative 'QuestionableUDPSocket'


def init(h, p1, p2)
	listener = UDPSocket.new
	forwarder = UDPSocket.new
	#Binds the listener (Acts like server)
	listener.bind("localhost", p1)
	#Listens forever, receives 1024 byte messages, and sends them to the entered host
	while true
		text, sender = listener.recvfrom(1024)
		puts text
		forwarder.send(text, 0, h, p2)
	end
end
#Takes the 3 arguements passed, any additional arguements will be discarded
h, p1, p2 = ARGV
init(h,p1,p2)