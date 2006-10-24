# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'adapter/redland'
require 'federation/federation_manager'
# require 'active_rdf/test/common'

class TestObjectCreation < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_pool
    adapter1 = ConnectionPool.add_data_source(:type => :redland)
    adapter2 = ConnectionPool.add_data_source(:type => :redland)
    adapter3 = ConnectionPool.add_data_source(:type => :redland, :fake_symbol_to_get_different_adapter => true)
    adapter4 = ConnectionPool.add_data_source(:type => :redland, :fake_symbol_to_get_different_adapter => true)
    adapter5 = ConnectionPool.add_data_source(:type => :redland, :yet_another_symbol => true)

    one = adapter1.object_id
    three = adapter3.object_id
    five = adapter5.object_id

    assert_equal one, adapter2.object_id
    assert_equal three, adapter4.object_id
    assert one != three
    assert one != five
    assert three != five
  end
end
