# Author:: Benjamin Heitmann
# Copyright:: (c) 2007
# License:: LGPL

require 'test/unit'
require 'rubygems'

require "java"

require 'active_rdf'

require "pp"

class TestSesameAdapter < Test::Unit::TestCase

  def setup 
    @adapter = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs, :reasoner => :rdfs, :lucene => true)
    @eyal = RDFS::Resource.new 'http://eyaloren.org'
    @age = RDFS::Resource.new 'foaf:age'
    @test = RDFS::Resource.new 'test:test'
  end

  # TODO: does not support anything except uris
  # TODO: supports no contexts
  # TODO: close is undefined...
  # TODO: adapter clear is undefined

  def teardown
    #adapter.close
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

    # @adapter.clear
    # assert_equal 0, @adapter.size 
  end  

  def test_rdfs_reasoning
    adapter_rdfs = ConnectionPool.add_data_source(:type => :jena, :ontology => :rdfs, :reasoner => :rdfs_simple)

    adapter_rdfs.add(@eyal, @age, @test)
    result = Query.new.distinct(:o).where(@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size
    
  end


end