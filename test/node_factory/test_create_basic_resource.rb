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

	@@adapter = nil

	def setup
		params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_node_factory' }
		@@adapter = NodeFactory.connection(params) if @@adapter.nil?
	end

	def test_A_create_basic_resource
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		assert_not_nil(basic_resource)
	end
	
	def test_B_read_uri
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		
		assert_equal('http://m3pe.org/basicresource', basic_resource.uri)
	end
	
	def test_C_type
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		assert(basic_resource.kind_of?(IdentifiedResource))
	end
	
	def test_D_superclass_type
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		assert(basic_resource.kind_of?(Node))
		assert(basic_resource.kind_of?(Resource))
	end
	
	def test_E_create_same_instance
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		object_id = basic_resource.object_id
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		assert_equal(object_id, basic_resource.object_id, "Not the same instance of the basic resource.")
	end
	
	def test_F_class_uri_from_class
		class_uri = IdentifiedResource.class_URI
		assert_not_nil(class_uri)
		assert(class_uri.kind_of?(IdentifiedResource))
		assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource", class_uri.uri)
	end
	
	def test_G_class_uri_from_instance
		basic_resource = NodeFactory.create_identified_resource('http://m3pe.org/basicresource')
		class_uri = basic_resource.class_URI
		assert_not_nil(class_uri)
		assert(class_uri.kind_of?(IdentifiedResource))
		assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource", class_uri.uri)
	end
	
end
