#!/usr/bin/env ruby

#Avery VanKirk August 2017
#Ruby Pig implementation. 
#2 connects. Heads listen, Tails connects.
require 'socket'

class Pig
	#attr_accessor :lip
	#attr_accessor :port

	def initialize(lip = 'localhost', lport = 36751, rip = 'localhost', rport = 36752)
		@lip = lip
		@lport = lport
		@rip = rip
		@rport = rport
		@head = false
		@tail = false
		@users = 0
	end

	def listen(lip = @lip,lport = @lport)
		begin
			server = TCPServer.new(lip,lport)
			Thread.start do
				head = server.accept
				server.close
				@head = head
				num = @users
				@users = @users + 1
				head.puts "[Server] Connected as head"
				while line = head.gets
					puts "head: #{line}"
					if @tail
						@tail.puts line
					end
				end
			end
		rescue => e
			puts "Exception: #{@lip}:#{@lport} - #{ e.message }"
		end
	end

	def connect(rip = @rip, rport = @rport)
		begin
			Thread.start(TCPSocket.new(rip,rport)) do |tail|
				@tail = tail
				tail.puts "[Server] Connected as tail"
				while line = tail.gets
					puts "tail: #{line}"
					if @head
						@head.puts line
					end
				end
				tail.close
			end
		rescue => e
			puts "Exception: #{@rip}:#{@rport} - #{ e.message }"

		end	
	end

	def about
		puts "Head: #{@lip}:#{@lport} - connected: #{@head}"
		puts "Tail: #{@rip}:#{@rport} - connected: #{@tail}"
	end
end

if __FILE__ == $0
	p = Pig.new()
	p.listen
	p.connect
	#p.about

	while true
		print ">"
		input = gets.split(" ")
		puts "input was #{input}"
		if input[0] == "connect" and input.length == 3
			p.connect(input[1],input[2])
		elsif input[0] == "listen" and input.length == 3
			p.listen(input[1],input[2])		
		end		
	end
end


