# = test_initialisation_yars.rb
#
# Unit Test of NodeFactory initialisation
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

class TestNodeFactoryInitialisationYars < Test::Unit::TestCase

	def test_1_connection_error
		assert_raise(ConnectionError) {
			NodeFactory.connection
		}
	end
	
	def test_2_connection_yars
		params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'citeseer' }
		connection = NodeFactory.connection(params)
		assert_not_nil(connection)
	end

	def test_3_connection_same_instance
		params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'citeseer' }
		connection = NodeFactory.connection(params)
		object_id = connection.object_id
		connection = NodeFactory.connection
		assert_equal(object_id, connection.object_id, "Not the same instance of the connection.")
	end
end
