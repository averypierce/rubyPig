
require 'json'


module Pjson

	def asJson(type = @type,body = @payload,from = 'pig',to = 'all')
		hash = {"from" => from,"to" => to,"type" => type,"body" => body}
		return JSON.generate(hash)
	end

	def fromJson(message)
		begin
			data = JSON.parse(message)
			@from = data["from"]
			@to = data["to"]
			@type = data["type"]
			@payload = data["body"]
		rescue
			puts "Not a valid JSON message"
		end
	end
end

#module Pxml


class PigMessage

	include Pjson
	attr_accessor :type
	attr_accessor :to

	def initialize
		@from = nil
		@to = nil
		@type = nil
		@payload = nil
	end

	def display
		puts @payload
	end
end

#A plain-text message 
class TextMessage < PigMessage

	def initialize(text,from = 'pig',to = 'all')
		@from = from
		@to = to
		@type = 'text'
		@payload = text
	end
end

#This is a message pertaining to topology of the piggy network
class TopoMessage < PigMessage

	def initialize(text,from = 'pig',to = 'all')
		@from = from
		@to = to
		@type = 'text'
		@payload = text
	end
end

