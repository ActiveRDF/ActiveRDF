# = test_redland_connection.rb
#
# Unit Test of NodeFactory with Redland connections
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
require 'active_rdf/test/adapter/redland/manage_redland_db'
require 'tmpdir'

class TestRedlandConnection < Test::Unit::TestCase
	Default_parameters = { :adapter => :redland, :location => :memory }

	def test_simple_connections
		assert_nothing_raised { NodeFactory.connection :adapter => :redland, :location => :memory, :construct_class_model => false }
		assert_nothing_raised { NodeFactory.connection :adapter => :redland, :location => :memory }
		assert_nothing_raised { NodeFactory.connection :adapter => :redland }
	end
  
  def test_same_instance
		connection3 = NodeFactory.connection :adapter => :redland, :location => :memory
		connection4 = NodeFactory.connection :adapter => :redland, :location => :memory
    assert_same connection3, connection4
  end

#  # TODO: implement find within single context
#	def test_find_in_context
#		assert_nothing_raised { NodeFactory.connection :adapter => DB, :host => DB_HOST, :port => 8080, :context => TestContext  }
#		assert_nothing_raised { NodeFactory.connection :host => DB_HOST, :context => 'cia' }
#		
#    resources_in_cia = IdentifiedResource.find :context => 'cia'
#		resources_in_fbi = IdentifiedResource.find :context => 'fbi'
#		all_resources IdentifiedResource.find
#
#		# all resources should return cia plus fbi
#		assert all_resources.eql?(resources_in_cia + resources_in_fbi)
#		assert (not all_resources.eql?(resources_in_cia))
#	end

end
