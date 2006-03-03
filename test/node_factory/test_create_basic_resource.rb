# = test_create_basic_resource.rb
#
# Unit Test of BasicIdentifiedResource creation
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

class TestNodeFactoryBasicResource < Test::Unit::TestCase

	def test_1_create_basic_resource
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		assert_not_nil(basic_resource)
	end
	
	def test_2_read_uri
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		
		assert_equal('http://m3pe.org/basicresource', basic_resource.uri)
	end
	
	def test_3_type
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		assert(basic_resource.kind_of?(BasicIdentifiedResource))
	end
	
	def test_4_subclass_type
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		assert(basic_resource.kind_of?(Node))
		assert(basic_resource.kind_of?(Resource))
	end
	
	def test_5_create_same_instance
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		object_id = basic_resource.object_id
		basic_resource = NodeFactory.create_basic_identified_resource('http://m3pe.org/basicresource')
		assert_equal(object_id, basic_resource.object_id, "Not the same instance of the basic resource.")
	end
	
end
