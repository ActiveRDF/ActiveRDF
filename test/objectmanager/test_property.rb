require 'test/unit'
require 'active_rdf'
require 'set'
require File.dirname(File.expand_path(__FILE__)) + '/../common'

class TestProperty < Test::Unit::TestCase
  include SetupAdapter

  def test_retrieve_a_triple_with_property
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    @adapter.load "#{File.dirname(__FILE__)}/../test_person2_data.nt"
    eyal = TEST::eyal
    michael = TEST::michael
    benjamin = TEST::Person.new(TEST::benjamin)
    eyal.test::member_of = ["A","B","C"]
    michael.test::member_of = ["A","B"]
    benjamin.test::member_of = ["B","C"]
    
    s = Query.new.select(:s).where(:s,:p,TEST::michael.member_of).execute
    assert_equal Set[michael,eyal], Set.new(s)
    
    s = Query.new.select(:s).where(:s,michael.member_of,michael.member_of).execute
    assert_equal Set[michael,eyal], Set.new(s)
    
  end
end

class TestAssociatedProperty < Test::Unit::TestCase
  include SetupAdapter

  @@eyal = TEST::eyal

  def setup
    super
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
  end

  def test_to_a
    assert_equal ["eyal@cs.vu.nl", "eyal.oren@deri.org"], @@eyal.email
  end

  def test_to_h
    h = {"fe82da4f0b32cd8ca4f1e8eb7683fcb1"=>"eyal@cs.vu.nl", "48ba5c9312b3400d28a72b637b0b3748"=>"eyal.oren@deri.org"}
    assert_equal h, @@eyal.email.to_h
  end

  def test_append
    @@eyal.email = "eyal@cs.vu.nl"
    assert @@eyal.email == "eyal@cs.vu.nl"

    @@eyal.email += "eyal.oren@deri.com"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.com"], @@eyal.email

    # append array
    @@eyal.email = "eyal@cs.vu.nl"
    @@eyal.email += ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @@eyal.email

    # append numbers (doesn't add them together, adds new value)
    @@eyal.age = 30
    @@eyal.age += 35
    assert_equal [30, 35], @@eyal.age
  end

  def test_remove
    @@eyal.email -= "eyal.oren@deri.org"
    assert @@eyal.email == "eyal@cs.vu.nl"
  end

  def test_replace
    # two ways to update values
    # using an index
    @@eyal.email[@@eyal.email.index("eyal.oren@deri.org")] = "eyal.oren@deri.net"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.net"], @@eyal.email

    # using old value
    @@eyal.email["eyal.oren@deri.net"] = "eyal.oren@deri.org"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @@eyal.email

    @@eyal.age = 30
    @@eyal.age[30] += 5
    assert_equal [35], @@eyal.age
  end
  
  def test_delete
    assert_equal "not found", @@eyal.email.delete("nothing"){"not found"}

    # two ways to delete
    @@eyal.email.delete(@@eyal.email.index("eyal@cs.vu.nl"))
    @@eyal.email.delete("eyal.oren@deri.org")
    assert_nil @@eyal.email   # direct predicate removed. unknown predicates return nil

    # delete numbers (non-strings)
    @@eyal.age = 30
    @@eyal.age.delete(30)
    assert @@eyal.age.empty?
  end

  def test_clear
    @@eyal.email.clear
    assert_nil @@eyal.email   # direct predicate removed. unknown predicates return nil
    @@eyal.age.clear
    assert @@eyal.age.empty?  # class predicates return empty RDF::Property
  end

  def test_collect!
    @@eyal.email.collect!{|email| email + "_XX"}
    assert @@eyal.email == ["eyal@cs.vu.nl_XX", "eyal.oren@deri.org_XX"]
  end
  
  def test_delete_if
    @@eyal.email.delete_if{|key, val| val == "eyal@cs.vu.nl"}
    assert_equal ["eyal.oren@deri.org"], @@eyal.email
  end

  def test_equals
    assert @@eyal.eye == "blue"
    # Order doesn't matter when comparing Property to Array
    assert_equal @@eyal.email, ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal @@eyal.email, ["eyal.oren@deri.org","eyal@cs.vu.nl"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @@eyal.email
    assert_equal ["eyal.oren@deri.org","eyal@cs.vu.nl"], @@eyal.email
    
    assert_equal @@eyal.email, TEST::email
    assert_equal TEST::email, @@eyal.email
    assert_equal @@eyal.eye, TEST::eye
    assert_equal TEST::eye, @@eyal.eye
    
    # test property w/o subject
    assert_equal RDF::Property.new(TEST::email), TEST::email
  end
  
  def test_each_index
    @@eyal.email.each_key do |idx|
      assert_not_nil @@eyal.email[idx]
    end
  end
  
  def test_fetch
    idx = @@eyal.email.index("eyal@cs.vu.nl")
    assert_equal "eyal@cs.vu.nl", @@eyal.email.fetch(idx)
    @@eyal.email.delete(idx)
    assert_equal "default", @@eyal.email.fetch(idx,"default")
    assert_equal idx, @@eyal.email.fetch(idx){|i| i}
    assert_raise IndexError do
      @@eyal.email.fetch(idx)
    end
  end

  def test_include?
    assert @@eyal.email.include?("eyal@cs.vu.nl")
  end

  def test_keys
    assert_equal 2, @@eyal.email.keys.size
    assert @@eyal.email.keys.include?("fe82da4f0b32cd8ca4f1e8eb7683fcb1")
    assert @@eyal.email.keys.include?("48ba5c9312b3400d28a72b637b0b3748")
  end

  def test_only
    assert_equal "blue", @@eyal.eye.only
    @@eyal.eye.add "white"
    assert_raise ActiveRdfError do
      @@eyal.eye.only
    end
  end

  def test_lang
    @adapter.load "#{File.dirname(__FILE__)}/../rdfs.nt"
    ls_en = LocalizedString.new('ActiveRdf developer', '@en')
    ls_de = LocalizedString.new('ActiveRdf entwickler', '@de')
    @@eyal.comment = ls_en
    @@eyal.comment.add ls_de

    assert_equal ['en',true], @@eyal.comment.lang('@en').lang
    assert_equal ['de',false], @@eyal.comment.lang('de', false).lang

    assert_equal [ls_en], @@eyal.comment.lang('@en')
    assert_equal @@eyal.comment.lang('@en'), @@eyal.comment.lang('en')   # @en and en should equate

    assert_equal [ls_de], @@eyal.comment.lang('@de')
    assert_equal [ls_en, ls_de], @@eyal.comment

    @@eyal.comment.add LocalizedString.new('ActiveRdf developer', 'en')
    assert_equal 1, @@eyal.comment.lang('en').size      # no duplicates
  end

  def test_datatype
    @adapter.load "#{File.dirname(__FILE__)}/../rdfs.nt"
    t = Time.parse("Tue Jan 20 12:00:00 -0800 2009")
    @@eyal.comment = [1, LocalizedString.new('localized string', '@en'), "string", t]
    assert_equal XSD::integer, @@eyal.comment.datatype(XSD::integer).datatype
    assert_equal [1], @@eyal.comment.datatype(XSD::integer)
    assert_equal ["string"], @@eyal.comment.datatype(XSD::string)   # LocalizedString != XSD::string
    assert_equal [t], @@eyal.comment.datatype(XSD::time)
  end

  def test_length
    assert_equal 2, @@eyal.email.length
    assert_equal 2, @@eyal.email.size
  end

  def test_values_at
    idx1 = @@eyal.email.index("eyal@cs.vu.nl")
    idx2 = @@eyal.email.index("eyal.oren@deri.org")
    assert_equal ["eyal@cs.vu.nl", "eyal.oren@deri.org"], @@eyal.email.values_at(idx1, idx2)
    assert_equal ["eyal@cs.vu.nl"], @@eyal.email.values_at(idx1)
    assert_equal ["eyal.oren@deri.org"], @@eyal.email.values_at(idx2)
  end

  def test_false_value
    @@eyal.email = false
    assert @@eyal.email == false
  end
  
  def test_subproperties
    RDF::Property.new(TEST::relative).save
    RDF::Property.new(TEST::ancestor).save.rdfs::subPropertyOf = TEST::relative
    RDF::Property.new(TEST::parent).save.rdfs::subPropertyOf = TEST::ancestor
    RDF::Property.new(TEST::sibling).save.rdfs::subPropertyOf = TEST::relative
    
    assert_equal Set[TEST::ancestor, TEST::sibling], TEST::relative.subproperties
    assert_equal Set[TEST::ancestor, TEST::parent, TEST::sibling], TEST::relative.subproperties(true)
  end
end