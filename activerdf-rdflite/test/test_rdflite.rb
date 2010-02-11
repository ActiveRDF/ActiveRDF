# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

# require 'active_rdf'
require 'test/unit'
require 'active_rdf'
common_test_dir = File.dirname(File.expand_path(__FILE__)) + '/../../test'
require "#{common_test_dir}/adapters/test_persistent_adapter"
require "#{common_test_dir}/adapters/test_bnode_capable_adapter"
require "#{common_test_dir}/adapters/test_context_aware_adapter"
require "#{common_test_dir}/adapters/test_network_aware_adapter"
require "#{common_test_dir}/adapters/test_reasoning_adapter"


class TestRdfLiteAdapter < Test::Unit::TestCase
  include SetupAdapter
  include TestNetworkAwareAdapter
  include TestReasoningAdapter

  def setup
    super(:type => :rdflite)
  end

  def test_registration
    assert_instance_of RDFLite, @adapter
  end

  def test_initialise
    @adapter = ConnectionPool.add(:type => :rdflite, :keyword => false)
    assert !@adapter.keyword_search?
  end

#  def test_keyword_search
#    @adapter = ConnectionPool.add(:type => :rdflite, :keyword => true)
#
#    # we cant garantuee that ferret is installed
#    if @adapter.keyword_search?
#      assert_equal TEST::eyal, Query.new.distinct(:s).where(:s,:keyword,"blue").execute(:flatten => true)
#      assert_equal TEST::eyal, Query.new.distinct(:s).where(:s,:keyword,"27").execute(:flatten => true)
#      assert_equal TEST::eyal, Query.new.distinct(:s).where(:s,:keyword,"eyal oren").execute(:flatten => true)
#    end
#  end
end

class TestRdfLiteAdapterMemory < Test::Unit::TestCase
  include TestWritableAdapter
  #include TestBnodeCapableAdapter
  #include TestContextAwareAdapter

  def setup
    super(:type => :rdflite, :new => true)
  end
end

class TestRdfLiteAdapterFile < Test::Unit::TestCase
  include TestPersistentAdapter
  #include TestBnodeCapableAdapter
  #include TestContextAwareAdapter

  def setup
    super(:type => :rdflite, :location => 'test_rdflite_db', :new => true)
  end
end