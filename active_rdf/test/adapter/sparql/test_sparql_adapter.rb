require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'
require 'adapter/sparql/sparql_adapter'

class TestSparqlJson < Test::Unit::TestCase
	def setup		
		NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'm3pe.org', :port => 2020 , :context => 'books', :result_format => :json)
		@qe = QueryEngine.new
	end
	
	def teardown
		delete_any
	end	
	
	def test_spo
		@qe.add_binding_variables(:s, :p, :o)
		@qe.add_condition(:s, :p, :o)		
		results = @qe.execute
		
		assert_not_nil(results)
		assert(results.size > 0)
		
		assert_type results
		assert_size results, 3		
	end
	
	def test_all_sp
		@qe.add_binding_variables(:s, :p)
		@qe.add_condition(:s, :p, :o)
		results = @qe.execute
	
		assert_not_nil(results)
		assert(results.size > 0)
		
		assert_type results
		assert_size results, 2
	end
	
	def test_all_s
		@qe.add_binding_variables(:s)
		@qe.add_condition(:s, :p, :o)
		results = @qe.execute
		
		assert_not_nil(results)
		assert(results.size > 0)		
		assert (results.all? { |r| r.nil? or r.kind_of?(Node) })
	end
	
	# assert that all results are either nodes or nil	
	def assert_type results
		assert(results.all? { |result| result.all? {|r| r.nil? or r.kind_of?(Node) }})
	end
	
	# assert that all results are array of size three (s,p,o)
	def assert_size results, size	
		assert(results.all? { |result| result.size == size})
	end
end