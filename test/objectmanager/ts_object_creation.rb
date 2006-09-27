require 'test/unit'
require 'active_rdf'
# require 'active_rdf/test/common'

class TestObjectCreation < Test::Unit::TestCase
	def setup
	end
	
	def teardown
	end
	
	def test_unique_same_object_creation
		assert_raise(NoMethodError) { RDFS::Resource.new('abc') }
		assert_nothing_raised { RDFS::Resource.lookup('abc') }
		
		r1 = RDFS::Resource.lookup('abc')
		r2 = RDFS::Resource.lookup('cde')
		r3 = RDFS::Resource.lookup('cde')
		
		assert_equal 'abc', r1.uri
		assert_equal 'cde', r2.uri
		assert_equal r3.object_id, r2.object_id
		
		assert_instance_of RDFS::Resource, r1
		assert_instance_of RDFS::Resource, r2
	end
end