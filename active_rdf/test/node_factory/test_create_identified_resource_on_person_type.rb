# = test_create_identified_resource_on_person_type.rb
#
# Unit Test of IdentifiedResource creation on person type
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

class TestNodeFactoryIdentifiedResource < Test::Unit::TestCase

	def setup
		setup_any
    require 'active_rdf/test/node_factory/person'
	end
	
	def teardown
		delete_any
	end

	def test_create_identified_resource_with_known_type_and_no_attributes
		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_not_nil(person)

    assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', person.uri)

		assert_kind_of(IdentifiedResource, person)
		assert_kind_of(Resource, person)
		assert_kind_of(Node, person)
	end

	def test_create_same_instance_of_known_type
		person1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		person2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_equal(person1,person2)
	end
end
