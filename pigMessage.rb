
require 'json'


module Pjson

	def asJson(type = @type,payload = @payload,from = 'pig',to = 'all')
		hash = {"from" => from,"to" => to,"type" => type,"payload" => payload}
		return JSON.generate(hash)
	end

	def fromJson(message)
		begin
			puts "fromJason() recieved #{message}"
			data = JSON.parse(message)
			@from = data["from"]
			@to = data["to"]
			@type = data["type"]
			@payload = data["payload"]
			return true
		rescue => e
			puts "Exception: #{ e.message }"
			puts "Not a valid JSON message"
			return false
		end
	end
end

#module Pxml
class PigMessage

	include Pjson
	attr_accessor :type
	attr_accessor :from
	attr_accessor :to
	attr_accessor :payload

	def initialize
		@from = nil
		@to = nil
		@type = "normal"
		@payload = nil
	end

	def load(message)
		if not fromJson(eval("'"+message+"'"))
			puts "loading message as raw"
			@payload = message.to_s
		end
	end

	def display
		puts "from: #{@from}"
		puts "to: #{@to}"
		puts "type: #{@type}"
		puts "payload: #{@payload}"
	end
end

class TextMessage < PigMessage

	def initialize(text,from = 'pig',to = 'all')
		@from = from
		@to = to
		@type = 'text'
		@payload = text
	end
end
