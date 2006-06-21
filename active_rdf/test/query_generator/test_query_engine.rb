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

  ## TODO: write query engine tests

	def setup	 
		setup_any
#		@rdfs_subclass = NamespaceFactory.get :rdfs_subclass
#		@rdf_type = NamespaceFactory.get :rdf_type
#		@res_publication = NodeFactory.create_basic_resource 'http://m3pe.org/activerdf/citeseer#Publication'
	end
	
#	def test_A_generate_sparql
#		qe = QueryEngine.new
#		qe.add_condition(:s, :p, :o)
#		qe.add_binding_variables(:s)
#		assert_nothing_raised { qe.generate_sparql }
#	end
#
#	def test_B_generate_ntriples
#		qe = QueryEngine.new
#		
#		assert_not_nil(qe)
#		
#		qe.add_binding_triple(:s, :p, :o)
#		qe.add_condition(:x, @rdfs_subclass, @res_publication)
#		qe.add_condition(:s, @rdf_type, :x)
#		qe.add_condition(:s, :p, :o)
#		
#		str_query = qe.generate_ntriples
#		query_waiting = <<QUERY_END
#@prefix ql: <http://www.w3.org/2004/12/ql#> . 
#<> ql:select {
#?s ?p ?o .
#}; 
#ql:where {
#	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf>  <http://m3pe.org/activerdf/citeseer#Publication> . 
#	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>  ?x . 
#	 ?s ?p  ?o . 
#} .
#
#QUERY_END
#		
#		assert_equal(query_waiting, str_query)
#	end
#
#	def test_C_count_sparql
#		qe = QueryEngine.new
#		qe.add_counting_variable :s
#		qe.add_condition :s, :p, :o
#		assert_raise(WrongTypeQueryError) { qe.generate_sparql }
#	end
#
#	def test_D_count_yars
#		qe = QueryEngine.new
#		qe.add_counting_variable :s
#		qe.add_condition :s, :p, :o
#		assert_nothing_raised { qe.generate_ntriples }
#	end
#	
#	def test_E_generate_sparql
#		qe = QueryEngine.new
#		
#		qe.add_binding_variables(:s, :p, :o)
#		qe.add_condition(:x, @rdfs_subclass, @res_publication)
#		qe.add_condition(:s, @rdf_type, :x)
#		qe.add_condition(:s, :p, :o)
#		
#		str_query = qe.generate_sparql
#
#		query_waiting = <<QUERY_END
#SELECT ?s ?p ?o 
#
#WHERE {
#	 ?x <http://www.w3.org/2000/01/rdf-schema#subClassOf> <http://m3pe.org/activerdf/citeseer#Publication> . 
#	 ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?x . 
#	 ?s ?p ?o
#}
#
#QUERY_END
#		
#		assert_equal(query_waiting, str_query)
#
#	end
#
#	def test_F_execute_ntriples
#		qe = QueryEngine.new
#		
#		assert_not_nil(qe)
#		
#		qe.add_binding_triple(:s, @rdf_type, :x)
#		qe.add_condition(:x, @rdfs_subclass, @res_publication)
#		qe.add_condition(:s, @rdf_type, :x)
#		
#		
#		results = qe.execute
#		assert_not_nil(results)
##		assert_equal(11, results.size)
##		
#		qe.add_binding_triple(:s, :p, :o)
#		qe.add_condition(:x, @rdfs_subclass, @res_publication)
#		qe.add_condition(:s, @rdf_type, :x)
#		qe.add_condition(:s, :p, :o)
#		assert_nothing_raised { qe.execute }
##		
##		
##		results = qe.execute
##		assert_not_nil(results)
##		assert_equal(97, results.size)
#	end
#
#	def test_G_count_results
#		qe = QueryEngine.new
#		qe.add_condition :s, :p, :o
#		qe.add_counting_variable :s
#		result = qe.execute
#		assert_kind_of(Integer, result)
#	end
	
	def test_H_keyword_search
		qe = QueryEngine.new
		qe.add_binding_triple(:s, :p, :o)
		qe.add_condition(:s, :p, :o)
		qe.add_keyword(:o, 'Bernhard')
		
		query_waiting = <<END_OF_STRING
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

		assert_equal(query_waiting, qe.generate_ntriples)
	end
	
#	def test_I_keyword_search
#		qe = QueryEngine.new
#		qe.add_binding_triple(:s, :p, :o)
#		qe.add_condition(:s, :p, :o)
#		qe.add_keyword(:o, 'Bernhard')
#		
#		results = qe.execute
#		assert_not_nil(results)
#		assert_equal(30, results.size)
#	end
	

end
