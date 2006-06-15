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
require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'

class TestIdentifiedResourceCreate < Test::Unit::TestCase

	def setup
		setup_any
    require 'active_rdf/test/node_factory/person'
	end
	
	def teardown
		delete_any
	end

	def test_create_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
	end
	
	def test_create_two_times_same_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
		ir2 = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_equal(ir, ir2)
	end
	
	def test_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		assert(Resource.exists?(person))
	end
	
	def test_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		assert(Person.exists?(person))
	end
	
	def test_load_person
    return unless load_test_data
		regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		assert_equal('45', regis.age)
	end
	
	def test_load_person_via_identified_resource
    return unless load_test_data
		regis = IdentifiedResource.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		assert_equal('45', regis.age)		
	end

end
