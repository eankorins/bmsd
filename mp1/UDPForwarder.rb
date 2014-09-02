require 'socket'
require_relative 'QuestionableUDPSocket'

def init(h, p1, p2)
	listener = UDPSocket.new
	forwarder = QuestionableUDPSocket.new
	listener.bind("127.0.0.1", p1)
	while true
		text, sender = listener.recvfrom(1024)
		forwarder.send(text, 0, h, p2)
	end
end
h, p1, p2 = ARGV[0], ARGV[1], ARGV[2]
init(h,p1,p2)