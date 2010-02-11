# Authors:: Benjamin Heitmann, Karsten Huneycutt
# Copyright:: (c) 2007
# License:: LGPL

require 'test/unit'
require 'rubygems'

require "java"

require 'active_rdf'

require "pp"

require "fileutils"

class TestNG4JAdapter < Test::Unit::TestCase
  include ActiveRDF

  def setup
    @adapter = ConnectionPool.add_data_source(:type => :ng4j)
    @eyal = RDFS::Resource.new 'http://eyaloren.org'
    @age = RDFS::Resource.new 'foaf:age'
    @mbox = RDFS::Resource.new 'foaf:mbox'
    @test = RDFS::Resource.new 'test:test'
    @mboxval = Literal.new 'aahfgiouhfg'
    @ageval = Literal.new 23
    @context = RDFS::Resource.new "http://activerdf.org/test/named_graphs_rock"
    @context2 = RDFS::Resource.new "http://activerdf.org/test/named_graphs_rock2"
  end

  def teardown
    @adapter.close
    # ConnectionPool.clear
  end



  def test_load_no_args
    adapter = ConnectionPool.add_data_source(:type => :ng4j)
    assert_instance_of NG4JAdapter, adapter
  end


  def test_retrieve_a_triple_with_only_uris

    assert_instance_of NG4JAdapter, @adapter

    @adapter.add(@eyal, @age, @test)
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@eyal, @age, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @age, @test).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@eyal, :p, @test).execute
    assert_equal 1, result.flatten.size

  end

  def test_retrieve_a_triple_with_string

    assert_instance_of NG4JAdapter, @adapter

    @adapter.add(@eyal, @mbox, @mboxval)
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@eyal, @mbox, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @mbox, @mboxval).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@eyal, :p, @mboxval).execute
    assert_equal 1, result.flatten.size

  end

  def test_retrieve_a_triple_with_fixnum

    assert_instance_of NG4JAdapter, @adapter

    @adapter.add(@eyal, @age, @ageval)
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@eyal, @age, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @age, @ageval).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@eyal, :p, @ageval).execute
    assert_equal 1, result.flatten.size

  end

  def test_remove
    @adapter.add(@eyal, @age, @ageval)
    @adapter.add(@eyal, @mbox, @mboxval)
    @adapter.delete(@eyal, @age, @ageval)
    assert_equal 1, @adapter.size


    @adapter.add(@eyal, @age, @ageval)
    @adapter.add(@eyal, @mbox, @mboxval)
    @adapter.delete(:s, :p, @ageval)
    assert_equal 1, @adapter.size

    @adapter.add(@eyal, @age, @ageval)
    @adapter.add(@eyal, @mbox, @mboxval)
    @adapter.delete(:s, @age, :o)
    assert_equal 1, @adapter.size

    @adapter.add(@eyal, @age, @ageval)
    @adapter.add(@eyal, @mbox, @mboxval)
    @adapter.delete(@eyal, :p, :o)
    assert_equal 0, @adapter.size
  end

  # now tests with quads ----------------------------------------

  def test_simple_add_and_remove_quad_of_uris
    assert_equal 0, @adapter.size
    @adapter.add(@eyal, @mbox, @mboxval, @context)
    assert_equal 1, @adapter.size
    @adapter.delete(@eyal, @mbox, @mboxval, @context)
    assert_equal 0, @adapter.size
  end

  def test_wildcard_add_and_remove_quad_of_uris
    assert_equal 0, @adapter.size
    @adapter.add(@eyal, @mbox, @mboxval, @context)
    assert_equal 1, @adapter.size
    @adapter.add(@eyal, @mbox, @mboxval)
    assert_equal 2, @adapter.size
    @adapter.delete(:s, :p, :o, @context)
    assert_equal 1, @adapter.size
    @adapter.add(@eyal, @mbox, @mboxval, @context2)
    assert_equal 2, @adapter.size
    @adapter.add(@eyal, @mbox, @mboxval, @context)
    assert_equal 3, @adapter.size
    @adapter.delete(@eyal, @mbox, @mboxval)
    assert_equal 2, @adapter.size
    @adapter.delete(@eyal, @mbox, @mboxval, :c)
    assert_equal 0, @adapter.size
  end

  def test_query_with_quads
    lit1 = Literal.new(1)
    lit2 = Literal.new("cat", "@en")
    lit3 = Literal.new( "dog" , RDFS::Resource.new("http://www.w3.org/2001/XMLSchema#string"))
    # TODO: if this is ..#stringy then it gets returned as ..#string. Whats happening there?

    @adapter.add(@eyal, @mbox, lit1, @context)
    @adapter.add(@eyal, @mbox, lit2, @context2)
    @adapter.add(@eyal, @mbox, lit3)
    assert_equal 3, @adapter.size

    res1 = Query.new.distinct(:o).where(@eyal, @mbox, :o, @context).execute(:flatten => true)
    assert_equal lit1.value, res1.value
    assert_equal lit1.type.uri, res1.type.uri

    res2 = Query.new.distinct(:o).where(@eyal, @mbox, :o, @context2).execute(:flatten => true)
    assert_equal lit2.value, res2.value
    assert_equal lit2.language, res2.language

    res3 = Query.new.distinct(:o).where(@eyal, @mbox, :o).execute(:flatten => true)
    assert_equal 3, res3.size

    res4 = Query.new.distinct(:c).where(@eyal, @mbox, :o, :c).execute(:flatten => true)
    assert_equal 3, res4.size

    res5 = Query.new.distinct(:o).where(@eyal, @mbox, :o, :c).execute(:flatten => true)
    assert_equal 3, res5.size
  end

  # -------------------------------------------------------------


  def test_dump
    @adapter.add(@eyal, @age, @test)

    stringDump = @adapter.dump

    assert_not_nil stringDump
    assert_kind_of String, stringDump
  end

  def test_size
    @adapter.add(@eyal, @age, @test)

    assert 0 < @adapter.size
  end

  def test_clear
    @adapter.add(@eyal, @age, @test)
    assert 0 < @adapter.size

    @adapter.clear
    assert_equal 0, @adapter.size
  end


  # may seem redundant, but nonetheless this is needed
  # TODO: find out why this does not raise errors..
  def test_close

    @adapter.close

    my_adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs)
    my_adapter.add(@eyal, @age, @test)
    results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    assert results.flatten.size > 0

    my_adapter.close
    # assert_raises ActiveRdfError do
    #   results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    # end

    my_adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs)
    my_adapter.add(@eyal, @age, @test)
    results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    assert results.flatten.size > 0

    my_adapter.close
    # assert_raises ActiveRdfError do
    #   results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    # end
  end


  def test_load_ntriples
    assert_equal 0, @adapter.size

    this_dir = File.dirname(File.expand_path(__FILE__))
    @adapter.load("file://" + this_dir + "/eyal-foaf.nt", :format => :ntriples, :into => :default_model)

    assert_not_equal 0, @adapter.size

    #check for <https://launchpad.net/products/browserdf/+rdf> <http://xmlns.com/foaf/0.1/name> "BrowseRDF" .
    project_browserdf = RDFS::Resource.new("https://launchpad.net/products/browserdf/+rdf")
    foaf_name = RDFS::Resource.new("http://xmlns.com/foaf/0.1/name")
    result = Query.new.distinct(:o).where(project_browserdf, foaf_name, :o).execute
    assert_equal 1, result.flatten.size
    assert_equal "BrowseRDF", result[0].value
  end

  def test_load_rdf_xml
    assert_equal 0, @adapter.size

    this_dir = File.dirname(File.expand_path(__FILE__))
    @adapter.load("file://" + this_dir + "/bnode_org_rss.rdf", :format => :rdfxml, :into => :default_model)

    assert_not_equal 0, @adapter.size

    a_post = RDFS::Resource.new("http://bnode.org/blog/2007/05/29/semantic-web-gets-a-mention-in-visual-x-mag-webinale-report")
    rss_title = RDFS::Resource.new("http://purl.org/rss/1.0/title")

    result = Query.new.distinct(:o).where(a_post, rss_title, :o).execute
    assert_equal 1, result.flatten.size
    assert_equal "Semantic Web gets a mention in Visual-x mag webinale report", result[0].value
  end

  def test_load_n3
    assert_equal 0, @adapter.size

    this_dir = File.dirname(File.expand_path(__FILE__))
    @adapter.load("file://" + this_dir + "/s1.n3", :format => :n3)
    #:into => :default_model)

    assert_not_equal 0, @adapter.size

    transy = RDFS::Resource.new("http://www.daml.org/2001/03/daml+oil#TransitiveProperty")
    rdf_type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
    result = Query.new.distinct(:s, :c).where(:s, rdf_type, transy, :c).execute
    assert_equal 6, result.flatten.size

    result2 = Query.new.distinct(:s).where(:s, rdf_type, transy).execute
    assert_equal 3, result2.flatten.size
  end

  def test_keyword_search
   @adapter.close

   this_dir = File.dirname(File.expand_path(__FILE__))
   keyword_adapter = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :lucene => true)

   keyword_adapter.load("file://" + this_dir + "/test_data.nt", :format => :ntriples, :into => :default_model )

   eyal = RDFS::Resource.new('http://activerdf.org/test/eyal')

   assert keyword_adapter.keyword_search?

   assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"blue").execute(:flatten => true)
   assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"27").execute(:flatten => true)
   assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"eyal oren").execute(:flatten => true)

   keyword_adapter.close
  end

  def test_hsql_embedded_persistence
    @adapter.close
    this_dir = File.dirname(File.expand_path(__FILE__))

    hsql1 = ConnectionPool.add_data_source(:type => :ng4j,
      :database => {:url => "jdbc:hsqldb:file:/" + this_dir + "/db1", :type => "hsql", :username => "sa", :password => ""})

    hsql1.add(@eyal, @age, @ageval)
    hsql1.add(@eyal, @mbox, @mboxval)

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    hsql1.close
    ConnectionPool.clear

    hsql2 = ConnectionPool.add_data_source(:type => :ng4j, :id => "2",
      :database => {:url => "jdbc:hsqldb:file:/" + this_dir + "/db1", :type => "hsql", :username => "sa", :password => ""})

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    hsql2.close

    # begin
    #   java.sql.DriverManager.getConnection("jdbc:derby:;shutdown=true")
    # rescue java.sql.SQLException
    #   # expected
    # end
    # FileUtils.rm_rf(this_dir + "/superfunky")
  end


  # def test_explore_sparql
  #   puts Query2SPARQL.translate(Query.new.distinct(:s).
  #       where(:s, :p, :o, RDFS::Resource.new("http://penny-arcade.com/funky")).
  #       where(:s, :p, @mboxval, RDFS::Resource.new("http://penny-arcade.com/funky")).
  #       where(:s, :p, @mboxval)
  #       )
  # end

end
