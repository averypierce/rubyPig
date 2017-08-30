#!/usr/bin/env ruby

#Avery VanKirk August 2017
#Ruby Pig implementation.

#Heads listem, tails connect
#Heads are on the left, Tails are on the right. 
require 'socket'
require_relative 'pigMessage'
require 'tracer'
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

		lnabs = []
		rnabs = []

		@reads = []
		@dispatcher = PigDispatcher.new
	end

	def main
		while true
			ready = IO.select(@reads)
			readable = ready[0]
			readable.each do |socket|
				
				if socket.instance_of? P
					if socket.lissen
						puts "listen socket detected..."
						@reads.push(socket.accept_nonblock) #by not deleteing listener we are still accepting connections on this thigny
					end
				else
					buf = socket.gets
					if socket == @head
						src = "head"
						puts buf
						@dispatcher.forward(@head,@tail,buf)
					elsif socket == @tail
						src = "tail".
						#@dispatcher.forward(@tail,@head,buf)
					elsif socket == @stdin
						src = "keyboard"
						@dispatcher.forward(@head,@tail,TextMessage.new(buf))
						break
					end
					
					if buf
						print "recv from ",src,": "
						puts buf
						recv = PigMessage.new.fromJson(buf)
						recv.display
					end
				end
	        end
	    end
	end

	def headUp(lip = @lip,lport = @lport)
		if @head
			puts "Head is already up"	
		else
			begin
				@head = PigSocket.new.listen(lip,lport)
				@reads.push(@head.conn)
			rescue => e
				puts "Exception: #{ e.message }"
			end		
		end
	end

	def tailUp(rip = @rip,rport = @rport)
		if @tail
			puts "Tail is already up"	
		else
			begin
				@tail = PigSocket.new.connect(rip,rport)
				@reads.push(@tail.conn)
			rescue => e
				puts "Exception: #{ e.message }"
			end	
		end
	end

	def keyboardUp
		begin
			@stdin = IO.for_fd(STDIN.fileno)
			@reads.push(@stdin)
		rescue => e
			puts "Exception: #{ e.message }"
		end	
	end
end

class PigDispatcher

	def initialize(echo = false,forward = true)
		@echo = echo
		@forward = forward
		@filters = []
	end

	def forward(sourceSocket,destSocket,message)

		#apply filters
		if forward
			destSocket.puts(message.asJson)
		end
		if echo
			sourceSocket.puts(message.asJson)
		end
	end
end



class P < TCPServer

	attr_accessor :lissen
	def initialize(ip,port)
		super
		@lissen = true
	end
end

####!!! lets get rid of this... !!!####
#Socket Wrapper
#Sets up a socket to listen/connect and returns it
class PigSocket

	attr_accessor :conn

	def initialize(ip = 'localhost',port = Default)
		@ip = ip
		@port = port		
		@conn = nil
	end

	def fileno
		return @conn.fileno
	end

	#Assigns @conn to a listen socket, and returns the socket for optional direct use
	def listen(ip = @ip,port = @port)
		begin
			listenSocket = P.new(ip,port)
			puts listenSocket.lissen
			#We could put in a pigmessage WHOAMI thing here
			#@conn.puts "HTTP/1.1 200 OK\r\nServer: WebServer\r\nContent-Type: text/html\r\nContent-Length: 3\r\nConnection: close\r\n\r\n123"
			#@conn = listenSocket.accept
			#listenSocket.close
			@conn = listenSocket
			#@conn.puts "[Server] Connected as head"
			#return listenSocket
			#puts @conn.fileno
			return self
		rescue => e
			puts "Exception: #{@ip}:#{@port} - #{ e.message }"
		end
	end

	def accept(listenSocket)
		@conn = listenSocket.accept
		listenSocket.close
		@conn.puts "[Server] Connected as head"
		return @conn
	end

	#Assigns @conn to an active socket, and returns the socket for optional direct use
	def connect(ip = @ip, port = @port)
		begin
			@conn = TCPSocket.new(ip,port)
			@conn.puts "[Server] Connected as tail"
			return self
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
	#p.tailup	
	p.headUp
	p.keyboardUp
	p.main

	while true
		sleep(5)	
	end
end


