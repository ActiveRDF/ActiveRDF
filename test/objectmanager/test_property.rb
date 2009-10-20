require 'test/unit'
require 'active_rdf'
require 'set'
require File.dirname(File.expand_path(__FILE__)) + '/../common'

class TestProperty < Test::Unit::TestCase
  include SetupAdapter

  def test_to_ary
    p = RDF::Property.new(TEST::age)
    assert !p.respond_to?(:to_ary)

    p = RDF::Property.new(TEST::age, TEST::eyal)
    assert p.respond_to?(:to_ary)
  end

  def test_retrieve_a_triple_with_property
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    @adapter.load "#{File.dirname(__FILE__)}/../test_person2_data.nt"
    eyal = TEST::eyal
    age = 27
    michael = TEST::michael
    michael.age = age
    benjamin = TEST::Person.new(TEST::benjamin)

    eyal.test::member_of = ["A","B","C"]
    michael.test::member_of = ["A","B"]
    benjamin.test::member_of = ["B","C"]

    s = Query.new.select(:s).where(:s,TEST::member_of,eyal.member_of).execute
    assert_equal Set[eyal], Set.new(s)

    s = Query.new.select(:s).where(:s,TEST::member_of,michael.member_of).execute
    assert_equal Set[eyal,michael], Set.new(s)

    s = Query.new.select(:s).where(:s,TEST::member_of,benjamin.member_of).execute
    assert_equal Set[eyal,benjamin], Set.new(s)

    p = RDF::Property.new(TEST::member_of, michael)
    # Property will act as set of values in the object clause when @subject set
    assert_equal Set[eyal,michael], Set.new(Query.new.distinct(:s).where(:s, p, p).execute)
  end
end

