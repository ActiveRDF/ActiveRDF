# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceWriting < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
    @adapter = get_primary_adapter
    Namespace.register(:test, 'http://activerdf.org/test/')

    @eyal = TEST::eyal
  end

  def test_update_value
    assert_raises(ActiveRdfError) { @eyal.age = 18 }

    @eyal.test::age = 100
    assert_equal 100, @eyal.test::age.to_a.first
   
    @eyal.age += 18
    assert_equal [100,18], @eyal.age

    @eyal.test::age = [100, 80]
    assert_equal [100, 80], @eyal.test::age
  end
end
