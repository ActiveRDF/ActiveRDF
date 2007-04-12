# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceReading < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
    @adapter = get_adapter
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    Namespace.register(:test, 'http://activerdf.org/test/')
    ObjectManager.construct_classes

    @eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
  end

  def teardown
  end

  def test_find_all_instances
    assert_equal 7, RDFS::Resource.find_all.size
    assert_equal [TEST::eyal, TEST::other], TEST::Person.find_all
  end

  def test_class_predicates
    assert_equal 4, RDFS::Resource.predicates.size
  end

  def test_eyal_predicates
    # assert that eyal's three direct predicates are eye, age, and type
    preds = @eyal.direct_predicates.collect {|p| p.uri }
    assert_equal 3, preds.size
    ['age', 'eye', 'type'].each do |pr|
      assert preds.any? {|uri| uri =~ /.*#{pr}$/ }, "Eyal should have predicate #{pr}"
    end

		# test class level predicates
		class_preds = @eyal.class_level_predicates.collect {|p| p.uri }
		# eyal.type: person and resource, has predicates age, eye
		# not default rdfs:label, rdfs:comment, etc. because not using rdfs reasoning
    assert_equal 4, class_preds.size
  end

  def test_eyal_types
    types = @eyal.type
		assert_equal 2, types.size
		assert types.include?(TEST::Person)
		assert types.include?(RDFS::Resource)
  end

  def test_eyal_age
    # triple exists '<eyal> age 27'
    assert_equal '27', @eyal.age

    # Person has property car, but eyal has no value for it
    assert_equal nil, @eyal.car

    # non-existent method should throw error
    assert_equal nil, @eyal.non_existing_method
  end

  def test_eyal_type
    assert_instance_of RDFS::Resource, @eyal
    assert_instance_of TEST::Person, @eyal
  end

  def test_find_options
    all = [Namespace.lookup(:test,:Person), Namespace.lookup(:rdfs, :Class), Namespace.lookup(:rdf, :Property), @eyal, TEST::car, TEST::age, TEST::eye]
    found = RDFS::Resource.find
    assert_equal all.sort, found.sort

    properties = [TEST::car, TEST::age, TEST::eye]
    found = RDFS::Resource.find(:where => {RDFS::domain => RDFS::Resource})
    assert_equal properties.sort, found.sort

    found = RDFS::Resource.find(:where => {RDFS::domain => RDFS::Resource, :prop => :any})
    assert_equal properties.sort, found.sort

    found = TEST::Person.find(:order => TEST::age)
    assert_equal [TEST::other, TEST::eyal], found
  end

  def test_find_methods
    assert_equal @eyal, RDFS::Resource.find_by_eye('blue')
    assert_equal @eyal, RDFS::Resource.find_by_test::eye('blue')

    assert_equal @eyal, RDFS::Resource.find_by_age(27)
    assert_equal @eyal, RDFS::Resource.find_by_test::age(27)

    assert_equal @eyal, RDFS::Resource.find_by_age_and_eye(27, 'blue')
    assert_equal @eyal, RDFS::Resource.find_by_test::age_and_test::eye(27, 'blue')
    assert_equal @eyal, RDFS::Resource.find_by_test::age_and_eye(27, 'blue')
    assert_equal @eyal, RDFS::Resource.find_by_age_and_test::eye(27, 'blue')
  end

  # test for writing if no write adapter is defined (like only sparqls)
  def test_write_without_write_adapter
    ConnectionPool.clear
    get_read_only_adapter
    assert_raises(ActiveRdfError) { @eyal.age = 18 }
  end
end
