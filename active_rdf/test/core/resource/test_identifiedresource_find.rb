# = test_identifiedresource_find.rb
#
# Unit Test of IdentifiedResource find method
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
#

require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'

class TestIdentifiedResourceFind < Test::Unit::TestCase

	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_empty_db		
		assert IdentifiedResource.find.empty?    
    assert Resource.find.empty?
	end
	
	def test_find_all    
    return unless load_test_data
		results = IdentifiedResource.find
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(12, results.size)
    
    results2 = Resource.find
    assert_equal results2, results
	end
	
	def test_find_predicate
    return unless load_test_data
		class_uri = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/Person')
		predicates = IdentifiedResource.find({ NamespaceFactory.get(:rdfs, 'domain') => class_uri })
		assert_not_nil(predicates)
		assert_instance_of(Array, predicates)
		assert_equal(3, predicates.size)
		for predicate in predicates
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/(age|knows|name)/, predicate.uri)
		end
	end
	
	def test_find_resource_knows_instance_9
    return unless load_test_data
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
		subjects = IdentifiedResource.find({predicate => object})
		assert_not_nil(subjects)
		assert_instance_of(Array, subjects)
		assert_equal(2, subjects.size)
		for subject in subjects
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|10)/, subject.uri)
		end
	end
	
	def test_find_resource_with_two_conditions
    return unless load_test_data
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/name')
		object2 = NodeFactory.create_literal('renaud', 'string')
		
		subject = Resource.find({predicate1 => object1, predicate2 => object2}).first
		assert_not_nil(subject)
		assert_kind_of(Resource, subject)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', subject.uri)
	end
	
end
