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

  # TODO: supports no contexts

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
  
  def test_load
    # fill in
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
  
  def test_persistence
    # fill in
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
  
  # def test_anynode
  #   include_class("com.hp.hpl.jena.graph.Node")
  #   
  #   a = Jena::Node.create("??")
  # 
  #   puts "the any node: #{a.inspect}"
  # end

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
