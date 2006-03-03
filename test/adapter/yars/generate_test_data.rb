#!/usr/bin/ruby
file = File.open 'test_data.nt', 'w'
100.times do |i|
	file << "<http://eyaloren.org#me#{i}> <test:time> \"#{i}\" .\n"
	
end
