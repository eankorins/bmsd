require 'socket'
require 'timeout'

require_relative 'counter'
size, n, interval = ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_f
#Connection to echo server

#host, port = ['10.25.251.194', 7007]
#host, port = ['192.168.2.116', 7]
host, port = ['106.185.40.123', 7]
puts "Size: #{size} Number: #{n} interval: #{interval}"

sent = Counter.new
s2 = UDPSocket.new
#establish socket connection with host
response = s2.connect(host, port)

# Send padded packets n times with an interval
t1 = Thread.new { 
	n.times do |i|
		sent.increment!
		message = i.to_s.ljust(size-8)
		s2.send(message, 0, host, port)
		sleep(interval)
	end
}

#Listen and receive packets

t2 = Thread.new {
	#Prepare variables
	received = []
	packet_count = (0..n).inject({}) { |hash, e| hash[e] = 0; hash }
	percentage_received = 0

	#Loop forever or untill no packets have been received for 2 seconds (might need increase if desired interval is higher)
	while true
		begin 
			timeout(2) do
				r = s2.recvfrom(1024)
				received << r
				percentage_received = 100 -((received.count.to_f / sent.total.to_f) * 100)
				print "Sent: #{sent.total} Received: #{received.count}  (#{percentage_received.round(2)}\%)\r"
			end
		rescue Timeout::Error
			break
		end
	end

	received.each { |text, sockaddr| packet_count[text.to_i] += 1 }
	puts packet_count
	duplicates = packet_count.select { |k,v| v > 1 }.count
	print "Sent: #{sent.total} Received: #{received.count}  (#{percentage_received.round(2)}\%) Duplicates: #{duplicates}\r"
}
t1.join
t2.join

