# = test_redland_sparql_query.rb
# Unit test for sparql query methods of Redland
# ----
# Project	: ActiveRDF
#
# See		: http://m3pe.org/activerdf/
#
# Author	: Renaud Delbru, Eyal Oren
#
# Mail		: first dot last at deri dot org
#
# (c) 2005-2006

require 'test/unit'
require 'rdf/redland'

class TestRedlandSparqlQuery < Test::Unit::TestCase

	def setup
		# Load the data file
		dirname = File.dirname(__FILE__)
		system("cd #{dirname}; cp reset_test_query.sh /tmp")
		system("cd #{dirname}; cp *.xml /tmp")
		system("cd /tmp; ./reset_test_query.sh")
	
		@store = Redland::HashStore.new('bdb', 'test-store', '/tmp' , false) if @store.nil?
		@model = Redland::Model.new @store
		
		query_string = <<END_OF_STRING
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?nick, ?name
WHERE { ?x rdf:type foaf:Person . ?x foaf:nick ?nick . ?x foaf:name ?name }
END_OF_STRING
		query = Redland::Query.new(query_string, "sparql", nil, nil)
		@results = @model.query_execute(query)

	end
	
	def test_query
			assert_not_nil @results
	end
	
	def test_binding
			assert @results.is_bindings?
		
			names = @results.binding_names
			assert_equal(2, names.size)
			
			values = @results.binding_values()
			assert_equal(2, values.size)
	end
	
	def test_results
		array_result = Array.new
		
		while !@results.finished?
			values = @results.binding_values()
			array_result << values
			@results.next()
		end
		
		assert_equal(11, array_result.size)
	end
end
