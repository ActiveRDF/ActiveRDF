require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
#require 'adapter/redland'
require 'adapter/sparql'
# require 'active_rdf/test/common'

class TestResourceInstanceMethods < Test::Unit::TestCase
	def setup
		ConnectionPool.instance.add_data_source(:type => :sparql, :path => 'repositories/', :context => 'test-people')
		Namespace.register(:ar, 'http://activerdf.org/test/')
		@eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
	end
	
	def teardown
	end
	
	def test_find_all_instances
    assert_equal 36, RDFS::Resource.find_all.size
	  assert_equal @eyal, AR::Person.find_all
	end
	
	def test_class_predicates
	  assert_equal 10, RDFS::Resource.predicates.size
	end
	
	def test_eyal_predicates
		predicates = @eyal.predicates

		# assert that the three found predicates are (in short form) eye, age, and type
		assert_equal 10, predicates.size
		predicates_labels = predicates.collect {|pred| pred.label }
		
		assert ['age', 'eye', 'type', 'car'].all? { |pr| predicates_labels.include?(pr) }
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
		assert_not_nil found_eyal
		assert_equal @eyal, found_eyal
		assert_equal 'blue', RDFS::Resource.find_by_age(27).eye		
		assert_equal @eyal, RDFS::Resource.find_by_age_and_eye(27,'blue')
	end
	
end
