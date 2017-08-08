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

	def listen

		server = TCPServer.new(@lip,@lport)
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
	end

	def connect

		Thread.start(TCPSocket.new(@rip,@rport)) do |tail|
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
	end

	def about
		puts @lip
		puts @port
		puts "connected: #{@head}" 
	end
end

if __FILE__ == $0
	p = Pig.new()
	p.listen
	p.connect
	#loop to keep threads alive 
	puts "Ay"
	while true
		sleep(0.1)
	end
end