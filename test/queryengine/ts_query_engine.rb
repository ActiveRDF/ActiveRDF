require 'test/unit'
require 'active_rdf'
require 'queryengine/query'
require 'queryengine/query2sparql'

class TestObjectCreation < Test::Unit::TestCase
	def setup
	end
	
	def teardown
	end
	
	def test_sparql_generation
		query = Query.new
		query.select(:s)
		query.where(:s, 'foaf:age', '30')
		
		generated = Query2SPARQL.instance.translate(query)
		expected = "SELECT DISTINCT ?s WHERE { ?s foaf:age 30 .}"
		assert_equal expected, generated
		
		query = Query.new
		query.select(:s)
		query.where(:s, 'foaf:age', :a)
		query.where(:a, 'rdf:type', 'xsd:int')
		generated = Query2SPARQL.instance.translate(query)
		expected = "SELECT DISTINCT ?s WHERE { ?s foaf:age ?a. ?a rdf:type xsd:int .}"
		assert_equal expected, generated
		
		query = Query.new
		query.select(:s).select(:a)
		query.where(:s, 'foaf:age', :a)
		generated = Query2SPARQL.instance.translate(query)
		expected = "SELECT DISTINCT ?s ?a WHERE { ?s foaf:age ?a .}"
		assert_equal expected, generated
	end
	
	def test_query_omnipotent
		# can define multiple select clauses at once or separately
		q1 = Query.new.select(:s,:a)
		q2 = Query.new.select(:s).select(:a)
		assert_equal Query2SPARQL.instance.translate(q1),Query2SPARQL.instance.translate(q2)
	end
end