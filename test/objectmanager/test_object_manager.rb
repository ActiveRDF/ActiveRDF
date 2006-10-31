# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'

class TestObjectManager < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_unique_same_object_creation
    assert_nothing_raised { RDFS::Resource.new('abc') }

    r1 = RDFS::Resource.new('abc')
    r2 = RDFS::Resource.new('cde')
    r3 = RDFS::Resource.new('cde')

    assert_equal 'abc', r1.uri
    assert_equal 'cde', r2.uri
    assert_equal r3, r2

    assert_instance_of RDFS::Resource, r1
    assert_instance_of RDFS::Resource, r2
    assert_instance_of RDFS::Resource, r3
  end
  
   def test_class_construct_class
    raise NotImplementedError, 'Need to write test_class_construct_class'
  end

  def test_class_construct_classes
    raise NotImplementedError, 'Need to write test_class_construct_classes'
  end

  def test_class_create_module_name
    raise NotImplementedError, 'Need to write test_class_create_module_name'
  end

  def test_class_localname_to_class
    raise NotImplementedError, 'Need to write test_class_localname_to_class'
  end

  def test_class_prefix_to_module
    raise NotImplementedError, 'Need to write test_class_prefix_to_module'
  end

  def test_class_replace_illegal_chars
    raise NotImplementedError, 'Need to write test_class_replace_illegal_chars'
  end
  
end
