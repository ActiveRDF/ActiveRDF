require 'test/unit'
require 'active_rdf'
# require 'active_rdf/test/common'

class TestObjectCreation < Test::Unit::TestCase
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
end
