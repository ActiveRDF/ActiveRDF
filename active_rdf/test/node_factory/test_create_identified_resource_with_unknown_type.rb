# = test_create_identified_resource_with_unknown_type.rb
#
# Unit Test of IdentifiedResource creation with unknown type
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

class TestNodeFactoryUnknownIdentifiedResource < Test::Unit::TestCase

	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end

	def test_create_identified_resource_with_unknown_type
		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_not_nil(identified_resource)
	
		assert_equal('http://m3pe.org/identifiedresource', identified_resource.uri)
	
    assert_instance_of(IdentifiedResource, identified_resource)
		assert_kind_of(Node, identified_resource)
		assert_kind_of(Resource, identified_resource)
	end

	def test_create_same_instance_of_unknown_type
		r1 = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		r2 = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_equal r1,r2
	end
end
