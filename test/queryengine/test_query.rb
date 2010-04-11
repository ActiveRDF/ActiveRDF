# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'test_helper'

class TestQuery < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_sparql_generation
    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('predicate'), '30')
    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <predicate> \"30\" . } "
    assert_equal expected, generated

    query = Query.new
    query.select(:s)
    query.where(:s, RDFS::Resource.new('foaf:age'), :a)
    query.where(:a, RDFS::Resource.new('rdf:type'), RDFS::Resource.new('xsd:int'))
    generated = Query2SPARQL.translate(query)
    expected = "SELECT ?s WHERE { ?s <foaf:age> ?a. ?a <rdf:type> <xsd:int> . } "
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

	def test_query_refuses_string_in_where_clause_subject_or_predicate
    assert_raises(ActiveRdfError)do
      Query.new.select(:s).where("http://test.org/uri",:p, :o).execute
    end
  end
end
