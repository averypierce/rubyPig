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

		@allowMultipleConnections = false

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
				
				if socket.instance_of? TCPServer #getsockopt(SOL_SOCKET,SO_ACCEPTCONN) is not working on linux subsystem
					#if socket.listening
					puts "Accepting connection"
					#@reads.push(socket.accept) #by not deleteing listener we are still accepting connections on this thigny
					@head = socket.accept
					@reads.push(@head)
					if not @allowMultipleConnections
						@reads.delete(socket)
						socket.close
					end
				else
					buf = socket.gets

					if socket == @head
						src = "head"
						puts buf
						@dispatcher.forward(socket,@tail,TextMessage.new(buf))
					elsif socket == @tail
						src = "tail"
						puts buf
						@dispatcher.forward(socket,@head,TextMessage.new(buf))
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
				listenSocket = TCPServer.new(lip,lport)
				@reads.push(listenSocket)
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
				@tail = TCPSocket.new(rip,rport)
				if @tail
					@reads.push(@tail)
				end
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

#Interface for how a filter should work
class Filter
	def filter(message)
		#do whatever
		return message
	end
end

#
class PigDispatcher

	def initialize(echo = false,forward = true)
		@echo = echo
		@forward = forward
		@filters = []
	end

	def addFilter(filter)
		filters.push(filter)
	end

	def forward(sourceSocket,destSocket,message)

		@filters.each do |filter|
			message = filter.filter(message)
		end

		if destSocket and @forward
			destSocket.puts(message.asJson)
		end
		if sourceSocket and @echo
			sourceSocket.puts(message.asJson)
		end
	end
end



if __FILE__ == $0
	p = Pig.new()
	p.tailUp	
	p.headUp
	p.keyboardUp
	p.main

	while true
		sleep(5)	
	end
end


