# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'test_helper'

class TestQuery2Sparql < Test::Unit::TestCase

  def test_sparql_generation
    # TODO: write tests for distinct, ask

    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('predicate'), 30)

    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <predicate> \"30\"^^<http://www.w3.org/2001/XMLSchema#integer> . } "
    assert_equal expected, generated

    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('foaf:age'), :a)
    query.where(:a, RDFS::Resource.new('rdf:type'), RDFS::Resource.new('xsd:int'))
    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <foaf:age> ?a . ?a <rdf:type> <xsd:int> . } "
    assert_equal expected, generated
  end

  def test_sparql_distinct
    query = Query.new
    query.distinct(:s)
    query.where(:s, RDFS::Resource.new('foaf:age'), :a)
    generated = Query2SPARQL.translate(query)
    expected = "SELECT DISTINCT ?s WHERE { ?s <foaf:age> ?a . } "
    assert_equal expected, generated
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
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s) ", Query2SPARQL.translate(q1)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s) ASC(?p) ASC(?o) ", Query2SPARQL.translate(q2)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY DESC(?s) ", Query2SPARQL.translate(q3)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY DESC(?s) DESC(?p) DESC(?o) ", Query2SPARQL.translate(q4)
    assert_equal "SELECT ?s WHERE {  . } ORDER BY ASC(?s) DESC(?p) ", Query2SPARQL.translate(q5)
  end
  
  def test_execute_sort_query
    ConnectionPool.clear
    file_one = "#{File.dirname(__FILE__)}/../small-one.nt"
    adapter = get_default_primary_adapter
    
    if (adapter.class.to_s != "SesameAdapter")
      adapter.load file_one
    else
      adapter.load(file_one, 'ntriples')
    end
    @eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    @eye = RDFS::Resource.new 'http://activerdf.org/test/eye'
    @eyal[@eye] << 'green'
    assert_equal ["blue", "green"], Query.new.select(:o).where(@eyal, @eye, :o).limit(100).sort(:o).execute
    assert_equal ["green", "blue"], Query.new.select(:o).where(@eyal, @eye, :o).limit(100).reverse_sort(:o).execute
  end
end
