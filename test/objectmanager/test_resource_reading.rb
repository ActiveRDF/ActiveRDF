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
    assert_equal Set[RDF::type,RDF::value,RDFS::comment,RDFS::label,RDFS::seeAlso,RDFS::isDefinedBy,RDFS::member],
                 Set.new(RDFS::Resource.predicates)
    assert_equal Set[TEST::age, TEST::eye, TEST::car],
                 Set.new(TEST::Person.predicates - RDFS::Resource.predicates)
  end

  def test_resource_predicates
    # assert that eyal's three direct predicates are eye, age, and type
    assert_equal Set[RDF::type, TEST::age, TEST::eye, TEST::email],
                 Set.new(@@eyal.direct_predicates)
  end

  def test_resource_type
    assert_instance_of RDFS::Resource, @@eyal
    assert_instance_of TEST::Person, @@eyal
  end

  def test_resource_types
    assert_equal Set[TEST::Person.class_uri, RDFS::Resource.class_uri],
                 Set.new(@@eyal.type)
  end

  def test_resource_classes
    assert_equal Set[TEST::Person, RDFS::Resource],
                 Set.new(@@eyal.classes)
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
    nl_blauw = LocalizedString.new('blauw','nl')
    @adapter.add(TEST::eyal,TEST::eye, nl_blauw)
    @adapter.add(TEST::other,TEST::eye,LocalizedString.new('rot','de'))

    # find all TEST::Person resources
    assert_equal Set[@@eyal, TEST::other], Set.new(TEST::Person.find_all)

    # find TEST::Person resources that having the property specified
    assert_equal Set[@@eyal, TEST::other], Set.new(TEST::Person.find_by.age.execute)
    assert_equal [@@eyal], TEST::Person.find_by.test::email.execute

    # find TEST::Person resources with property matching the supplied value(s)
    assert_equal [@@eyal], TEST::Person.find_by.age(27).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::email('eyal@cs.vu.nl','eyal.oren@deri.org').execute
    assert_equal [@@eyal], TEST::Person.find_by.test::email(['eyal@cs.vu.nl','eyal.oren@deri.org']).execute
    assert_equal [@@eyal], TEST::Person.find_by.eye(blue).execute

    # find TEST::Person resources with property matching the supplied value ignoring lang/datatypes
    assert_equal [@@eyal], TEST::Person.find_by.eye('blue').execute(:all_types => true)
    assert_equal       [], TEST::Person.find_by.eye('blue').execute

    # find RDFS::Resources having property matching the supplied value ignoring lang/datatypes
    assert_equal [@@eyal], RDFS::Resource.find_by.test::eye('blue').execute(:all_types => true)
    assert_equal       [], RDFS::Resource.find_by.test::eye('blue').execute

    # find TEST::Person resources with property having the specified language
    assert_equal [@@eyal], TEST::Person.find_by.eye(:lang => '@en').execute
    assert_equal [@@eyal], TEST::Person.find_by.eye(:lang => '@nl').execute
    assert_equal [TEST::other], TEST::Person.find_by.eye(:lang => '@de').execute

    # find TEST::Person resources with property having the specified datatype
    assert_equal Set[@@eyal, TEST::other], Set.new(TEST::Person.find_by.age(:datatype => XSD::integer).execute)
    TEST::other.age = "twenty"
    assert_equal [@@eyal], TEST::Person.find_by.age(:datatype => XSD::integer).execute

    # combining lang/datatype specifiers with all_types is prohibited
    assert_raise ActiveRdfError do
      TEST::Person.find_by.eye(:lang => '@en').execute(:all_types => true)
    end
    assert_raise ActiveRdfError do
      TEST::Person.find_by.age(:datatype => XSD::integer).execute(:all_types => true)
    end

    # chain multiple properties together, ANDing restrictions
    assert_equal [@@eyal], TEST::Person.find_by.age(27).eye(blue).execute

    # raise error for properties not in domain (fully qualified name required)
    assert_raise ActiveRdfError do
      RDFS::Resource.find_by.age(27).execute
    end

    # find RDFS::Resources having the fully qualified property
    assert_equal [@@eyal], RDFS::Resource.find_by.test::email.execute

    # find RDFS::Resources having the fully qualified property and value
    assert_equal [@@eyal], RDFS::Resource.find_by.test::age(27).execute
    assert_equal [@@eyal], RDFS::Resource.find_by.test::eye(blue).execute

    # find RDFS::Resources with multiple chained properties
    assert_equal [@@eyal], TEST::Person.find_by.age(27).eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.age(27).test::eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).eye(blue).execute
    assert_equal [@@eyal], TEST::Person.find_by.test::age(27).test::eye(blue).execute

    # bug 62481
    camelCaseProperty = RDF::Property.new(TEST::camelCaseProperty).save
    camelCaseProperty.domain = TEST::Person
    @@eyal.camelCaseProperty = "a CamelCase property name"
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

    # Sqlite doesn't support regular expressions by default
    unless ConnectionPool.write_adapter.class == ActiveRDF::RDFLite
      # find TEST::Person resources with property matching the specified regex
      assert_equal [@@eyal], TEST::Person.find_by.age(:regex => /7/).execute
      assert_equal [@@eyal], TEST::Person.find_by.eye(:regex => /lu/).execute
      assert_equal [TEST::other], TEST::Person.find_by.eye(:regex => /ot/).execute
    end
  end


  def test_finders_with_options
    blue = LocalizedString.new('blue','en')

    assert_equal Set[TEST::car, TEST::age, TEST::eye], Set.new(RDF::Property.find_by.rdfs::domain(TEST::Person).execute)

    assert_equal 2, RDFS::Resource.find_all.size
    assert_equal 2, RDFS::Resource.find_all(:limit => 10).size
    assert_equal 1, RDFS::Resource.find_all(:limit => 1).size

    if @adapter.contexts?
      file = "#{File.dirname(__FILE__)}/../test_person2_data.nt"
      @adapter.load(file)
      context_one = RDFS::Resource.new("file:#{File.dirname(__FILE__)}/../test_person_data.nt")
      context_two = RDFS::Resource.new("file:#{file}")

      assert_equal 2, RDFS::Resource.find_all(:context => context_one).size
      assert_equal 1, RDFS::Resource.find_all(:context => context_two).size
      assert_equal 1, RDFS::Resource.find_all(:context => context_one, :limit => 1).size

      # Redland doesn't support querying more than one context at a time as of Feb 2009
      assert_equal [@@eyal], TEST::Person.find_by.age(27,:context => context_one).execute
      assert_equal       [], TEST::Person.find_by.eye('blue', :context => context_one).execute
      assert_equal [@@eyal], TEST::Person.find_by.eye('blue', :context => context_one).execute(:all_types => true)
      assert_equal [@@eyal], TEST::Person.find_by.eye(blue, :context => context_one).execute
      assert_equal       [], TEST::Person.find_by.eye(blue, :context => context_two).execute
    end
  end

  # test for writing if no write adapter is defined (like only sparqls)
  def test_write_without_write_adapter
    ConnectionPool.clear
    get_read_only_adapter
    assert_raises(ActiveRdfError) { @@eyal.test::age = 18 }
  end
end
