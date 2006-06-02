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
require 'node_factory'
require 'active_rdf/test/adapter/yars/manage_yars_db'
require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestNodeFactoryUnknownIdentifiedResource < Test::Unit::TestCase

	def setup
		case DB
		when :yars
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_create_identified_resource' }
			@connection = NodeFactory.connection(params)
		when :redland
			params = { :adapter => :redland }
			@connection = NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def teardown
		case DB
		when :yars
			delete_yars('test_create_identified_resource')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end

	def test_A_create_identified_resource_with_unknow_type
		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_not_nil(identified_resource)
	end

	def test_B_read_uri_of_unknow_type
		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_equal('http://m3pe.org/identifiedresource', identified_resource.uri)
	end

	def test_C_type_of_unknow_type
		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_instance_of(IdentifiedResource, identified_resource)
	end

	def test_D_superclass_type_of_unknow_type
		identified_resource = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_kind_of(Node, identified_resource)
		assert_kind_of(Resource, identified_resource)
	end

	def test_E_create_same_instance_of_unknow_type
		identified_resource1 = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		identified_resource2 = NodeFactory.create_identified_resource('http://m3pe.org/identifiedresource')
		assert_equal(identified_resource1, identified_resource2, "Not the same instance of the identified resource.")
	end


end
