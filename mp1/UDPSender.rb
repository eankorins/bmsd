require 'socket'

sender = UDPSocket.new
10.times do |i|
	# message = (1..1000).to_a.map!(&:to_s).join(', ')
	# puts message
	sender.send(i.to_s, 0, 'localhost', 1234)
end