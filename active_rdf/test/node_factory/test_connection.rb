# = test_connection.rb
#
# Unit Test of NodeFactory with multiple connections
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

	DB = :yars
	DB_HOST = 'browserdf.org'
require 'test/unit'
require 'active_rdf'
require 'node_factory'
require 'test/adapter/yars/manage_yars_db'
require 'test/adapter/redland/manage_redland_db'

class TestConnection < Test::Unit::TestCase
	Context = 'test_connection'
	Default_parameters = { :adapter => DB, :host => DB_HOST, :portr => 8080, :context => Context }

	def setup
		setup_yars Context
	end

	def teardown
		delete_yars Context
	end

	def test_A_1
		assert_nothing_raised { NodeFactory.connection :context => Context }
	end

	def test_A_2
		assert_nothing_raised { NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080 }
	end
	
	def test_A_3
		assert_nothing_raised {NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080, :context => Context }
	end

	def test_A_4
		NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080
		
		assert_nothing_raised { NodeFactory.connection }
		assert_nothing_raised { NodeFactory.connection :context => Context }
		assert_nothing_raised { NodeFactory.select_context Context }
	end

	def test_AB_various_inits
		assert_nothing_raised { NodeFactory.connection :context => Context }
		assert_nothing_raised { NodeFactory.connection :adapter => :yars, :host => DB_HOST}
		assert_nothing_raised { NodeFactory.connection}
	end

#	def test_B_get_contexts
#		##
#		## disabling context test...is very slow!
#		
#		#assert_nothing_raised {contexts = NodeFactory.get_contexts :adapter => DB, :host => DB_HOST, :port => 8080}
#		#assert_not_nil contexts
#	end
#
	def test_C_add_context
		assert_raise(ConnectionError) { NodeFactory.connection}
		assert_nothing_raised { NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080, :context => Context}
		assert_nothing_raised { NodeFactory.select_context Context}
		assert_nothing_raised { NodeFactory.select_context 'another-context'}
		assert_kind_of YarsAdapter, NodeFactory.connection(:context => Context )
		all_resources = IdentifiedResource.find

		# TODO: find :context => ...
		# TODO: does everything automatically work in current context?
		#resources_in_fbi = IdentifiedResource.find {}, :context => Context 
		#assert_equal all_resources, resources_in_fbi
	end

	def test_E_switch_context
		assert_raise(ConnectionError){ NodeFactory.select_context }
		assert_raise(ConnectionError){NodeFactory.select_context Context }
		assert_nothing_raised do
			NodeFactory.connection :host => DB_HOST, :port => 8080, :adapter => DB
			NodeFactory.select_context Context
		end	
		assert NodeFactory.connection.context == Context 
		assert_nothing_raised {NodeFactory.select_context 'toet' }
		assert NodeFactory.connection.context == 'toet'
	end

	def test_D_add_another_context
		#assert_nothing_raised { NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080, :context => Context  }
		#assert_nothing_raised {NodeFactory.connection :context => 'cia'}
		#assert_kind_of YarsAdapter, NodeFactory.connection(:context => 'cia')
		#resources_in_cia = IdentifiedResource.find :context => 'cia'
		#resources_in_fbi = IdentifiedResource.find :context => 'fbi'
		#all_resources IdentifiedResource.find

		# all resources should return cia plus fbi
		#assert all_resources.eql?(resources_in_cia + resources_in_fbi)
		#assert (not all_resources.eql?(resources_in_cia))
	end

	def test_proxy_A
		# TODO: verify querying over proxy server
		assert_raise(ConnectionError){ NodeFactory.connection Default_parameters.merge(:proxy => '') }
	end

	def test_proxy_B
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => '81.22.90.226', :construct_class_model => false) }
	end

	def test_proxy_C
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => Net::HTTP.Proxy('81.22.90.226'), :construct_class_model=> false) }
	end

	def test_proxy_D
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => nil) }
	end
end
