# = test_redland_joint_query.rb
#
# Test Unit of Redland Adapter query method with joint conditions
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

require 'active_rdf'
require 'active_rdf/test/common'
#require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestRedlandAdapterJointQuery < Test::Unit::TestCase

	def setup
		setup_redland
    
		parser = Redland::Parser.new
		model = NodeFactory.connection.model
		dataset = File.read "#{File.dirname(__FILE__)}/../../test_set_person.rdf"
		parser.parse_string_into_model(model,dataset,'uri://test-set-activerdf/')
	end
	
	def teardown
	   NodeFactory.clear
  end
	
	def test_A_query_subject_with_joint_resource_object
		qs = query_test_A
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		result = results.first
		assert_kind_of(Resource, result)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_10', result.uri)
	end
	
	def test_B_query_subject_with_joint_literal_object
		qs = query_test_B
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		result = results.first
		assert_kind_of(Resource, result)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_10', result.uri)
	end
	
	def test_C_query_object_with_joint_resource_object
		qs = query_test_C
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(3, results.size)
		for result in results
			assert_kind_of(Resource, result)
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|9|10)/, result.uri)
		end	
	end
	
	def test_D_query_subject_with_transitive_joint
		qs = query_test_D
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(2, results.size)
		for result in results
			assert_kind_of(Resource, result)
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|10)/, result.uri)
		end			
	end

	private
	
	def query_test_A
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		object2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, predicate, object1)
		qe.add_condition(:s, predicate, object2)
		return qe.generate
	end
	
	def query_test_B
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/name')
		object1 = NodeFactory.create_literal('45', 'xsd:integer')
		object2 = NodeFactory.create_literal('regis', 'xsd:string')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, predicate1, object1)
		qe.add_condition(:s, predicate2, object2)
		return qe.generate
	end
	
	def query_test_C
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object1 = NodeFactory.create_literal('45', 'xsd:integer')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(:s, predicate1, object1)
		qe.add_condition(:s, predicate2, :o)
		return qe.generate		
	end
	
	def query_test_D
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
		object = NodeFactory.create_literal('19', 'xsd:integer')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, predicate1, :x)
		qe.add_condition(:x, predicate2, object)
		return qe.generate		
	end
	
end
