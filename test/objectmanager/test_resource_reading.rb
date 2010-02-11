# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'set'
require "#{File.dirname(__FILE__)}/../common"

class TestResourceReading < Test::Unit::TestCase
  include SetupAdapter

  @@eyal = TEST::eyal
  
  def setup
    super
    test_dir = "#{File.dirname(__FILE__)}/.."
    @adapter.load "#{test_dir}/rdf.nt"
    @adapter.load "#{test_dir}/rdfs.nt"
    @adapter.load "#{test_dir}/test_person_data.nt"
  end

  def test_class_resource_equality
    p = TEST::Person
    r  = RDFS::Resource.new(p.uri)
    assert_equal p, r
    assert_equal r, p
    assert p.eql?(r)
    assert r.eql?(p)
  end

  def test_class_predicates
    resource_predicates = RDFS::Resource.predicates
    assert_equal 7, resource_predicates.size
    assert resource_predicates.include?(RDF::type)
    assert resource_predicates.include?(RDF::value)
    assert resource_predicates.include?(RDFS::comment)
    assert resource_predicates.include?(RDFS::label)
    assert resource_predicates.include?(RDFS::seeAlso)
    assert resource_predicates.include?(RDFS::isDefinedBy)
    assert resource_predicates.include?(RDFS::member)
    person_predicates = (TEST::Person.predicates - resource_predicates)
    assert_equal 3, person_predicates.size
    assert person_predicates.include?(TEST::age)
    assert person_predicates.include?(TEST::eye)
    assert person_predicates.include?(TEST::car)
    assert !person_predicates.include?(TEST::email)
  end
  
  def test_property_accessors
    properties = @@eyal.property_accessors
    assert_equal 11, properties.size
    %w(type value comment label seeAlso isDefinedBy member age eye car email).each{|prop| assert properties.include?(prop), "missing property #{prop}"}
  end

  def test_resource_predicates
    # assert that eyal's three direct predicates are eye, age, and type
    preds = @@eyal.direct_predicates
    assert_equal 4, preds.size
    assert preds.include?(TEST::age)
    assert preds.include?(TEST::eye)
    assert preds.include?(TEST::email)
  end

  def test_resource_type
    assert_instance_of RDFS::Resource, @@eyal
    assert_instance_of TEST::Person, @@eyal
  end

  def test_resource_types
    type = @@eyal.type
    assert_equal 2, type.size
    assert type.include?(TEST::Person.class_uri)
    assert type.include?(RDFS::Resource.class_uri)
  end

  def test_resource_values
    # triple exists '<eyal> age 27'
    assert_kind_of RDF::Property, @@eyal.age
    assert_equal 1, @@eyal.age.size
    assert_equal 27, @@eyal.age.to_a.first
    assert_equal @@eyal.age.to_a.first, 27 
    assert_equal [27], @@eyal.age
    assert_equal @@eyal.age, [27]
    assert_kind_of RDF::Property, @@eyal.test::age
    assert_equal 1, @@eyal.test::age.size
    assert_equal 27, @@eyal.test::age.to_a.first
    assert_equal @@eyal.test::age.to_a.first, 27

    assert_equal 27, @@eyal.age[27]

    # Person has property car, but eyal has no value for it
    assert @@eyal.car.empty?
    assert_equal [], @@eyal.car
    assert @@eyal.test::car.empty?
    assert_equal [], @@eyal.test::car

    # non-existent property returns nil
    assert_nil @@eyal.non_existing_property

    # non-existent properties thrown errors on assignment
    assert_raise ActiveRdfError do
      @@eyal.non_existing_property = "value"
    end
  end

  def test_predicate_management
    @adapter.add(TEST::hair,RDF::type,RDF::Property)
    @adapter.add(TEST::hair,RDFS::domain,TEST::Person)
    assert TEST::Person.predicates.include?(TEST::hair)
  end

  def test_custom_method
    TEST::Person.class_eval{def foo; "foo"; end}
    assert_equal "foo", @@eyal.foo
    TEST::Graduate.class_eval{def bar; "bar"; end}
    assert_nil @@eyal.bar
    @@eyal.type += TEST::Graduate
    assert_equal "bar", @@eyal.bar
  end

  def test_find_all
    assert_equal Set[@@eyal, TEST::other], Set.new(TEST::Person.find_all)
  end

  def test_find_methods
    blue = LocalizedString.new('blue','en')
    assert_raise ActiveRdfError do
      # this should raise an error because eye is not in the domain of RDFS::Resource
      assert_equal [@@eyal], RDFS::Resource.find_by.eye(blue).execute
    end

    assert_equal [@@eyal], TEST::Person.find_by.test::email.execute    

    assert_equal [], RDFS::Resource.find_by.test::eye('blue').execute
    assert_equal [@@eyal], RDFS::Resource.find_by.test::eye('blue').all_types.execute

    assert_equal [@@eyal], RDFS::Resource.find_by.test::eye(blue).execute

    # using Person class, fully qualified properties not required
    assert_equal [@@eyal], TEST::Person.find_by.age(27).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).execute

    assert_equal [@@eyal], TEST::Person.find_by.age(27).eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).test::eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.age(27).test::eye(blue).execute

    # bug 62481
    camelCaseProperty = RDF::Property.new(TEST::camelCaseProperty).save
    camelCaseProperty.domain = TEST::Person
    @@eyal.camelCaseProperty = "a CamelCase property name"
    q = TEST::Person.find_by.camelCaseProperty.instance_eval{@query}
    qs = q.to_s
    assert_equal [@@eyal], TEST::Person.find_by.camelCaseProperty.execute
    assert_equal [@@eyal], TEST::Person.find_by.test::camelCaseProperty.execute
    assert_equal [@@eyal], TEST::Person.find_by.camelCaseProperty("a CamelCase property name").execute

    underscored_property = RDF::Property.new(TEST::underscored_property).save
    underscored_property.domain = TEST::Person
    @@eyal.underscored_property = "an underscored property name"
    assert_equal [@@eyal], TEST::Person.find_by.underscored_property.execute
    assert_equal [@@eyal], TEST::Person.find_by.test::underscored_property.execute
    assert_equal [@@eyal], TEST::Person.find_by.underscored_property("an underscored property name").execute

    mixedCamelCase_underscored_property = RDF::Property.new(TEST::mixedCamelCase_underscored_property).save
    mixedCamelCase_underscored_property.domain = TEST::Person
    @@eyal.mixedCamelCase_underscored_property = "a mixed CamelCase and underscored property"
    assert_equal [@@eyal], TEST::Person.find_by.mixedCamelCase_underscored_property.execute
    assert_equal [@@eyal], TEST::Person.find_by.test::mixedCamelCase_underscored_property.execute
    assert_equal [@@eyal], TEST::Person.find_by.mixedCamelCase_underscored_property("a mixed CamelCase and underscored property").execute
    
    found = RDFS::Resource.find_by.rdf::type(RDFS::Resource).execute
    assert_equal 2, found.size
    assert found.include?(TEST::Person)
    assert found.include?(TEST::eyal)
  end


  def test_finders_with_options
    assert_equal Set[TEST::car, TEST::age, TEST::eye], Set.new(RDF::Property.find_by.rdfs::domain(TEST::Person).execute)

    assert_equal 2, RDFS::Resource.find_all.size
