# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require "rubygems"
require 'active_rdf'
require 'test/unit'
require 'federation/federation_manager'
require 'queryengine/query'


class TestSparqlAdapter < Test::Unit::TestCase
  include ActiveRDF

  def setup
    ConnectionPool.clear
    @adapter = ConnectionPool.add(:type => :sparql, :url => 'http://dbpedia.org/sparql', :engine => :virtuoso)
  end

  def teardown
  end

  def test_registration
    assert_instance_of SparqlAdapter, @adapter
  end

  def test_language
    sunset = RDFS::Resource.new("http://dbpedia.org/resource/77_Sunset_Strip")
    abstract = RDFS::Resource.new("http://dbpedia.org/property/abstract")

    german = Query.new.distinct(:o).where(sunset,abstract,:o).limit(1).lang(:o,'de').execute.first
    english = Query.new.distinct(:o).where(sunset,abstract,:o).limit(1).lang(:o,'en').execute.first

    assert english =~ /^77 Sunset Strip is the first hour-length private detective series in American television history/
    assert german =~ /^77 Sunset Strip ist ein Serienklassiker aus den USA um das gleichnamige, in Los Angeles am Sunset Boulevard angesiedelte Detektivbüro/
  end

  def test_limit_offset
    one = Query.new.select(:s).where(:s,:p,:o).limit(10).execute
    assert_equal 10, one.size

    one.all? do |r|
      assert_instance_of RDFS::Resource, r
    end

    two = Query.new.select(:s).where(:s,:p,:o).limit(10).offset(1).execute
    assert_equal 10, two.size
    assert_equal one[1], two[0]

    three = Query.new.select(:s).where(:s,:p,:o).limit(10).offset(0).execute
    assert_equal one, three
  end

  def test_regex_filter
    Namespace.register :yago, 'http://dbpedia.org/class/yago/'
    Namespace.register :dbpedia, 'http://dbpedia.org/property/'
    Namespace.register :dbresource, 'http://dbpedia.org/resource/'

    movies = Query.new.
      distinct(:title).
      where(DBRESOURCE::Kill_Bill, RDFS.label, :title).
      filter_regex(:title, /^Kill/).limit(10).execute

    assert !movies.empty?, "regex query returns empty results"
    assert movies.all? {|m| m =~ /^Kill/ }, "regex query returns wrong results"
  end

  def test_query_with_block
    reached_block = false
    Query.new.select(:s, :p).where(:s,:p,:o).limit(1).execute do |s, p|
      reached_block = true
      assert_equal RDFS::Resource, s.class
      assert_equal RDFS::Resource, p.class
    end
    assert reached_block, "querying with a block does not work"

    reached_block = false
    Query.new.select(:s, :p).where(:s,:p,:o).limit(3).execute do |s, p|
      reached_block = true
      assert_equal RDFS::Resource, s.class
      assert_equal RDFS::Resource, p.class
    end
    assert reached_block, "querying with a block does not work"

    reached_block = false
    Query.new.select(:s).where(:s,:p,:o).limit(3).execute do |s|
      reached_block = true
      assert_equal RDFS::Resource, s.class
    end

    assert reached_block, "querying with a block does not work"
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

  def test_literal_conversion
    # test literal conversion
    label = Query.new.distinct(:label).where(:s, RDFS::label, :label).limit(1).execute(:flatten)
    assert_instance_of String, label
  end
end
