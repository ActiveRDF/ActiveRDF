# Test Unit of adapter query method
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

class TestAdapterBasicQuery < Test::Unit::TestCase

	def setup    
		setup_any
		raise StandardError, 'could not load test data' unless load_test_data
    @qe = QueryEngine.new    
 	end
	
	def teardown
    delete_any
	end
	
	def test_query_all
    @qe.add_binding_variables(:s, :p, :o)
    @qe.add_condition(:s, :p, :o)
		results = NodeFactory.connection.query(@qe.generate)

		assert_not_nil(results)
		assert_instance_of(Array, results)
    # skip if using YARS because it doesnt work correctly when selecting distinct using multiple select variables
    assert_equal(49, results.size)  unless NodeFactory.connection.adapter_type == :yars
		
    result = results.first
		assert_instance_of(Array, result)
		assert_equal(3, result.size)
	end
	
	def test_query_subjects
    @qe.add_binding_variables(:s)
    @qe.add_condition(:s, :p, :o)

		results = NodeFactory.connection.query(@qe.generate)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(12, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end
	
	def test_query_predicates
    @qe.add_binding_variables(:p)
    @qe.add_condition(:s, :p, :o)
		results = NodeFactory.connection.query(@qe.generate)
		
    assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(12, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end

	def test_query_objects
    @qe.add_binding_variables(:o)
    @qe.add_condition(:s, :p, :o)
		results = NodeFactory.connection.query(@qe.generate)
    
		assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(28, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end
	
	def test_query_subject_by_predicate_and_literal_object
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
    object = NodeFactory.create_literal("23", 'xsd:integer')
  
    @qe = QueryEngine.new
    @qe.add_binding_variables(:s)
    @qe.add_condition(:s, predicate, object)
		results = NodeFactory.connection.query(@qe.generate)

		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', results.first.uri)
	end

	def test_query_subject_by_predicate_and_resource_object
    predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
    object = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
    @qe.add_binding_variables(:s)
    @qe.add_condition(:s, predicate, object)
		results = NodeFactory.connection.query(@qe.generate)

		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(2, results.size)
		for result in results
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|10)/, result.uri)
		end
	end
	
	def test_query_predicate_by_subject_and_literal_object
    subject = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
    object = NodeFactory.create_literal('renaud', 'xsd:string')
    @qe.add_binding_variables(:p)
    @qe.add_condition(subject, :p, object)
		results = NodeFactory.connection.query(@qe.generate)

		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://m3pe.org/activerdf/test/name', results.first.uri)
	end
	
	def test_query_predicate_by_subject_and_resource_object
    subject = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
    object = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
    @qe.add_binding_variables(:p)
    @qe.add_condition(subject, :p, object)	
  	results = NodeFactory.connection.query(@qe.generate)
    
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://m3pe.org/activerdf/test/knows', results.first.uri)
	end
	
	def test_query_literal_object_by_subject_and_predicate
		subject = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
    predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/name')
    @qe.add_binding_variables(:o)
    @qe.add_condition(subject, predicate, :o)
    results = NodeFactory.connection.query(@qe.generate)
    
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Literal, results.first)
		assert_equal('renaud', results.first.value)
	end
	
	def test_query_resource_object_by_subject_and_predicate
		subject = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
    predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
    @qe.add_binding_variables(:o)
    @qe.add_condition(subject, predicate, :o)
    results = NodeFactory.connection.query(@qe.generate)
    
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_9', results.first.uri)
	end
end