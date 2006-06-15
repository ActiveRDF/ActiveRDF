# Test Unit of adapter query method with joint conditions
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

class TestAdapterJointQuery < Test::Unit::TestCase

	def setup
		setup_any
    raise StandardError, "could not load test data" unless load_test_data
	end
	
	def teardown
    #delete_any
  end
	
	def test_query_subject_with_joint_resource_object
    predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
    object1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
    object2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
  
    qe = QueryEngine.new
    qe.add_binding_variables(:s)
    qe.add_condition(:s, predicate, object1)
    qe.add_condition(:s, predicate, object2)
    qs = qe.generate
    
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		result = results.first
		assert_kind_of(Resource, result)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_10', result.uri)
	end
	
	def test_query_subject_with_joint_literal_object
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
    predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/name')
    object1 = NodeFactory.create_literal('45', 'xsd:integer')
    object2 = NodeFactory.create_literal('regis', 'xsd:string')
  
    qe = QueryEngine.new
    qe.add_binding_variables(:s)
    qe.add_condition(:s, predicate1, object1)
    qe.add_condition(:s, predicate2, object2)
    qs = qe.generate

		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		result = results.first
		assert_kind_of(Resource, result)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_10', result.uri)
	end
	
	def test_query_object_with_joint_resource_object
	  predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
    predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
    object1 = NodeFactory.create_literal('45', 'xsd:integer')
  
    qe = QueryEngine.new
    qe.add_binding_variables(:o)
    qe.add_condition(:s, predicate1, object1)
    qe.add_condition(:s, predicate2, :o)
    qs = qe.generate    

		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(3, results.size)
		for result in results
			assert_kind_of(Resource, result)
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|9|10)/, result.uri)
		end	
	end
	
	def test_query_subject_with_transitive_joint		
    predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
    predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
    object = NodeFactory.create_literal('19', 'xsd:integer')
  
    qe = QueryEngine.new
    qe.add_binding_variables(:s)
    qe.add_condition(:s, predicate1, :x)
    qe.add_condition(:x, predicate2, object)
    qs = qe.generate  
    
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(2, results.size)
		for result in results
			assert_kind_of(Resource, result)
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|10)/, result.uri)
		end			
	end
end
