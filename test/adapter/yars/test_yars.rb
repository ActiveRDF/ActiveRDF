require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/person'

# TODO!!! BLANK NODE

class TestYars < Test::Unit::TestCase

	def setup	 
		$logger.level = Logger::DEBUG
		@yars = Resource.establish_connection({ :adapter => :yars, :host => 'opteron', :port => 8080, :context => '/citeseer' })
		@eyal = Resource.create 'http://eyaloren.org#me'
		@eyal.save
	end

	def test_find_all
		$logger.info 'FIND ALL TEST'
		result = @yars.find_all
		$logger.info "found #{result.size} triples" unless result.nil?
	end

	def test_find_b
		home = Resource.create('http://purl.org/net/dajobe/')
		dajobe = Person.find_by_homepage(home)
		p 'homepage: ' + dajobe.homepage
		assert_instance_of Person, dajobe
		assert_equal dajobe.homepage, home
	end

#	def test_remove
#		$logger.info 'REMOVE TEST'
#		assert @yars.remove @eyal, nil, nil
#	end
	
	def test_find
		$logger.info 'FIND SUBJECT TEST'
		result = @yars.find @eyal,nil,nil
		$logger.info "found #{result.size} subjects"
		assert_not_nil result
		result.each do |s,p,o|
			assert_same s, @eyal
			assert_not_nil p
			assert_not_nil o
			assert_instance_of Resource, p
			assert (o.instance_of? Literal or o.instance_of? Resource)
		end
	end
 
	def test_put
		$logger.info 'PUT TEST'
		p = Resource.create 'test:set'
		t = Time.now.to_s
		assert_nothing_raised() {@yars.add @eyal, p, t }
	end
end
