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
  end

  def test_update_value
    Namespace.register(:ar, 'http://activerdf.org/test/')
    adapter = get_write_adapter

    eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    assert_raises(ActiveRdfError) { eyal.age = 18 }

    eyal.ar::age = 100
    assert_equal 100, eyal.ar::age
    assert_equal [100], eyal.all_ar::age
   
    # << fails on Fixnums , because Ruby doesn't allow us to change behaviour of 
    # << on Fixnums 
    eyal.age << 18
    assert_equal 100, eyal.age

    eyal.ar::age = [100, 80]
    assert_equal [100, 80], eyal.ar::age
  end
end
