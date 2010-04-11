# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'test_helper'
require 'adapters/test_network_aware_adapter'

class TestFetchingAdapter < Test::Unit::TestCase
  include SetupAdapter
  include TestNetworkAwareAdapter

  def setup
    super(:type => :fetching)
  end
end
