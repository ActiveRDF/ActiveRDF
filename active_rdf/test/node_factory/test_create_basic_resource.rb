# = test_create_basic_resource.rb
#
# Unit Test of basic IdentifiedResource creation (intern method)
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
require 'node_factory'

class TestNodeFactoryBasicResource < Test::Unit::TestCase

	def test_A_create_basic_resource
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert_not_nil(basic_resource)
	end
	
	def test_B_read_uri
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		
		assert_equal('http://m3pe.org/basicresource', basic_resource.uri)
	end
	
	def test_C_type
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert_kind_of(IdentifiedResource, basic_resource)
	end
	
	def test_D_superclass_type
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert_kind_of(Node, basic_resource)
		assert_kind_of(Resource, basic_resource)
	end
	
	def test_E_create_same_instance
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		object_id = basic_resource.object_id
		basic_resource = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert_equal(object_id, basic_resource.object_id, "Not the same instance of the basic resource.")
	end
	
end
