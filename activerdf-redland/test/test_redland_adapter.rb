# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'tmpdir'
require 'fileutils'
common_test_dir = File.join(File.dirname(File.expand_path(__FILE__)),'..','..','test')
require "#{common_test_dir}/test_writable_adapter"
require "#{common_test_dir}/test_persistent_adapter"

module TestRedlandAdapter
  include TestWritableAdapter
  
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
    @adapter_args = {:type => :redland, :location => "memory"}
    super
  end
end

lass TestRedlandAdapterFile < Test::Unit::TestCase
 include TestRedlandAdapter 
 include TestPersistentAdapter

 def setup
   @location = File.join(Dir.tmpdir,"redland-temp")
   @adapter_args = {:type => :redland, :location => @location} 
   super
 end
 def teardown
   FileUtils.rm Dir.glob(@location + '-*')
 end
nd

class TestRedlandAdapterSqlite < Test::Unit::TestCase
  include TestRedlandAdapter 
  # not persistent

  def setup
    @adapter_args = {:type => :redland, :location => 'sqlite'}
    super
  end
end

#class TestRedlandAdapterMySQL < Test::Unit::TestCase
#  include TestRedlandAdapter
#  include TestPersistentAdapter
#
#  def setup
#    @adapter_args = {:type => :redland, :name => 'db1', :location => 'mysql',
#                     :host => 'localhost', :database => 'redland_test',
#                     :user => '', :password => '', :new => 'yes'}
#    super
#    @adapter.clear
#  end
#end

#class TestRedlandAdapterPostgres < Test::Unit::TestCase
#  include TestPersistentAdapter
#  include TestRedlandAdapter 
#
#  def setup
#    @adapter_args = {:type => :redland, :name => 'db1', :location => 'postgresql',
#                     :host => 'localhost', :database => 'redland_test',
#                     :user => '', :password => '', :new => 'yes'}
#    super
#  end
#end

