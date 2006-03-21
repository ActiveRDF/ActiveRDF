# = test_yars_resource_find.rb
#
# Unit Test of Resource find method with yars adapter
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
require 'test/adapter/yars/setup_yars'

class TestYarsResourceFind < Test::Unit::TestCase

	def setup
		setup_yars 'test_query'
		params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_query' }
		NodeFactory.connection(params)
	end
	
	def teardown
		delete_yars 'test_query'
	end
	
	def test_A_empty_db
		params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'empty' }
		NodeFactory.connection(params)
		
		results = Resource.find
		assert_nil(results)
	end
	
	def test_B_find_all
		results = Resource.find
		assert_not_nil(results)
		assert_instance_of(Array, results)
		assert_equal(11, results.size)
	end
	
	def test_C_find_predicate
		class_uri = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/Person')
		predicates = Resource.find({ NamespaceFactory.get(:rdfs_domain) => class_uri })
		assert_not_nil(predicates)
		assert_instance_of(Array, predicates)
		assert_equal(3, predicates.size)
		for predicate in predicates
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/(age|knows|name)/, predicate.uri)
		end
	end
	
	def test_D_find_resource_knows_instance_9
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
		subjects = Resource.find({predicate => object})
		assert_not_nil(subjects)
		assert_instance_of(Array, subjects)
		assert_equal(2, subjects.size)
		for subject in subjects
			assert_match(/http:\/\/m3pe\.org\/activerdf\/test\/test_set_Instance_(7|10)/, subject.uri)
		end
	end
	
	def test_E_find_resource_with_two_conditions
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/knows')
		object1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_9')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/name')
		object2 = NodeFactory.create_literal('renaud', 'string')
		
		subject = Resource.find({predicate1 => object1, predicate2 => object2})
		assert_not_nil(subject)
		assert_kind_of(Resource, subject)
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', subject.uri)
	end
	
end
