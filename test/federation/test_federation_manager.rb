# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/federation_manager'
require "#{File.dirname(__FILE__)}/../common"

class TestObjectCreation < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
  end

  def teardown
  end

	def test_ensure_adapter_behaviour
		adapter = get_adapter
		read_behaviour = [:query, :translate, :writes?, :reads?, :size]
		write_behaviour = [:add, :flush, :load]

		read_behaviour.each do |method|
			assert adapter.respond_to?(method), "adapter #{adapter.class} should respond to #{method}"
		end if adapter.reads?

		write_behaviour.each do |method|
			assert adapter.respond_to?(method), "adapter #{adapter.class} should respond to #{method}"
		end if adapter.writes?
	end

	def test_single_pool
		a1 = get_adapter
		a2 = get_adapter
		assert_equal a1, a2
		assert_equal a1.object_id, a2.object_id
	end
end
