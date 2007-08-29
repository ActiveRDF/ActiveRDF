# Authors:: Benjamin Heitmann, Karsten Huneycutt
# Copyright:: (c) 2007
# License:: LGPL

require 'test/unit'
require 'rubygems'

require "java"

require 'active_rdf'

require "pp"

class TestJenaAdapter < Test::Unit::TestCase

  def setup 
    @adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs)
    @eyal = RDFS::Resource.new 'http://eyaloren.org'
    @age = RDFS::Resource.new 'foaf:age'
    @mbox = RDFS::Resource.new 'foaf:mbox'
    @test = RDFS::Resource.new 'test:test'
    @mboxval = Literal.new 'aahfgiouhfg'
    @ageval = Literal.new 23
  end

  def teardown
    @adapter.close
    # ConnectionPool.clear
  end
  
  
  
  def test_load_no_args
    adapter = ConnectionPool.add_data_source(:type => :jena)
    assert_instance_of JenaAdapter, adapter
  end
  
  def test_with_args_no_location
    assert_instance_of JenaAdapter, @adapter
  end
  
  def test_retrieve_a_triple_with_only_uris
  
    assert_instance_of JenaAdapter, @adapter
    
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
  
    assert_instance_of JenaAdapter, @adapter
  
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
  
    assert_instance_of JenaAdapter, @adapter
  
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
  def test_close    
    my_adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs)
    my_adapter.add(@eyal, @age, @test)
    results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    assert results.flatten.size > 0
    
    my_adapter.close
    assert_raises ActiveRdfError do
      results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    end
  
    my_adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs)
    my_adapter.add(@eyal, @age, @test)
    results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    assert results.flatten.size > 0
    
    my_adapter.close
    assert_raises ActiveRdfError do
      results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    end
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
    assert_equal "BrowseRDF", result[0]
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
    assert_equal "Semantic Web gets a mention in Visual-x mag webinale report", result[0]
  end

  def test_load_n3
    assert_equal 0, @adapter.size
    
    this_dir = File.dirname(File.expand_path(__FILE__))
    @adapter.load("file://" + this_dir + "/s1.n3", :format => :n3, :into => :default_model)
    
    assert_not_equal 0, @adapter.size
    
    transy = RDFS::Resource.new("http://www.daml.org/2001/03/daml+oil#TransitiveProperty")
    rdf_type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
    result = Query.new.distinct(:s).where(:s, rdf_type, transy).execute
    
    assert_equal 3, result.flatten.size    
  end
  
  def test_persistence_file_based_anonymous
    @adapter.close 
    
    this_dir = File.dirname(File.expand_path(__FILE__))
    persistent_adapter = ConnectionPool.add_data_source(:type => :jena,
     :file => this_dir + "/jena_persistence")
    assert_equal 0, persistent_adapter.size
    
    persistent_adapter.add(@eyal, @age, @ageval)
    persistent_adapter.add(@eyal, @mbox, @mboxval)
    
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    persistent_adapter.close
    ConnectionPool.clear

    adapter2 = ConnectionPool.add_data_source(:type => :jena,
     :file => this_dir + "/jena_persistence")

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    adapter2.close    
    File.delete(this_dir + "/jena_persistence/default")    
  end

  def test_persistence_file_based_named_model
    @adapter.close 
    
    this_dir = File.dirname(File.expand_path(__FILE__))
    persistent_adapter = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky",
     :file => this_dir + "/jena_persistence")
    assert_equal 0, persistent_adapter.size
    
    persistent_adapter.add(@eyal, @age, @ageval)
    persistent_adapter.add(@eyal, @mbox, @mboxval)
    
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    persistent_adapter.close
    ConnectionPool.clear

    adapter2 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky",
     :file => this_dir + "/jena_persistence")

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    adapter2.close    
    File.delete(this_dir + "/jena_persistence/superfunky")    
  end

  
  def test_database_persistence
    # TODO: fill in
    # what to check ? mysql and postgresql and maybe some java embedded thing? 
  end

  def test_contexts
    # TODO
  end

  def test_keyword_query
    # TODO
  end  

  # TODO: need a better understanding of rdfs reasoning in Jena before I can write a test for it
  # def test_rdfs_reasoning
  #   adapter_rdfs = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs, :reasoner => :rdfs)
  # 
  #   adapter_rdfs.add(@eyal, @age, @test)
  #   result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
  #   assert_equal 2, result.flatten.size
  #   adapter_rdfs.close
  # end

end
