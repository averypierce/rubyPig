#!/usr/bin/env ruby

#Avery VanKirk August 2017
#Ruby Pig implementation.

#Heads listem, tails connect
#Heads are on the left, Tails are on the right. 
require 'socket'

Default = 36751

class Pig

	def initialize(lip = 'localhost', lport = Default, rip = 'localhost', rport = 36752)
		@lip = lip
		@lport = lport
		@rip = rip
		@rport = rport
		@users = 0		
		@head = false
		@tail = false
	end

	def headup(lip = @lip,lport = @lport)
		if @head
			puts "Head is already up"	
		else	
			Thread.start do
				@head = PigSocket.new.listen(lip,lport)
				while line = @head.gets
					puts "head: #{line}"
					begin
						@tail.puts line
					rescue Exception => e
						puts "warning: tail not connected."
					end
				end
			end
		end
	end

	def tailup(rip = @rip,rport = @rport)
		if @tail
			puts "Tail is already up"
		else
			Thread.start do
				@tail = PigSocket.new.connect(rip,rport)
				while line = @tail.gets
					puts "tail: #{line}"
					begin
						@head.puts line
					rescue Exception => e
						puts "warning: head not connected"
					end					
				end
			end
		end
	end
end

#Sets up a socket to listen/connect and returns it
class PigSocket

	def initialize(ip = 'localhost',port = Default)
		@ip = ip
		@port = port
		@conn = nil
	end

	#Assigns @conn to a listen socket, and returns the socket for optional direct use
	def listen(ip = @ip,port = @port)
		begin
			server = TCPServer.new(ip,port)
			@conn = server.accept
			server.close
			@conn.puts "[Server] Connected as head"
			return @conn
		rescue => e
			puts "Exception: #{@ip}:#{@port} - #{ e.message }"
		end
	end

	#Assigns @conn to an active socket, and returns the socket for optional direct use
	def connect(ip = @ip, port = @port)
		begin
			@conn = TCPSocket.new(ip,port)
			@conn.puts "[Server] Connected as tail"
			return @conn
		rescue => e
			puts "Exception: #{@ip}:#{@port} - #{ e.message }"
		end	
	end

	#For sending with pig object instead of returned socket
	#Will be used for message filtering/processing
	def send(message)
		@conn.puts message
	end
end



if __FILE__ == $0
	p = Pig.new()
	p.tailup	
	p.headup

	while true
		sleep(5)	
	end
end


