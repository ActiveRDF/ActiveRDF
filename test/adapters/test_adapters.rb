# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/federation_manager'
require 'queryengine/query'
require "#{File.dirname(__FILE__)}/../common"

class TestAdapter < Test::Unit::TestCase
  include ActiveRDF

  def setup
    ConnectionPool.clear
  end

  def teardown
  end

  def test_ensure_adapter_behaviour
    read_adapters = ConnectionPool.read_adapters
    write_adapters = ConnectionPool.write_adapters
    read_behaviour = [:query, :translate, :writes?, :reads?]
    write_behaviour = [:add, :delete, :flush, :load]

    read_behaviour.each do |method|
      read_adapters.each do |a|
        assert a.respond_to?(method), "adapter #{a.class} should respond to #{method}"
      end
    end

    write_behaviour.each do |method|
      write_adapters.each do |a|
        assert a.respond_to?(method), "adapter #{a.class} should respond to #{method}"
      end
    end
  end
end

