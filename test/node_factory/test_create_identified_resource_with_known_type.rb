# = test_create_identified_resource_with_known_type.rb
#
# Unit Test of IdentifiedResource creation with known type
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

class TestNodeFactoryIdentifiedResource < Test::Unit::TestCase

	@@adapter = nil

	def setup
		params = { :adapter => :yars, :host => 'opteron', :port => 8080, :context => 'test_node_factory' }
		@@adapter = NodeFactory.connection(params) if @@adapter.nil?
	end
	
	def test_try_to_instanciate_a_resource_type_as_identified_resource
#		test = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/Person')
#		assert_not_nil(test)
#		p test.class
		test = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/age')
		p test.class
	end

#	def test_A_create_identified_resource_with_know_type_and_no_attributes
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_not_nil(person)
#		assert_instance_of(Person, person)
#	end
#
#	def test_B_read_uri_of_known_type
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', person.uri)
#	end
#
#	def test_C_type_of_known_type
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_instance_of(Person, person)
#	end
#
#	def test_D_subclass_type_of_known_type
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_kind_of(IdentifiedResource, person)
#		assert_kind_of(Resource, person)
#		assert_kind_of(Node, person)
#	end
#
#	def test_E_create_same_instance_of_known_type
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		object_id = person.object_id
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_equal(object_id, person.object_id, "Not the same instance of Person.")
#	end
#
#	def test_F_verify_literal_attributes
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		assert_equal('23', person['age'].value)
#		assert_equal('renaud', person['name'].value)
#		assert_equal('23', person.age)
#		assert_equal('renaud', person.name)
#	end
#	
#	def test_G_verify_resource_attributes
#		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
#		other_person = person.knows
#		assert_not_nil(other_person)
#		assert_kind_of(Person, other_person)
#		assert_equal('19', other_person['age'].value)
#		assert_equal('audrey', other_person['name'].value)
#		assert_equal('19', other_person.age)
#		assert_equal('audrey', other_person.name)		
#
#		renaud = other_person.knows
#		assert_equal(renaud.object_id, person.object_id)
#	end
#	
#	def test_H_verify_multiple_resource_attributes
#		regis = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_10')
#		other_persons = regis.knows
#		assert_not_nil(other_persons)
#		assert_kind_of(Array, other_persons)
#		for person in other_persons
#			assert_kind_of(Person, person)
#		end
#	end

#	def test_G_create_identified_resource_existing_in_the_db_with_unknow_type
#		attributes = {'first' => 'one', 'second' => 2}
#		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identified_resource_with_unknow_type', attributes)
#		assert_not_nil(identified_resource)
#		assert_kind_of(IdentifiedResource, identified_resource)
#		assert_equal('one', identified_resource['first'])
#		assert_equal(2, identified_resource['second'])
#		assert_equal('one', identified_resource.first)
#		assert_equal(2, identified_resource.second)
#	end

end
