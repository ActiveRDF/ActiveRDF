# = test_initialisation_connection.rb
#
# Unit Test of NodeFactory connection method for Yars and Redland
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

class TestNodeFactoryInitialisationConnection < Test::Unit::TestCase

	def test_1_connection_error
		assert_raise(ConnectionError) {
			NodeFactory.connection
		}
	end
	
	def test_2_connection_redland
		params = get_connection_parameters
		connection = NodeFactory.connection(params)
		assert_not_nil(connection)
	end
	
	def test_3_connection_same_instance
		params = get_connection_parameters
		connection = NodeFactory.connection(params)
		object_id = connection.object_id
		connection = NodeFactory.connection
		assert_equal(object_id, connection.object_id, "Not the same instance of the connection.")
	end
	
	private
	
	def get_connection_parameters
		case DB
		when :yars
			return { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'citeseer' }
		when :redland
			return { :adapter => :redland }
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
end
