require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
#require 'adapter/redland_adapter'
require 'adapter/sparql_adapter'
# require 'active_rdf/test/common'

class TestResourceInstanceMethods < Test::Unit::TestCase
	def setup
		ConnectionPool.instance.add_data_source(:type => :sparql, :context => 'persons')
		Namespace.register(:ar, 'http://activerdf.org/test/')
		@eyal = RDFS::Resource.lookup 'http://activerdf.org/test/eyal'
	end
	
	def teardown
	end
	
	def test_eyal_predicates
		predicates = @eyal.predicates

		# assert that the three found predicates are (in short form) eye, age, and type
		assert_equal 4, predicates.size
		predicates_labels = predicates.collect {|pred| pred.label }
		assert_equal ['age', 'eye', 'type', 'car'].sort, predicates_labels.sort
	end
	
	def test_eyal_types
		type_labels = @eyal.types.collect {|pred| pred.label}
		assert_equal ['Person','Resource'], type_labels
	end
	
	def test_eyal_age
		# triple exists '<eyal> age 27'
		assert_equal '27', @eyal.age

		# Person has property car, but eyal has no value for it
		assert_equal nil, @eyal.car

		# non-existent method should throw error
		assert_raise(NoMethodError) { @eyal.non_existing_method }
	end
	
	def test_eyal_type
		assert_instance_of RDFS::Resource, @eyal
		assert_instance_of AR::Person, @eyal
	end
	
	def test_find_methods
		found_eyal = RDFS::Resource.find_by_eye('blue')
		assert_equal @eyal, found_eyal
		assert_equal @eyal.object_id, found_eyal.object_id		
		assert_equal 'blue', RDFS::Resource.find_by_age(27).eye		
		assert_equal @eyal, RDFS::Resource.find_by_age_and_eye(27,'blue')
	end
	
end
