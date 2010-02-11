# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
common_test_dir = File.dirname(File.expand_path(__FILE__)) + '/../../test'
require "#{common_test_dir}/common"
require "#{common_test_dir}/adapters/test_network_aware_adapter"

class TestFetchingAdapter < Test::Unit::TestCase
  include SetupAdapter
  include TestNetworkAwareAdapter

  def setup
    super(:type => :fetching)
  end
end
