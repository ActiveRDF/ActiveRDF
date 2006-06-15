# = test_yars_connection.rb
#
# Unit Test of NodeFactory with YARS connections
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
require 'active_rdf/test/common'

class TestYarsConnection < Test::Unit::TestCase
	def setup
		setup_yars
	end

	def teardown
		delete_yars
	end

	def test_simple_connections
    # you can open connection with default values, but to construct the class model a YARS instance needs to be running locally, therefore we disable class model construction
		assert_nothing_raised { NodeFactory.connection :construct_class_model => false}
		assert_nothing_raised { NodeFactory.connection :adapter => :yars, :host => $yars_host, :port => 8080 }
		assert_nothing_raised { NodeFactory.connection :construct_class_model => false, :context => $yars_context }
		assert_nothing_raised { NodeFactory.connection :adapter => :yars, :host => $yars_host, :port => 8080, :context => $yars_context }
	end

	def test_init
		assert_nothing_raised { NodeFactory.connection(:context => $yars_context, :construct_class_model => false) }
    assert_nothing_raised { NodeFactory.connection :host => $yars_host, :adapter => :yars, :context => $yars_context}
		assert_nothing_raised { NodeFactory.connection :adapter => :yars, :host => $yars_host}
		assert_nothing_raised { NodeFactory.connection}
	end

  def test_same_instance
    connection1 = NodeFactory.connection :adapter => :yars, :location => $yars_host, :construct_class_model => false
    connection2 = NodeFactory.connection :adapter => :yars, :location => $yars_host, :construct_class_model => false
    assert_same connection1, connection2
  end

## disabling context test...because it is very slow!
#  def test_get_all_contexts
#	  NodeFactory.connection :host => $yars_host
#		assert_nothing_raised {contexts = NodeFactory.get_contexts :adapter => :yars, :host => $yars_host, :port => 8080}
#		assert_not_nil contexts
#	end

	def test_switch_context
    NodeFactory.connection(:adapter => :yars, :host => $yars_host, :context => $yars_context, :construct_class_model => false)

    # if changing context without explicitly setting a new host, keep the old host
    con = NodeFactory.select_context 'abcde'
    assert_equal con.host, $yars_host
    assert_equal con.context, 'abcde'
    assert_equal con, NodeFactory.connection
    
		assert_nothing_raised { NodeFactory.select_context $yars_context}
		assert_nothing_raised { NodeFactory.select_context 'another-context'}

		assert_kind_of YarsAdapter, NodeFactory.connection
    assert_equal NodeFactory.connection.context, 'another-context'

		# open connection, then change context
		assert_nothing_raised do
			NodeFactory.connection :host => $yars_host, :port => 8080, :adapter => :yars
			NodeFactory.select_context $yars_context
		end	

		assert_equal NodeFactory.connection.context, $yars_context 
	end

  def test_default_parameters
    # if invoking NodeFactory.connection without specifying parameters, use default settings
    NodeFactory.connection(:construct_class_model => false)
    c = NodeFactory.connection
    default = NodeFactory.default_parameters
    assert c.host == default[:host]
    assert c.context == default[:context]
  end

#  # TODO: implement find within single context
#	def test_find_in_context
#		assert_nothing_raised { NodeFactory.connection :adapter => :yars, :host => $yars_host, :port => 8080, :context => $yars_context  }
#		assert_nothing_raised { NodeFactory.connection :host => $yars_host, :context => 'cia' }
#		
#    resources_in_cia = IdentifiedResource.find :context => 'cia'
#		resources_in_fbi = IdentifiedResource.find :context => 'fbi'
#		all_resources IdentifiedResource.find
#
#		# all resources should return cia plus fbi
#		assert all_resources.eql?(resources_in_cia + resources_in_fbi)
#		assert (not all_resources.eql?(resources_in_cia))
#	end

  Default_parameters = { :adapter => :yars, :host => $yars_host, :port => 8080, :context => $yars_context }
  
	def test_empty_proxy
		# TODO: verify querying over proxy server
  	assert_raise(ConnectionError){ NodeFactory.connection Default_parameters.merge(:proxy => '') }
	end

	def test_proxy_server_address
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => '81.22.90.226', :construct_class_model => false) }
	end

	def test_proxy_server
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => Net::HTTP.Proxy('81.22.90.226'), :construct_class_model=> false) }
	end

	def test_proxy_nil
		assert_nothing_raised { NodeFactory.connection Default_parameters.merge(:proxy => nil) }
	end
end
