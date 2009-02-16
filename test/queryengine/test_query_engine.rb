# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'queryengine/query'
require 'queryengine/query2sparql'
require "#{File.dirname(__FILE__)}/../common"
require 'set'

class TestQueryEngine < Test::Unit::TestCase
  include SetupAdapter

  def setup
    super
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
  end

  def test_datatype
    t = Time.parse("Tue Jan 20 12:00:00 -0800 2009")
    @adapter.add(TEST::time,TEST::value,t)

    email = Set["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal email,      Set.new(Query.new.select(:o).where(:s,:p,:o).datatype(:o,XSD::string).execute)
    assert_equal Set[27,21], Set.new(Query.new.select(:o).where(:s,:p,:o).datatype(:o,XSD::integer).execute)
    assert_equal [t],                Query.new.select(:o).where(:s,:p,:o).datatype(:o,XSD::time).execute
  end

  def test_lang

    en_blue = LocalizedString.new('blue','en')
    nl_blauw = LocalizedString.new('blauw','nl')
    @adapter.add(TEST::eyal,TEST::eye, nl_blauw)
    @adapter.add(TEST::eyal,TEST::eye,'blu')

    assert_equal Set[en_blue,nl_blauw,'blu'], Set.new(Query.new.select(:o).where(:s,TEST::eye,:o).execute)
    assert_equal Set[en_blue,nl_blauw],       Set.new(Query.new.select(:o).where(:s,:p,:o).lang(:o,'n',false).execute)
    assert_equal [en_blue],                           Query.new.select(:o).where(:s,:p,:o).lang(:o,'e',false).execute
    assert_equal [en_blue],                           Query.new.select(:o).where(:s,:p,:o).lang(:o,'en',true).execute
    assert_equal [],                                  Query.new.select(:s).where(:s,:p,:o).lang(:o,'n',true).execute

    # check that localized strings will also be found when searching with a non-localized string
    q = Query.new.select(:s).where(:s,TEST::eye,"blue").all_types
    assert_equal Set[TEST::eyal],    Set.new(q.execute)
    assert_equal Set[TEST::eyal],    Set.new(Query.new.select(:s).where(:s,TEST::eye,"blauw").all_types.execute)
  end

  def test_expanded_objects
    @adapter.load "#{File.dirname(__FILE__)}/../test_person2_data.nt"
    eyal = TEST::eyal
    michael = TEST::michael
    benjamin = TEST::Person.new(TEST::benjamin)
    eyal.test::member_of = ["A","B","C"]
    michael.test::member_of = ["A","B"]
    benjamin.test::member_of = ["B","C"]

    s = Query.new.select(:s).where(:s,TEST::member_of,["A","B","C"]).execute
    assert_equal Set[eyal], Set.new(s)

    s = Query.new.select(:s).where(:s,TEST::member_of,["A","B"]).execute
    assert_equal Set[eyal,michael], Set.new(s)

    s = Query.new.select(:s).where(:s,TEST::member_of,["B","C"]).execute
    assert_equal Set[eyal,benjamin], Set.new(s)

    s = Query.new.select(:s).where(:s,TEST::member_of,"B").execute
    assert_equal Set[eyal,michael,benjamin], Set.new(s)
  end
end
