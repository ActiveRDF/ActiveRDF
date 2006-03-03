# = test_redland_query.rb
#
# Test Unit of Redland Adapter query method
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
require 'adapter/redland/redland_adapter'
require 'node_factory'

class TestRedlandAdapterQuery < Test::Unit::TestCase

	def setup
		# Load the data file
		dirname = File.dirname(__FILE__)
		system("cd #{dirname}; cp reset_test_redland_query.sh /tmp")
		system("cd #{dirname}; cp ./../test_set.rdfs /tmp")
		system("cd #{dirname}; cp ./../test_set.rdf /tmp")
		system("cd /tmp; ./reset_test_redland_query.sh")
		
		params = { :adapter => :redland }
		NodeFactory.connection(params)
	end
	
	def test_1_query_all
		qs = query_test_1
		results = NodeFactory.connection.query(qs)
		assert_not_nil(results)
		assert(results.instance_of?(Array))
		assert_equal(46, results.size)
	end
	
	private
	
	def query_test_1
		qe = QueryEngine.new
		qe.add_binding_variables(:s, :p, :o)
		qe.add_condition(:s, :p, :o)
		return qe.generate
	end
	
end