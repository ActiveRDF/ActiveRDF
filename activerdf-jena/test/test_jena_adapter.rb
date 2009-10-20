# Authors:: Benjamin Heitmann, Karsten Huneycutt
# Copyright:: (c) 2007
# License:: LGPL

require 'test/unit'
require 'rubygems'

require "java"

require 'active_rdf'

require "pp"

require "fileutils"

class TestJenaAdapter < Test::Unit::TestCase
  include ActiveRDF

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
    Dir.mkdir(this_dir + "/jena_persistence")
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
    FileUtils.rm_rf(this_dir + "/jena_persistence")
  end

  def test_persistence_file_based_named_model
    @adapter.close

    this_dir = File.dirname(File.expand_path(__FILE__))
    Dir.mkdir(this_dir + "/jena_persistence")
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
    FileUtils.rm_rf(this_dir + "/jena_persistence")
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

  def test_derby_embedded_persistence
    @adapter.close
    this_dir = File.dirname(File.expand_path(__FILE__))

    derby1 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky",
                                            :database => {:url => "jdbc:derby:#{this_dir}/superfunky;create=true", :type => "Derby", :username => "", :password => ""})

    derby1.add(@eyal, @age, @ageval)
    derby1.add(@eyal, @mbox, @mboxval)

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    derby1.close
    ConnectionPool.clear

    derby2 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :id => "2",
                                            :database => {:url => "jdbc:derby:#{this_dir}/superfunky;create=true", :type => "Derby", :username => "", :password => ""})

    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    derby2.close

    begin
      java.sql.DriverManager.getConnection("jdbc:derby:;shutdown=true")
    rescue java.sql.SQLException
      # expected
    end
    FileUtils.rm_rf(this_dir + "/superfunky")
  end

  def test_querying_bnodes
    this_dir = File.dirname(File.expand_path(__FILE__))
    @adapter.load("file://" + this_dir + "/fun_with_bnodes.nt", :format => :ntriples, :into => :default_model)

    res1 = Array(Query.new.select(:s).where(:s, RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDFS::Resource.new("http://xmlns.com/foaf/0.1/Person")).execute)
    assert_equal 1, res1.size
    bn1 = res1.first

    res2 = Array(Query.new.select(:s).where(:s, :p, RDFS::Resource.new("http://wordpress.org")).execute)
    assert_equal 1, res2.size
    bn2 = res2.first

    assert_equal bn1, bn2

    res3 = Array(Query.new.select(:o).where(bn1, :p, :o).execute)
    assert_equal 2, res3.size

    res4 = Array(Query.new.select(:p).where(bn1, :p, RDFS::Resource.new("http://wordpress.org") ).execute)
    assert_equal 1, res4.size

  end


  # TODO: NOT TESTED until now, run this against a local mysql installation to confirm it
  def test_mysql_persistence
    # @adapter.close
    #
    # mysql1 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :id => "1",
    #   :database => {:url => "jdbc:postgresql://MyDbComputerNameOrIP/myDatabaseName;create=true", :type => "MySQL", :username => "theUser", :password => "thepassword"})
    #
    #     mysql1.add(@eyal, @age, @ageval)
    #     mysql1.add(@eyal, @mbox, @mboxval)
    #
    #     result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    #     assert_equal 2, result.flatten.size
    #
    #     mysql1.close
    #     ConnectionPool.clear
    #
    # mysql2 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :id => "2",
    #   :database => {:url => "jdbc:mysql://MyDbComputerNameOrIP/myDatabaseName;create=true", :type => "MySQL", :username => "theUser", :password => "thepassword"})
    #
    #     result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    #     assert_equal 2, result.flatten.size
    #
    #     mysql2.close
    #     this_dir = File.dirname(File.expand_path(__FILE__))
    #     #FileUtils.remove_dir(this_dir + "/superfunky")
  end

  # TODO: NOT TESTED until now, run this against a local postgres installation to confirm it
  def test_postgres_embedded_persistence
    # @adapter.close
    #
    # postgres1 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :id => "1",
    #   :database => {:url => "jdbc:postgresql://MyDbComputerNameOrIP/myDatabaseName;create=true", :type => "PostgreSQL", :username => "theUser", :password => "thepassword"})
    #
    #     postgres1.add(@eyal, @age, @ageval)
    #     postgres1.add(@eyal, @mbox, @mboxval)
    #
    #     result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    #     assert_equal 2, result.flatten.size
    #
    #     postgres1.close
    #     ConnectionPool.clear
    #
    # postgres2 = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :id => "2",
    #   :database => {:url => "jdbc:postgresql://MyDbComputerNameOrIP/myDatabaseName;create=true", :type => "PostgreSQL", :username => "theUser", :password => "thepassword"})
    #
    #     result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    #     assert_equal 2, result.flatten.size
    #
    #     postgres2.close
    #     this_dir = File.dirname(File.expand_path(__FILE__))
    #     #FileUtils.remove_dir(this_dir + "/superfunky")
  end





  def test_contexts
    # TODO
  end

  # TODO: querying pellet does not work right now
  def test_search_with_pellet
    @adapter.close

    this_dir = File.dirname(File.expand_path(__FILE__))
    adapter = ConnectionPool.add_data_source(:type => :jena, :model => "superfunky", :lucene => true,
                                             :reasoner => :pellet, :ontology => :owl)

    adapter.load("file://" + this_dir + "/test_data.nt", :format => :ntriples, :into => :default_model )

    eyal = RDFS::Resource.new('http://activerdf.org/test/eyal')

    # Keyword with pellet does not work.
    #    assert adapter.keyword_search?
    #    assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"blue").execute(:flatten => true)
    #    assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"27").execute(:flatten => true)
    #    assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"eyal oren").execute(:flatten => true)

    adapter.close
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
