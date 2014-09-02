require 'socket'

class QuestionableUDPSocket < UDPSocket
	alias_method :questionable_send, :send

	sent_packets = []

	def reorder(mesg, flags, host, port)

	end

	def duplicate(mesg, flags, host, port)
		2.times { questionable_send(mesg << "duped", flags, host, port) }
	end

	def discard
	end

	def send(mesg, flags, host, port)
		
		rand = rand(0..100)
		
		case rand
		when 0..70
			super(mesg, flags, host, port)
		when 71..80
			duplicate(mesg, flags, host, port)
		when 81..90
			reorder(mesg, flags, host, port)
		when 91..100
			discard
		end
	end


end