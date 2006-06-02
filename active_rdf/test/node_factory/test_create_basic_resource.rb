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
require 'active_rdf/test/adapter/yars/manage_yars_db'
require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestNodeFactoryBasicResource < Test::Unit::TestCase
	def setup
		case DB
		when :yars
			setup_yars('test_create_person')
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_create_person' }
			@connection = NodeFactory.connection(params)
		when :redland
			setup_redland
			params = { :adapter => :redland }
			@connection = NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def teardown
		case DB
		when :yars
			delete_yars('test_create_person')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
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
