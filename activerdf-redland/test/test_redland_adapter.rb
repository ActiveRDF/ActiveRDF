# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'tmpdir'
require 'fileutils'
common_test_dir = File.dirname(File.expand_path(__FILE__)) + '/../../test'
require "#{common_test_dir}/adapters/test_writable_adapter"
require "#{common_test_dir}/adapters/test_persistent_adapter"
require "#{common_test_dir}/adapters/test_network_aware_adapter"

module TestRedlandAdapter
  include TestWritableAdapter
  include TestNetworkAwareAdapter

  def test_sparql_query
    @adapter.add(@@eyal, @@age, @@ageval)

    @adapter.flush

    query = Query.new.distinct(:s).where(:s,:p,:o)
    sparql_query = @adapter.get_query_results(query)
    assert sparql_query.include?(TEST::eyal.uri)
  end
end

class TestRedlandAdapterMemory < Test::Unit::TestCase
  include TestRedlandAdapter
  # not persistent

  def setup
    super(:type => :redland, :location => "memory")
  end
end

#class TestRedlandAdapterFile < Test::Unit::TestCase
#  include TestRedlandAdapter
#  include TestPersistentAdapter
#
#  def setup
#    super(:type => :redland, :location => @location)
#    @location = File.join(Dir.tmpdir,"redland-temp")
#  end
#  def teardown
#    FileUtils.rm Dir.glob(@location + '-*')
#  end
#end

class TestRedlandAdapterSqlite < Test::Unit::TestCase
  include TestRedlandAdapter
  # not persistent

  def setup
    super(:type => :redland, :location => 'sqlite')
  end
end

#class TestRedlandAdapterMySQL < Test::Unit::TestCase
#  include TestRedlandAdapter
#  include TestPersistentAdapter
#
#  def setup
#    super(:type => :redland, :name => 'db1', :location => 'mysql',
#          :host => 'localhost', :database => 'redland_test',
#          :user => '', :password => '', :new => 'yes')
#  end
#end

#class TestRedlandAdapterPostgres < Test::Unit::TestCase
#  include TestPersistentAdapter
#  include TestRedlandAdapter
#
#  def setup
#    super(:type => :redland, :name => 'db1', :location => 'postgresql',
#          :host => 'localhost', :database => 'redland_test',
#          :user => '', :password => '', :new => 'yes')
#  end
#end

