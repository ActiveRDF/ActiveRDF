# = test_redland_context_query.rb
#
# Test Unit of Redland Adapter query method on specific context
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
require 'test/adapter/redland/manage_redland_db'

class TestRedlandAdapterContextQuery < Test::Unit::TestCase

	def setup
		setup_redland('test_person')
		params = { :adapter => :redland, :context => 'test_person' }
		NodeFactory.connection(params)
	end
	
	def teardown
		delete_redland('test_person')
	end
	
	def test_A_query_all
		qs = query_test_A
		NodeFactory.connection.query(qs)
	end

	private
	
	def query_test_A
		qe = QueryEngine.new
		qe.add_binding_variables(:s, :p, :o)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end
	
end