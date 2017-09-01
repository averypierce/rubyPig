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

	def initialize(lip = 'localhost', lport = 36751, rip = 'localhost', rport = 36752)
		$lip = lip
		$lport = lport
		$rip = rip
		$rport = rport
		@users = 0		
		@head = false
		@tail = false

		@shash = {"head" => @head,"tail" => @tail}

		@selfIP = Socket.ip_address_list[0].ip_address


		@allowMultipleConnections = false

		lnabs = []
		$rnabs = []

		@reads = []
		@dispatcher = PigDispatcher.new
		@dispatcher.addFilter(TopologyFilter.new)
		#@dispatcher.addFilter(ReverseFilter.new)
	end

	def main
		#self.headUp
		while true
			ready = IO.select(@reads)
			readable = ready[0]
			readable.each do |socket|
				src = ""
				#if socket is listening listening				
				if socket.instance_of? TCPServer #getsockopt(SOL_SOCKET,SO_ACCEPTCONN) is not working on linux subsystem
					
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
						destSocket = @tail
					end
					if socket == @tail
						src == "tail"
						destSocket = @head
					end

					if buf == nil
						
						if socket == @head
							@head = false
							puts "[#{src} has disconnected]"
							puts "Reopening listener socket for network healing"
							self.headUp(@selfIP,$lport)
						end
						if socket == @tail
							@tail = false
							puts "[#{src} has disconnected]"
							puts "PigNode lost. Attempting to reconnect."
							$rnabs.each do |pigHeal|
								self.tailUp(pigHeal[0],pigHeal[1].to_i)
								if @tail
									break
								end
							end
						end
						@reads.delete(socket)
						socket.close					

					end
					
					if buf
						if socket == @stdin
							if buf[0] == "i"
								@dispatcher.forward(@head,@tail,TextMessage.new(buf[2..-1]))
							else
								keyboardCommands(buf)
							end
						else
							m = PigMessage.new
							m.load(buf)
							m.from = src
							@dispatcher.forward(socket,destSocket,m)
						end
					end
				end
	        end
	    end
	end

	def sendTopo
		hash = {"from" => "pig","to" => "all","type" => "topo","payload" => [["END","END"]]}
		b = JSON.generate(hash)
		#puts b
		if not @tail
			@head.puts(b)
		else
			puts "Only leftmost pig can initiate topology message"
		end
	end

	def keyboardCommands(command)
		command = command.split
		if command[0] == "listen"
			self.headUp(command[1],command[2])
		end
		if command[0] == "connect"
			self.tailUp(command[1],command[2])
		end
		if command[0] == "sendtopo"
			self.sendTopo
		end 
	end

	def headUp(lip = $lip,lport = $lport)
		if @head
			puts "Head is already up"	
		else
			begin
				listenSocket = TCPServer.new(lip,lport)
				@reads.push(listenSocket)
				$lip = lip
				$lport = lport
			rescue => e
				puts "Exception: #{ e.message } port: #{lport} IP: #{lip}"
			end		
		end
	end

	def tailUp(rip = @rip,rport = $rport)
		if @tail
			puts "Tail is already up"	
		else
			begin
				@tail = TCPSocket.new(rip,rport)
				if @tail
					@reads.push(@tail)
				end
				$rport = rport
				puts "Connection established"
			rescue => e
				puts "Exception: #{ e.message } port: #{rport} IP: #{rip}"
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
	def filter(pigMessage)
		#do whatever
		return pigMessage
	end
end

class ReverseFilter
	def filter(pigMessage)
		pigMessage.payload = pigMessage.payload.reverse 
		return pigMessage
	end
end

#sending your own data vs data from who you are connected to?
class TopologyFilter < Filter
	def filter(pigMessage)
		if pigMessage.type == "topo"
			puts "processing Topology message"
			if pigMessage.from == "left"
				port = $rport
			elsif pigMessage.from == "right"
				port = $lport
			end
			$rnabs = pigMessage.payload
			pigMessage.payload.unshift([Socket.ip_address_list[0].ip_address,$lport])
			pigMessage.display
		end
		return pigMessage
	end
end

class PigDispatcher

	def initialize(echo = false,forward = true)
		@echo = echo
		@forward = forward
		@filters = []
	end

	def addFilter(filter)
		@filters.push(filter)
	end

	def forward(sourceSocket,destSocket,message)
		message.display
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
	#p.tailUp	
	#p.headUp
	p.keyboardUp
	p.main

	while true
		sleep(5)	
	end
end


