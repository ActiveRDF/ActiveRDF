# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'queryengine/query2sparql'
require "#{File.dirname(__FILE__)}/../common"

class TestQuery2Sparql < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_sparql_generation

    # TODO: write tests for distinct, ask

    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('predicate'), '30')

    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <predicate> \"30\" . }"
    assert_equal expected, generated

    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('foaf:age'), :a)
    query.where(:a, RDFS::Resource.new('rdf:type'), RDFS::Resource.new('xsd:int'))
    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <foaf:age> ?a. ?a <rdf:type> <xsd:int> . }"
    assert_equal expected, generated

    #		query = Query.new
    #		query.select(:s).select(:a)
    #		query.where(:s, 'foaf:age', :a)
    #		generated = Query2SPARQL.translate(query)
    #		expected = "SELECT DISTINCT ?s ?a WHERE { ?s foaf:age ?a .}"
    #		assert_equal expected, generated
  end

  def test_query_omnipotent
    # can define multiple select clauses at once or separately
    q1 = Query.new.select(:s,:a)
    q2 = Query.new.select(:s).select(:a)
    assert_equal Query2SPARQL.translate(q1),Query2SPARQL.translate(q2)
  end
  
  def test_sort
    q1 = Query.new.select(:s).sort(:s)
    q2 = Query.new.select(:s).sort(:s, :p, :o)
    q3 = Query.new.select(:s).reverse_sort(:s)
    q4 = Query.new.select(:s).reverse_sort(:s, :p, :o)
    q5 = Query.new.select(:s).sort(:s).reverse_sort(:p)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s)", Query2SPARQL.translate(q1)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s ?p ?o)", Query2SPARQL.translate(q2)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY DESC(?s)", Query2SPARQL.translate(q3)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY DESC(?s ?p ?o)", Query2SPARQL.translate(q4)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s) DESC(?p)", Query2SPARQL.translate(q5)
  end
  
  def test_execute_sort_query
    ConnectionPool.clear
    file_one = "#{File.dirname(__FILE__)}/../small-one.nt"
    adapter = get_adapter
    
    if (adapter.class.to_s != "SesameAdapter")
      adapter.load file_one
    else
      adapter.load(file_one, 'ntriples', one)
    end
    @eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    @eye = RDFS::Resource.new 'http://activerdf.org/test/eye'
    @eyal.eye = "green"
    assert_equal ["blue", "green"], Query.new.select(:o).where(@eyal, @eye, :o).sort(:o).execute
    assert_equal ["green", "blue"], Query.new.select(:o).where(@eyal, @eye, :o).reverse_sort(:o).execute
  end
end
