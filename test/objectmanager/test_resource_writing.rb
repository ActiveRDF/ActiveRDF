# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceInstanceMethods < Test::Unit::TestCase
  def setup
    @adapter = get_write_adapter
    Namespace.register(:ar, 'http://activerdf.org/test/')
    
    @eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
  end

  def teardown
  end

  def test_update_value
    assert_raises(ActiveRdfError) { @eyal.age = 18 }
   
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    
    assert_nothing_raised { @eyal.age = 18 }
    assert_equal ['18','27'], @eyal.age
  end

 
end
