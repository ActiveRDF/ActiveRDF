# = test_redland_resource_find.rb
#
# Unit Test of Resource find method with redland adapter
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

class TestRedlandResourceFind < Test::Unit::TestCase

	@@loaded = false

	def setup
		if !@@loaded
			# Load the data file
			dirname = File.dirname(__FILE__)
			system("cd #{dirname}/../adapter/redland; cp reset_test_redland_query.sh /tmp")
			system("cd #{dirname}/../adapter/redland; cp test_set.rdfs /tmp")
			system("cd #{dirname}/../adapter/redland; cp test_set.rdf /tmp")
			system("cd /tmp; ./reset_test_redland_query.sh")
		
			params = { :adapter => :redland }
			NodeFactory.connection(params)
			@@loaded = true
		end
	end
	
	def test_A_empty_db
		@@loaded = false
		system("cd /tmp; rm test-store*.db")
		params = { :adapter => :redland }
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
		class_uri = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdfPerson')
		predicates = Resource.find({ NamespaceFactory.get(:rdfs_domain) => class_uri })
		assert_not_nil(predicates)
		assert_instance_of(Array, predicates)
		assert_equal(3, predicates.size)
		for predicate in predicates
			assert_match(/http:\/\/protege\.stanford\.edu\/rdf(age|knows|name)/, predicate.uri)
		end
	end
	
	def test_D_find_resource_knows_instance_9
		predicate = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdfknows')
		object = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_9')
		subjects = Resource.find({predicate => object})
		assert_not_nil(subjects)
		assert_instance_of(Array, subjects)
		assert_equal(2, subjects.size)
		for subject in subjects
			assert_match(/http:\/\/protege\.stanford\.edu\/rdftest_set_Instance_(7|10)/, subject.uri)
		end
	end
	
	def test_E_find_resource_with_two_conditions
		predicate1 = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdfknows')
		object1 = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdftest_set_Instance_9')
		predicate2 = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdfname')
		object2 = NodeFactory.create_literal('renaud', 'string')
		
		subject = Resource.find({predicate1 => object1, predicate2 => object2})
		assert_not_nil(subject)
		assert_kind_of(Resource, subject)
		assert_equal('http://protege.stanford.edu/rdftest_set_Instance_7', subject.uri)
	end
	
end
