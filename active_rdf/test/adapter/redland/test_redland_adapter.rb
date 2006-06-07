# = test_redland_adapter.rb
#
# Unit Test of Redland adapter
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

require 'active_rdf'
require 'active_rdf/test/common'
require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestRedlandAdapter < Test::Unit::TestCase
	def setup
		setup_connection
	end

	def teardown
		delete_redland
	end

	def test_A_initialize
		params = { :adapter => :redland, :location => :memory }
		connection = NodeFactory.connection
		
		assert_not_nil(connection)
		assert_kind_of(AbstractAdapter, connection)
		assert_instance_of(RedlandAdapter, connection)
	end
	
	def test_B_initialize_with_location
		params = { :adapter => :redland, :location => '/tmp/test-store-2' }
		connection = NodeFactory.connection(params)
		
		assert_not_nil(connection)
		assert_kind_of(AbstractAdapter, connection)
		assert_instance_of(RedlandAdapter, connection)
		
		assert(File.exists?('/tmp/test-store-2-po2s.db'))
		
		delete_redland
	end

	def test_C_initialize_with_location_in_memory
		params = { :adapter => :redland, :location => :memory }
		connection = NodeFactory.connection(params)
		
		assert_not_nil(connection)
		assert_kind_of(AbstractAdapter, connection)
		assert_instance_of(RedlandAdapter, connection)
	end
	
	def test_D_save
		params = { :adapter => :redland, :location => :memory }
		connection = NodeFactory.connection(params)
		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		connection.add(subject, predicate, object)
		
		assert_nothing_raised(RedlandAdapterError) {
			connection.save
		}
		
		delete_redland
	end
	
end
