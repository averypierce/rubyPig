#!/usr/bin/env ruby

#Swap first with last, first+1 with last-1, etc

def reverse(string)
	len = string.length - 1
	middle = (len / 2).to_i

	for i in 0..middle
		temp = string[i]
		string[i] = string[len - i]
		string[len - i] = temp
	end
	return string
end

puts reverse("Hello World!")


