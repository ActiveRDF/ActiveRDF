# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'rubygems'
require 'test/unit'
require 'active_rdf'

class TestFetchingAdapter < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
    @adapter = ConnectionPool.add(:type => :fetching)
  end

  def teardown
  end

  def test_parse_foaf    
    @adapter.fetch("http://eyaloren.org/foaf.rdf#me")
    assert @adapter.size > 0
  end
  
  def test_sioc_schema
    @adapter.fetch("http://rdfs.org/sioc/ns#")
    assert_equal 560, @adapter.size 
  end
    
  def test_foaf_schema
    @adapter.fetch("http://xmlns.com/foaf/0.1/")
    # foaf contains 563 triples but with two duplicates
    assert_equal 561, @adapter.size    
  end
end
