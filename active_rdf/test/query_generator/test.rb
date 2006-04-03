

require 'test/unit'

require 'active_rdf'

class TestQueryEngine < Test::Unit::TestCase



	def setup	 
		@rdfs_subclass = Resource.create('http://www.w3.org/2000/01/rdf-schema#subClassOf', false)
		@rdf_type = Resource.create('http://www.w3.org/1999/02/22-rdf-syntax-ns#type', false)
		@res_publication = Resource.create('http://m3pe.org/activerdf/citeseer#Publication', false)
		@yars = Resource.establish_connection({	:adapter 	=> :yars,
												:host 		=> 'opteron',
												:port 		=> 8080,
												:context 	=> '/citeseer' })
	end

	def test_1_generate_ntriples
		qe = QueryEngine.new(@yars)
		
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
	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://m3pe.org/activerdf/citeseer#Publication> . 
	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?x . 
	 ?s ?p ?o .
} .

QUERY_END
		
		assert_equal(query_waiting, str_query)

		$stdout << str_query << "\n"
	end
	
	def test_2_generate_sparql
		qe = QueryEngine.new(@yars)
		
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

		$stdout << str_query << "\n"
	end

	def test_3_execute_ntriples
		qe = QueryEngine.new(@yars)
		
		assert_not_nil(qe)
		
		qe.add_binding_triple(:s, @rdf_type, :x)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		
		$stdout << qe.generate_ntriples << "\n"
		
		results = qe.execute
		assert_not_nil(results)
		assert_equal(11, results.size)
		
		qe.add_binding_triple(:s, :p, :o)
		qe.add_condition(:x, @rdfs_subclass, @res_publication)
		qe.add_condition(:s, @rdf_type, :x)
		qe.add_condition(:s, :p, :o)
		
		$stdout << qe.generate_ntriples << "\n"
		
		results = qe.execute
		assert_not_nil(results)
		assert_equal(97, results.size)
	end
	
end
