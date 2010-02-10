# Author:: Benjamin Heitmann
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestConnectionPool < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
  end

  def teardown
		ConnectionPool.clear
  end

  def test_class_add_data_source    
    # test for successfull adding of an adapter
    adapter = get_primary_adapter
    assert_kind_of ActiveRdfAdapter, adapter
    assert ConnectionPool.adapter_pool.include?(adapter)
    
    # now check that we have different adapters for primary and secondary
    adapter2 = get_secondary_adapter
    assert adapter != adapter2
  end

  def test_class_adapter_pool
    ConnectionPool.clear
    assert_equal 0, ConnectionPool.adapter_pool.size
    get_primary_adapter
    assert_equal 1, ConnectionPool.adapter_pool.size
  end

  def test_class_register_adapter
    ConnectionPool.register_adapter(:funkytype, ActiveRdfAdapter)
    assert ConnectionPool.adapter_types.include?(:funkytype)
    # unregister test adapter
    ConnectionPool.unregister_adapter(:funkytype)
    assert !ConnectionPool.adapter_types.include?(:funkytype)
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
end

# need access to connectionpool.adapter_pool in tests
class ConnectionPool
  def self.adapter_pool
    @@adapter_pool
  end
end

