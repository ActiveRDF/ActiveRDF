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
	
end