#    assert_equal 2, RDFS::Resource.find(:all, :limit => 10).size
#    assert_equal 1, RDFS::Resource.find(:all, :limit => 1).size

    if @adapter.contexts?
      file = "#{File.dirname(__FILE__)}/../test_person2_data.nt"
      @adapter.load file
      context = RDFS::Resource.new("file:#{file}")

      assert_equal 1, RDFS::Resource.find(:all, :context => context).size
      assert_equal 1, RDFS::Resource.find(:all, :context => context, :limit => 1).size
      assert_equal 0, RDFS::Resource.find(:all, :context => context, :limit => 0).size
      assert_equal 1, RDFS::Resource.find_by_eye('blue', :context => one).size
      assert_equal 0, RDFS::Resource.find_by_eye('blue', :context => two).size
      assert_equal 1, RDFS::Resource.find_by_rdf::type(RDFS::Resource, :context => one).size
      assert_equal 1, RDFS::Resource.find_by_eye_and_rdf::type('blue', RDFS::Resource, :context => one).size
    end
  end

  # test for writing if no write adapter is defined (like only sparqls)
  def test_write_without_write_adapter
    ConnectionPool.clear
    get_read_only_adapter
    assert_raises(ActiveRdfError) { @@eyal.test::age = 18 }
  end
end
