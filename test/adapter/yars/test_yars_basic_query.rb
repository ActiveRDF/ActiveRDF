# = test_yars_basic_query.rb
#
# Test Unit of Yars Adapter query method
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
# == To-do
#
# * To-do 1
#

require 'test/unit'
require 'active_rdf'
require 'node_factory'

class TestYarsAdapterBasicQuery < Test::Unit::TestCase

	@@adapter = nil

	def setup
		params = { :adapter => :yars, :host => 'opteron', :port => 8080, :context => 'test' }
		@@adapter = NodeFactory.connection(params) if @@adapter.nil?
	end
	
	def test_A_query_all
		qs = query_test_A
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(46, results.size)
		result = results.first
		assert_instance_of(Array, result)
		assert_equal(3, result.size)
	end
	
	def test_B_query_subjects
		qs = query_test_B
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(11, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end
	
	def test_C_query_predicates
		qs = query_test_C
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(9, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end

	def test_D_query_objects
		qs = query_test_D
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		results.uniq!
		assert_equal(31, results.size)
		result = results.first
		assert_kind_of(Node, result)
	end
	
	def test_E_query_subject_by_predicate_and_literal_object
		qs = query_test_E
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_equal('http://protege.stanford.edu/rdftest_set_Instance_7', results.first.uri)
	end

	def test_F_query_subject_by_predicate_and_resource_object
		qs = query_test_F
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(2, results.size)
		for result in results
			assert_match(/http:\/\/protege\.stanford\.edu\/rdftest_set_Instance_(7|10)/, result.uri)
		end
	end
	
	def test_G_query_predicate_by_subject_and_literal_object
		qs = query_test_G
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://protege.stanford.edu/rdfname', results.first.uri)
	end
	
	def test_H_query_predicate_by_subject_and_resource_object
		qs = query_test_H
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://protege.stanford.edu/rdfknows', results.first.uri)
	end
	
	def test_I_query_literal_object_by_subject_and_predicate
		qs = query_test_I
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Literal, results.first)
		assert_equal('renaud', results.first.value)
	end
	
	def test_J_query_resource_object_by_subject_and_predicate
		qs = query_test_J
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(1, results.size)
		assert_kind_of(Resource, results.first)
		assert_equal('http://protege.stanford.edu/rdftest_set_Instance_9', results.first.uri)
	end

	private
	
	def query_test_A
		qe = QueryEngine.new
		qe.add_binding_variables(:s, :p, :o)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end
	
	def query_test_B
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end

	def query_test_C
		qe = QueryEngine.new
		qe.add_binding_variables(:p)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end

	def query_test_D
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end
	
	def query_test_E
		predicate = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdfage')
		object = NodeFactory.create_literal("23", 'xsd:integer')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, predicate, object)
		return qe.generate
	end
	
	def query_test_F
		predicate = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdfknows')
		object = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_9')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:s)
		qe.add_condition(:s, predicate, object)
		return qe.generate
	end
	
	def query_test_G
		subject = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_7')
		object = NodeFactory.create_literal('renaud', 'xsd:string')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:p)
		qe.add_condition(subject, :p, object)
		return qe.generate
	end

	def query_test_H
		subject = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_7')
		object = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_9')
	
		qe = QueryEngine.new
		qe.add_binding_variables(:p)
		qe.add_condition(subject, :p, object)
		return qe.generate
	end
	
	def query_test_I
		subject = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_7')
		predicate = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdfname')
		
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(subject, predicate, :o)
		return qe.generate
	end
	
	def query_test_J
		subject = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_7')
		predicate = NodeFactory.create_basic_identified_resource('http://protege.stanford.edu/rdfknows')
		
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(subject, predicate, :o)
		return qe.generate		
	end
	
end
