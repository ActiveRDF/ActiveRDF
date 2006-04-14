require 'test/unit'
require 'active_rdf'

class TestQueryEngine < Test::Unit::TestCase

	def setup	 
		$logger.level = Logger::DEBUG
		NodeFactory.connection :adapter => :yars, :host => 'opteron', :context => 'great-buildings'
		@rdfs_subclass = NamespaceFactory.get :rdfs_subclass
		@rdf_type = NamespaceFactory.get :rdf_type
		@res_publication = NodeFactory.create_basic_resource 'http://m3pe.org/activerdf/citeseer#Publication'
	end
	
	def test_generate_sparql
		qe = QueryEngine.new
		qe.add_condition(:s, :p, :o)
		qe.add_binding_variables(:s)
		assert_nothing_raised { qe.generate_sparql }
	end

	def test_1_generate_ntriples
		qe = QueryEngine.new
		
		assert_not_nil(qe)
		
		qe.add_binding_triple(:s, :p, :o)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		qe.add_condition(:s, :p, :o)
		
		str_query = qe.generate_ntriples
		query_waiting = <<QUERY_END
@prefix ql: <http://www.w3.org/2004/12/ql#> . 
<> ql:select {
?s ?p ?o .
}; 
ql:where {
	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf>  <http://m3pe.org/activerdf/citeseer#Publication> . 
	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>  ?x . 
	 ?s ?p  ?o . 
} .

QUERY_END
		
		assert_equal(query_waiting, str_query)
	end

	def test_count_sparql
		qe = QueryEngine.new
		qe.add_counting_variable :s
		qe.add_condition :s, :p, :o
		assert_raise(WrongTypeQueryError) { qe.generate_sparql }
	end

	def test_count_yars
		qe = QueryEngine.new
		qe.add_counting_variable :s
		qe.add_condition :s, :p, :o
		assert_nothing_raised { qe.generate_ntriples }
	end
	
	def test_2_generate_sparql
		qe = QueryEngine.new
		
		qe.add_binding_variables(:s, :p, :o)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		qe.add_condition(:s, :p, :o)
		
		str_query = qe.generate_sparql

		query_waiting = <<QUERY_END
SELECT ?s ?p ?o 

WHERE {
	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://m3pe.org/activerdf/citeseer#Publication> . 
	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?x . 
	 ?s ?p ?o
}

QUERY_END
		
		assert_equal(query_waiting, str_query)

	end

	def test_3_execute_ntriples
		qe = QueryEngine.new
		
		assert_not_nil(qe)
		
		qe.add_binding_triple(:s, @rdf_type, :x)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		
		
		results = qe.execute
		assert_not_nil(results)
#		assert_equal(11, results.size)
#		
		qe.add_binding_triple(:s, :p, :o)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		qe.add_condition(:s, :p, :o)
		assert_nothing_raised { qe.execute }
#		
#		
#		results = qe.execute
#		assert_not_nil(results)
#		assert_equal(97, results.size)
	end

	def test_count_results
		qe = QueryEngine.new
		qe.add_condition :s, :p, :o
		qe.add_counting_variable :s
		result = qe.execute
		assert_kind_of(Integer, result)
	end
	
end