class TestAssociatedProperty < Test::Unit::TestCase
  include SetupAdapter

  def setup
    super
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    @email = RDF::Property.new(TEST::email,TEST::eyal)
    @age = RDF::Property.new(TEST::age,TEST::eyal)
  end

  def test_to_a
    assert_equal Set["eyal@cs.vu.nl", "eyal.oren@deri.org"], Set.new(@email)
  end

  def test_to_ary
    assert @email.respond_to?(:to_ary)

    # when comparing arrays, order matters
    assert ["eyal@cs.vu.nl", "eyal.oren@deri.org"] != @email.to_ary

    assert_equal Set["eyal@cs.vu.nl", "eyal.oren@deri.org"], Set.new(@email.to_ary)
  end

  def test_to_h
    h = {"fe82da4f0b32cd8ca4f1e8eb7683fcb1"=>"eyal@cs.vu.nl", "48ba5c9312b3400d28a72b637b0b3748"=>"eyal.oren@deri.org"}
    assert_equal h, @email.to_h
  end

  def test_add
    @email.replace "eyal@cs.vu.nl"
    assert_equal ["eyal@cs.vu.nl"], @email

    @email.add "eyal.oren@deri.com"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.com"], @email

    @email.replace "eyal@cs.vu.nl"
    @email.add ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @email

    #  numbers (doesn't add them together, adds new value)
    @age.replace 30
    @age += 35
    assert_equal [30, 35], @age
  end

  def test_remove
    @email -= "eyal.oren@deri.org"
    assert ["eyal@cs.vu.nl"], @email
  end

  def test_replace
    # two ways to update values
    # using an index
    @email[@email.index("eyal.oren@deri.org")] = "eyal.oren@deri.net"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.net"], @email

    # using old value
    @email["eyal.oren@deri.net"] = "eyal.oren@deri.org"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @email

    @age.replace 30
    @age[30] += 5
    assert_equal [35], @age
  end

  def test_delete
    assert_equal "not found", @email.delete("nothing"){"not found"}

    # two ways to delete
    @email.delete(@email.index("eyal@cs.vu.nl"))
    @email.delete("eyal.oren@deri.org")
    assert_equal 0, @email.size

    # delete numbers
    assert_equal 1, @age.size
    @age.delete(27)
    assert @age.empty?
  end

  def test_clear
    @email.clear
    assert @email.empty?  # class predicates return empty RDF::Property
  end

  def test_collect!
    @email.collect!{|email| email + "_XX"}
    assert @email == ["eyal@cs.vu.nl_XX", "eyal.oren@deri.org_XX"]
  end

  def test_delete_if
    @email.delete_if{|key, val| val == "eyal@cs.vu.nl"}
    assert_equal ["eyal.oren@deri.org"], @email
  end

  def test_equals
    assert TEST::eyal.eye == "blue"
    # Order doesn't matter when comparing Property to Array
    assert_equal @email, ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal @email, ["eyal.oren@deri.org","eyal@cs.vu.nl"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @email
    assert_equal ["eyal.oren@deri.org","eyal@cs.vu.nl"], @email

    assert_equal @email, TEST::email
    assert_equal TEST::email, @email
    assert_equal TEST::eyal.eye, TEST::eye
    assert_equal TEST::eye, TEST::eyal.eye

    # test property w/o subject
    assert_equal RDF::Property.new(TEST::email), TEST::email
  end

  def test_each_index
    @email.each_key do |idx|
      assert_not_nil @email[idx]
    end
  end

  def test_fetch
    idx = @email.index("eyal@cs.vu.nl")
    assert_equal "eyal@cs.vu.nl", @email.fetch(idx)
    @email.delete(idx)
    assert_equal "default", @email.fetch(idx,"default")
    assert_equal idx, @email.fetch(idx){|i| i}
    assert_raise IndexError do
      @email.fetch(idx)
    end
  end

  def test_include?
    assert @email.include?("eyal@cs.vu.nl")
  end

  def test_keys
    assert_equal 2, @email.keys.size
    assert @email.keys.include?("fe82da4f0b32cd8ca4f1e8eb7683fcb1")
    assert @email.keys.include?("48ba5c9312b3400d28a72b637b0b3748")
  end

  def test_only
    assert_equal "blue", TEST::eyal.eye.only
    TEST::eyal.eye.add "white"
    assert_raise ActiveRdfError do
      TEST::eyal.eye.only
    end
  end

  def test_lang
    @adapter.load "#{File.dirname(__FILE__)}/../rdfs.nt"
    ls_en = LocalizedString.new('ActiveRDF developer', '@en')
    ls_de = LocalizedString.new('ActiveRDF entwickler', '@de')
    TEST::eyal.comment = ls_en
    TEST::eyal.comment.add ls_de

    assert_equal ['en',true], TEST::eyal.comment.lang('@en').lang
    assert_equal ['de',false], TEST::eyal.comment.lang('de', false).lang

    assert_equal [ls_en], TEST::eyal.comment.lang('@en')
    assert_equal TEST::eyal.comment.lang('@en'), TEST::eyal.comment.lang('en')   # @en and en should equate

    assert_equal [ls_de], TEST::eyal.comment.lang('@de')
    assert_equal [ls_en, ls_de], TEST::eyal.comment

    TEST::eyal.comment.add LocalizedString.new('ActiveRDF developer', 'en')
    assert_equal 1, TEST::eyal.comment.lang('en').size      # no duplicates
  end

  def test_datatype
    @adapter.load "#{File.dirname(__FILE__)}/../rdfs.nt"
    t = Time.parse("Tue Jan 20 12:00:00 -0800 2009")
    TEST::eyal.comment = [1, LocalizedString.new('localized string', '@en'), "string", t]
    assert_equal [1], TEST::eyal.comment.datatype(XSD::integer)
    assert_equal XSD::integer, TEST::eyal.comment.datatype(XSD::integer).datatype
    assert_equal ["string"], TEST::eyal.comment.datatype(XSD::string)   # LocalizedString != XSD::string
    assert_equal [t], TEST::eyal.comment.datatype(XSD::time)
  end

  def test_context
    if @adapter.contexts?
      @adapter.load "#{File.dirname(__FILE__)}/../test_person2_data.nt"
      context_one = RDFS::Resource.new("file:#{File.dirname(__FILE__)}/../test_person_data.nt")
      context_two = RDFS::Resource.new("file:#{File.dirname(__FILE__)}/../test_person2_data.nt")
      assert_equal [27], RDF::Property.new(TEST::age,TEST::eyal).context(context_one)
      assert_equal   [], RDF::Property.new(TEST::age,TEST::eyal).context(context_two)
      assert_equal [30], RDF::Property.new(TEST::age,TEST::michael).context(context_two)
    end
  end

  def test_length
    assert_equal 2, @email.length
    assert_equal 2, @email.size
  end

  def test_values_at
    idx1 = @email.index("eyal@cs.vu.nl")
    idx2 = @email.index("eyal.oren@deri.org")
    assert_equal ["eyal@cs.vu.nl", "eyal.oren@deri.org"], @email.values_at(idx1, idx2)
    assert_equal ["eyal@cs.vu.nl"], @email.values_at(idx1)
    assert_equal ["eyal.oren@deri.org"], @email.values_at(idx2)
  end

  def test_false_value
    @email = false
    assert @email == false
  end

  if $activerdf_internal_reasoning
    def test_sub_super_properties
      RDF::Property.new(TEST::relative).save
      RDF::Property.new(TEST::ancestor).save.rdfs::subPropertyOf = TEST::relative
      RDF::Property.new(TEST::parent).save.rdfs::subPropertyOf = TEST::ancestor
      RDF::Property.new(TEST::sibling).save.rdfs::subPropertyOf = TEST::relative
  
      assert_equal Set[TEST::ancestor, TEST::parent, TEST::sibling], Set.new(TEST::relative.sub_properties)
      assert_equal Set[TEST::relative, TEST::ancestor], Set.new(TEST::parent.super_properties) 
    end
  end
end