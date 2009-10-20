# Author:: Benjamin Heitmann
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestConnectionPool < Test::Unit::TestCase
  include ActiveRDF

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
    assert ConnectionPool.adapters.include?(adapter)

    # now check that we have different adapters for primary and secondary
    adapter2 = get_secondary_adapter
    assert adapter != adapter2
  end

  def test_duplicate_registration
    adapter1 = ConnectionPool.add_data_source(:type => :rdflite)
    adapter2 = ConnectionPool.add_data_source(:type => :rdflite)

    assert_equal adapter1, adapter2
    assert_equal adapter1.object_id, adapter2.object_id
  end

  def test_class_adapter_pool
    ConnectionPool.clear
    assert_equal 0, ConnectionPool.adapters.size
    get_primary_adapter
    assert_equal 1, ConnectionPool.adapters.size
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
    assert ConnectionPool.adapters.empty?
    assert_nil ConnectionPool.write_adapter
  end
end