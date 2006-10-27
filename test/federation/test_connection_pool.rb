# Author:: Benjamin Heitmann
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

# need access to connectionpool.adapter_pool in tests
class ConnectionPool
  def self.adapter_pool
    @adapter_pool
  end
end

class TestObjectCreation < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
  end

  def teardown
  end

  def test_class_add_data_source    
    # test for successfull adding of an adapter
    adapter = get_adapter
    assert_kind_of ActiveRdfAdapter, adapter
    assert ConnectionPool.adapter_pool.include?(adapter)
    
    # now check that we get the same adapter if we supply the same parameters
    adapter2 = get_adapter
    assert_equal adapter, adapter2
    # test same object_id
  end

  def test_class_adapter_pool
    assert_equal 0, ConnectionPool.adapter_pool.size
    adapter = get_adapter
    assert_equal 1, ConnectionPool.adapter_pool.size
  end

  def test_class_register_adapter
    ConnectionPool.register_adapter(:funkytype, ActiveRdfAdapter)
    assert ConnectionPool.adapter_types.include?(:funkytype)
  end

  def test_class_auto_flush_equals
    # assert auto flushing by default
    assert ConnectionPool.auto_flush?
    ConnectionPool.auto_flush = false
    assert !ConnectionPool.auto_flush?
  end

  def test_class_clear
    ConnectionPool.clear
    assert ConnectionPool.adapter_pool.empty?
    assert_nil ConnectionPool.write_adapter
  end

  def test_class_write_adapter
    adapter = get_write_adapter
    assert_kind_of ActiveRdfAdapter, adapter
  end

  def test_class_write_adapter_equals
    adapter = ConnectionPool.add_data_source(:type => :redland)
    adapter2 = ConnectionPool.add_data_source(:type => :redland, :location => "/tmp/redland-tmpy")
    assert_equal adapter2, ConnectionPool.write_adapter
    ConnectionPool.write_adapter = adapter
    assert_equal adapter, ConnectionPool.write_adapter
  end
end
