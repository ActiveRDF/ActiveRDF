# = test_identifiedresource_create.rb
#
# Unit Test of IdentifiedResource create method
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
require 'test/node_factory/person'

class TestIdentifiedResourceCreate < Test::Unit::TestCase

	@@loaded = false

	def setup
		if !@@loaded
			# Load the data file
			dirname = File.dirname(__FILE__)
			system("cd #{dirname}; cp reset_test_identifiedresource_create.sh /tmp")
			system("cd #{dirname}; cp test_set.rdf /tmp")
			system("cd /tmp; ./reset_test_identifiedresource_create.sh")
		
			params = { :adapter => :redland }
			NodeFactory.connection(params)
			@@loaded = true
		end
	end

	def test_A_create_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
	end
	
	def test_B_create_two_times_same_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
		ir2 = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_equal(ir.object_id, ir2.object_id)
	end
	
	def test_C_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		p Resource.exists?(person)
	end
	
	def test_D_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		p Person.exists?(person)
	end
	
	def test_D_load_person
		regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		assert_equal('45', regis.age)
	end

end
