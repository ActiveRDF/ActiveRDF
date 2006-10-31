# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'active_rdf'
require 'test/unit'
require 'federation/federation_manager'
require 'queryengine/query'

class TestSparqlAdapter < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
    @adapter = ConnectionPool.add_data_source(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people/", :results => :sparql_xml)
  end

  def teardown
  end

  def test_registration
    assert_instance_of SparqlAdapter, @adapter
  end

  def test_simple_query
    result = Query.new.select(:s).where(:s, Namespace.lookup(:rdf,:type), :t).execute.first
    assert_instance_of RDFS::Resource, result

    second_result = Query.new.select(:s, :p).where(:s, :p, 27).execute.flatten
    assert_equal 2, second_result.size
    assert_instance_of RDFS::Resource, second_result[0]
    assert_instance_of RDFS::Resource, second_result[1]
  end

  def test_query_with_block
    # this has to be defined in front of the block, to afterwards verify that the contents of the
    # block were indeed executed
    reached_block = false

    Query.new.select(:s,:p).where(:s,:p, 27).execute do |s,p|
      reached_block = true
      assert_equal 'http://activerdf.org/test/eyal', s.uri
      assert_equal 'http://activerdf.org/test/age', p.uri
    end

    assert reached_block, "querying with a block does not work"
  end

  # TODO: move this to the query test cases
  def test_query_refuses_string_in_where_clause_subject_or_predicate
    assert_raises ActiveRdfError do
      Query.new.select(:s).where("http://test.org/uri",:p, :o).execute
    end
  end

  def test_refuse_to_write
    eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    # NameError gets thown if the method is unknown
    assert_raises NoMethodError do
      @adapter.add(eyal, age, test)
    end
  end

  def test_federated_query
    # we first ask one sparl endpoint
    first_size = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size
    ConnectionPool.clear

    # then we ask the second endpoint
    ConnectionPool.add_data_source(:type => :sparql, :url =>
    "http://www.m3pe.org:8080/repositories/mindpeople", :results => :sparql_xml)

    second_size = Query.new.select(:o).where(:s, :p, :o).execute(:flatten =>
    false).size

    ConnectionPool.clear

    # now we ask both
    ConnectionPool.add_data_source(:type => :sparql, :url =>
    "http://m3pe.org:8080/repositories/test-people/", :results => :sparql_xml)
    ConnectionPool.add_data_source(:type => :sparql, :url =>
    "http://www.m3pe.org:8080/repositories/mindpeople", :results => :sparql_xml)

    union_size = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size
    assert_equal first_size + second_size, union_size
  end

  def test_person_data
    eyal = RDFS::Resource.new("http://activerdf.org/test/eyal")
    eye = RDFS::Resource.new("http://activerdf.org/test/eye")
    type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
    age = RDFS::Resource.new("http://activerdf.org/test/age")
    person = RDFS::Resource.new("http://www.w3.org/2000/01/rdf-schema#Resource")
    resource = RDFS::Resource.new("http://activerdf.org/test/Person")

    color = Query.new.select(:o).where(eyal, eye,:o).execute
    assert 'blue', color
    assert_instance_of String, color

    age_result = Query.new.select(:o).where(eyal, age, :o).execute
    assert 27, age_result

    types_result = Query.new.select(:o).where(eyal, type, :o).execute
    assert types_result.include?(person)
    assert types_result.include?(resource)
  end
end
