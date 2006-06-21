# = test_resource.rb
#
# Unit Test of Resource Class method
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved

require 'test/unit'
require 'active_rdf'
require 'node_factory'
require 'active_rdf/test/common'

class Person < IdentifiedResource
  setup_any
  set_class_uri 'http://test/Person'
end

class Resource
	def self.test_find_predicates(class_uri)
		return Resource.find_predicates(class_uri)
	end
end

class TestResource < Test::Unit::TestCase
	def setup
	   setup_any
	end
	
	def teardown
		 delete_any
	end
	
	def test_class_uri
		class_uri = Resource.class_URI
		assert_not_nil(class_uri)
		assert_kind_of(IdentifiedResource, class_uri)
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource', class_uri.uri)
	end
	
	def test_find_predicates
		assert_raise(ActiveRdfError) { Resource.test_find_predicates(nil)	}
    assert_raise(ActiveRdfError) { Resource.test_find_predicates(String.new) }   
 	end
  
  def test_find_predicates2
    # runs only on redland
    return unless $adapters.include?(:redland)
    
    # loading test dataset into model
    parser = Redland::Parser.new
    model = NodeFactory.connection.model
    dataset = File.read "#{File.dirname(__FILE__)}/../../test_set_person.rdf"
    parser.parse_string_into_model(model,dataset,'uri://test-set-activerdf/')
    
    # verifying predicates are correctly loaded
		class_uri = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/Person')
		predicates = Resource.test_find_predicates(class_uri)
		assert_not_nil(predicates)
		assert_instance_of(Hash, predicates)
		assert_equal(3, predicates.size)
	
  	predicates.each { |attribute, uri|
			case attribute
			when 'age'
				assert_equal('http://m3pe.org/activerdf/test/age', uri)
			when 'knows'
				assert_equal('http://m3pe.org/activerdf/test/knows', uri)
			when 'name'
				assert_equal('http://m3pe.org/activerdf/test/name', uri)
			end
		}		
	end
	
	def test_instantiate_resource
		assert_raise(NoMethodError) { resource = Resource.new	}
	end
	
	def test_exists
		resource = IdentifiedResource.create('http://m3pe.org/activerdf/test/exist')
		assert(!Resource.exists?(resource))
		resource.save
		assert(Resource.exists?(resource))		
	
		resource = IdentifiedResource.create('http://m3pe.org/activerdf/test/exist2')
		assert(!Resource.exists?('http://m3pe.org/activerdf/test/exist2'))
		resource.save
		assert(Resource.exists?('http://m3pe.org/activerdf/test/exist2'))
  end
  
  def test_add_predicate_identified_resource
		test_predicate = IdentifiedResource.create 'http://test/test'
		assert_nothing_raised { Person.add_predicate test_predicate }

		assert Person.predicates.include?('test')
		assert_kind_of IdentifiedResource, Person.predicates['test'] 
		assert_equal 'http://test/test', Person.predicates['test'].uri
	end
	
	def test_add_predicate_to_lowerclass
		assert_nothing_raised { Person.add_predicate 'http://test/test' }

		assert Person.predicates.include?('test')
		assert_kind_of IdentifiedResource, Person.predicates['test'] 
		assert_equal 'http://test/test', Person.predicates['test'].uri
	end

	def test_added_predicate_adds_schema_data
		Person.add_predicate 'http://test/test'
		p = IdentifiedResource.create 'http://test/test'

		# TODO implement
		# assert all_predicates.include?(p)
	end

	def test_use_added_predicate
		Person.add_predicate 'http://test/test'
		c = Person.new 'c'

		assert_nothing_raised { c.test }
		assert_nil c.test
		c.test = 'test-value'
		assert_equal 'test-value', c.test
		assert_nothing_raised { c.save }
	end
  
 	def test_load_added_predicate
    # we cannot run this test in memory: setup in temporary location
    NodeFactory.clear
    setup_any($temp_location)
    Person.add_predicate 'http://test/test'
    
    uri = 'http://m3pe.org/eyal'
		eyal = Person.create uri
		eyal.test = 'test-value'
		eyal.save

    # clear the cache, reopen the connection to same temporary location
		NodeFactory.clear
    setup_any($temp_location)
    eyal2 = Person.create uri    
    
    # assert we have a different object, but with equal values
		assert_not_equal eyal.object_id, eyal2.object_id
		assert_equal eyal, eyal2
		assert_equal 'test-value', eyal2.test

		# removing our temporary files
    delete_any($temp_location)
    
    # need to initialise connection again, because otherwise delete_any will fail in teardown
    setup_any
	end

	def test_predicate_collision
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_raise(ActiveRdfError) { IdentifiedResource.add_predicate 'http://othernamespace/test' }
	end
	
end
