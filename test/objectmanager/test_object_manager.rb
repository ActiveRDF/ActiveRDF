# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require "#{File.dirname(__FILE__)}/../common"

class TestObjectManager < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
  end

  def teardown
  end

  def test_resource_creation
    assert_nothing_raised { RDFS::Resource.new('abc') }

    r1 = RDFS::Resource.new('abc')
    r2 = RDFS::Resource.new('cde')
    r3 = RDFS::Resource.new('cde')

    assert_equal 'abc', r1.uri
    assert_equal 'cde', r2.uri
    assert_equal r3, r2
  end

  def test_class_construct_classes
		adapter = get_write_adapter
		adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"

		Namespace.register(:test, 'http://activerdf.org/test/')
		ObjectManager.construct_classes

		assert(defined? TEST, "class construction should have created module TEST")
		assert(defined? RDFS, "class construction should have created module RDFS")
		assert(defined? TEST::Person, "class construction should have created TEST::Person")
		assert(defined? RDFS::Class, "class construction should have created RDFS::Class")
  end

	def test_class_construct_class
		adapter = get_write_adapter
		adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"

		Namespace.register(:test, 'http://activerdf.org/test/')
		person_resource = Namespace.lookup(:test, :Person)
		person_class = ObjectManager.construct_class(person_resource)
		assert_instance_of Class, person_class
		assert_equal person_resource.uri, person_class.class_uri.uri
	end
end
