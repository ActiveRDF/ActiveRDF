# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceWriting < Test::Unit::TestCase
  include SetupAdapter

  @@eyal = TEST::eyal

  def test_update_value
    assert_raises(ActiveRdfError) { @@eyal.age = 18 }

    @@eyal.test::age = 100
    assert_equal 100, @@eyal.test::age.to_a.first

    @@eyal.age += 18
    assert_equal [100,18], @@eyal.age

    @@eyal.test::age = [100, 80]
    assert_equal [100, 80], @@eyal.test::age
  end

  def test_clear_property
    TEST::eyal.test::email = ["eyal@cs.vu.nl","eyal.oren@deri.net"]
    assert_equal 2, TEST::eyal.email.size
    TEST::eyal.email.clear

    # once direct predicates not defined in the schema are removed, they are no longer accessible without specifying a namespace
    assert_nil TEST::eyal.email
    assert_raise ActiveRdfError do
      TEST::eyal.email = ""
    end
    assert_equal 0, TEST::eyal.test::email.size
  end

  def test_save
    foo = RDFS::Resource.new(TEST::foo)
    assert_equal 0, ConnectionPool.write_adapter.size
    foo.save
    assert_equal 1, ConnectionPool.write_adapter.size
    assert_equal [foo], RDFS::Resource.find_all
  end
end
