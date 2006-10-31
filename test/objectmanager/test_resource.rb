# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceInstanceMethods < Test::Unit::TestCase
  def setup
    ConnectionPool.add_data_source(:type => :sparql, :url => "http://m3pe.org:8080/repositories/test-people", :results => :sparql_xml)
    Namespace.register(:ar, 'http://activerdf.org/test/')
    @eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
  end

  def teardown
  end

  def test_update_value
  end

  def test_find_all_instances
    assert_equal 36, RDFS::Resource.find_all.size
    assert_equal [@eyal], AR::Person.find_all
  end

  def test_class_predicates
    assert_equal 10, RDFS::Resource.predicates.size
  end

  def test_eyal_predicates
    predicates = @eyal.direct_predicates

    # assert that the three found predicates are eye, age, and type
    assert_equal 3, predicates.size
    predicates_labels = predicates.collect {|pred| pred.label }
    ['age', 'eye', 'type'].each do |pr|
      assert predicates_labels.include?(pr), "Eyal should have predicate #{pr}"
    end

    # assert that the found predicates on Person are eye, age, and type
    predicates_labels = predicates.collect {|pred| pred.label }
    ['age', 'eye', 'type'].each do |pr|
      assert predicates_labels.include?(pr), "Eyal should have predicate #{pr}"
    end
  end

  def test_eyal_types
    type_labels = @eyal.types.collect {|pred| pred.label}
    assert_equal ['Person','Resource'], type_labels
  end

  def test_eyal_age
    # triple exists '<eyal> age 27'
    assert_equal '27', @eyal.age

    # Person has property car, but eyal has no value for it
    assert_equal nil, @eyal.car

    # non-existent method should throw error
    assert_raise(NoMethodError) { @eyal.non_existing_method }
  end

  def test_eyal_type
    assert_instance_of RDFS::Resource, @eyal
    assert_instance_of AR::Person, @eyal
  end

  def test_find_methods
    found_eyal = RDFS::Resource.find_by_eye('blue')
    assert_not_nil found_eyal
    assert_equal @eyal, found_eyal
    assert_equal 'blue', RDFS::Resource.find_by_age(27).eye
    assert_equal @eyal, RDFS::Resource.find_by_age_and_eye(27,'blue')
  end

  # TODO: test for writing if no write adapter is defined (like only sparqls)

end
