# = test_query_engine.rb
#
# Unit test for the query generator
#
# == Project
#
# * ActiveRDF
# * http://m3pe.org/activerdf/
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved

require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'

class TestQueryEngine < Test::Unit::TestCase
	def setup	 
		setup_any
		@rdfs_subclass = NamespaceFactory.get :rdfs, :subClassOf
		@rdf_type = NamespaceFactory.get :rdf, :type
		@publication = NodeFactory.create_basic_resource 'http://m3pe.org/activerdf/citeseer#Publication'
	end
	
	def test_generate_sparql
		qe = QueryEngine.new
		qe.add_binding_variables :s
		qe.add_condition :s, :p, :o
		query = "SELECT DISTINCT ?s \n\nWHERE {\n\t ?s ?p ?o\n}\n\n"
		assert_equal query, qe.generate_sparql
	end

	def test_generate_ntriples
		qe = QueryEngine.new
		qe.add_binding_variables :s
		qe.add_condition :s, :p, :o
		query = "@prefix yars: <http://sw.deri.org/2004/06/yars#> .\n@prefix ql: <http://www.w3.org/2004/12/ql#> . \n<> ql:distinct {\n ( ?s ) .\n}; \nql:where {\n\t ?s ?p ?o . \n\n} .\n\n"
		assert_equal query, qe.generate_ntriples
	end

	def test_generate_using_condition
		qe = QueryEngine.new
		qe.add_binding_variables :s, :p, :o
		qe.add_condition :x, @rdfs_subclass, @publication
		qe.add_condition :s, @rdf_type, :x
		qe.add_condition :s, :p, :o
		
		query_nt = "@prefix yars: <http://sw.deri.org/2004/06/yars#> .\n@prefix ql: <http://www.w3.org/2004/12/ql#> . \n<> ql:distinct {\n ( ?s ?p ?o ) .\n}; \nql:where {\n\t ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://m3pe.org/activerdf/citeseer#Publication> . \n\t ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?x . \n\t ?s ?p ?o . \n\n} .\n\n"
		
		assert_equal query_nt, qe.generate_ntriples
		
		query_sparql = <<EOF
SELECT DISTINCT ?s ?p ?o 

WHERE {
	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://m3pe.org/activerdf/citeseer#Publication> . 
	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?x . 
	 ?s ?p ?o
}

EOF
		assert_equal query_sparql, qe.generate_sparql
	end

	def test_count_sparql
		qe = QueryEngine.new
		qe.add_counting_variable :s
		qe.add_condition :s, :p, :o
		assert_raise(ActiveRdfError) { qe.generate_sparql }
		
		query = "@prefix yars: <http://sw.deri.org/2004/06/yars#> .\n@prefix ql: <http://www.w3.org/2004/12/ql#> . \n<> ql:distinct {\n ( ?s ) .\n}; \nql:where {\n\t ?s ?p ?o . \n\n} .\n\n"
		assert_equal query, qe.generate_ntriples
	end
	

	def test_keyword_search
		qe = QueryEngine.new
		qe.add_binding_triple(:s, :p, :o)
		qe.add_condition(:s, :p, :o)
		qe.add_keyword(:o, 'Bernhard')
		
		query = <<END_OF_STRING
@prefix yars: <http://sw.deri.org/2004/06/yars#> .
@prefix ql: <http://www.w3.org/2004/12/ql#> . 
<> ql:distinct {
?s ?p ?o .
}; 
ql:where {
	 ?s ?p ?o . 
	 ?o yars:keyword "Bernhard" . 

} .

END_OF_STRING

		assert_equal(query, qe.generate_ntriples)
	end
end
