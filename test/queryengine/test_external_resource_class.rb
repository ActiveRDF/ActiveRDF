require File.join("test","unit")
require 'active_rdf'
require File.join("queryengine","query")
require File.join(File.dirname(__FILE__),"..","common")
require File.join(File.dirname(__FILE__),"my_external_resource")


class TestExternalResourceClass < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
  end

  def teardown
    ConnectionPool.clear
  end
  
  @@eyal = RDFS::MyExternalResource.new("http://activerdf.org/test/eyal")
  @@age = RDFS::MyExternalResource.new("http://activerdf.org/test/age")
  
  def test_query_external_resource
    adapters = get_talia_adapters
    adapters.each do |adapter|
      
      # load test data
      adapter.load(File.join(File.dirname(__FILE__),"..","test_person_data.nt"))
      
      # execute query and check the result classes
      #require "ruby-debug/debugger"
      result = Query.new(RDFS::MyExternalResource).select(:p,:o).where(@@eyal, :p, :o).execute
      assert result.size > 0, "No Results for #{adapter.class}"
      assert_kind_of RDFS::MyExternalResource, result[0][0]
      
      # add data
      pl = PropertyList.new(@@age, Query.new(RDFS::MyExternalResource).select(:o).where(@@eyal, @@age, :o).execute, @@eyal)
      assert(pl.size > 0, "PropertyList empty")
      assert_nothing_raised {pl << "18"}
      result = Query.new.select(:o).where(@@eyal, @@age, :o).execute
      assert result.include?("18")
    end
  end
  
  def test_namespace_external_resource
    # namespace
    Namespace.register(:test, 'http://activerdf.org/test/')
    assert_kind_of(RDFS::MyExternalResource, Namespace.lookup(:test, "eyal", RDFS::MyExternalResource))
    assert_equal(:test, Namespace.prefix(@@eyal))
    assert_equal("eyal",Namespace.localname(@@eyal))
  end
end
