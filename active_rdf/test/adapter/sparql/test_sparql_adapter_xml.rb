require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'
require 'adapter/sparql/sparql_adapter'

class TestSparqlJson < Test::Unit::TestCase
	
	def setup
		NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'my.opera.com', :port => 80 , :context => 'community/sparql/sparql', :result_format => :xml)
		@qe = QueryEngine.new
	end
	
	def teardown
	end
	
	def test_sp
		@qe.add_binding_variables(:s, :p)
		@qe.add_condition(:s, :p, Literal.new("Haavard", "xsd:string"))
		results = @qe.execute
		
		assert_not_nil(results)
		assert(results.size > 0)
		
		assert(results.all? { |result| result.all? {|r| r.nil? or r.kind_of?(Node) }})
		assert(results.all? { |result| result.size == 2})
	end
	
	def test_p
		@qe.add_binding_variables(:p)
		@qe.add_condition(:s, :p, Literal.new("Haavard", "xsd:string"))
		results = @qe.execute
	
		assert_not_nil(results)
		assert(results.size > 0)	
	
		assert (results.all? { |r| r.nil? or r.kind_of?(Node) })
	end
end
