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
	def setup
		case DB
		when :yars
			NodeFactory.connection(:adapter => :yars, :host => DB_HOST, :context => 'test_create_person')
			require 'active_rdf/test/adapter/yars/manage_yars_db'
			setup_yars('test_create_person')

		when :redland
			NodeFactory.connection(:adapter => :redland, :location => :memory, :construct_class_model => false)

		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def teardown
		case DB
		when :yars
			delete_yars('test_create_person')
		end	
	end

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
		basic_resource1 = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		basic_resource2 = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert_equal(basic_resource1, basic_resource2, "Not the same instance of the basic resource.")
	end
	
end
