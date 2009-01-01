require 'test/unit'
require 'active_rdf'

class TestProperty < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
    @adapter = ConnectionPool.add(:type => :redland, :location => 'sqlite')
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    Namespace.register(:test, 'http://activerdf.org/test/')

    @eyal = TEST::eyal
  end

  def test_to_a
    assert_equal ["eyal@cs.vu.nl", "eyal.oren@deri.org"], @eyal.email
  end

  def test_to_h
    h = {"fe82da4f0b32cd8ca4f1e8eb7683fcb1"=>"eyal@cs.vu.nl", "48ba5c9312b3400d28a72b637b0b3748"=>"eyal.oren@deri.org"}
    assert_equal h, @eyal.email.to_h
  end

  def test_append
    @eyal.email = "eyal@cs.vu.nl"
    assert @eyal.email == "eyal@cs.vu.nl"

    @eyal.email += "eyal.oren@deri.com"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.com"], @eyal.email

    # append array
    @eyal.email = "eyal@cs.vu.nl"
    @eyal.email += ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @eyal.email

    # append numbers (doesn't add them together, adds new value)
    @eyal.age = 30
    @eyal.age += 35
    assert_equal [30, 35], @eyal.age
  end

  def test_remove
    @eyal.email -= "eyal.oren@deri.org"
    assert @eyal.email == "eyal@cs.vu.nl"
  end

  def test_replace
    # two ways to update values
    # using an index
    @eyal.email[@eyal.email.index("eyal.oren@deri.org")] = "eyal.oren@deri.net"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.net"], @eyal.email

    # using old value
    @eyal.email["eyal.oren@deri.net"] = "eyal.oren@deri.org"
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @eyal.email

    @eyal.age = 30
    @eyal.age[30] += 5
    assert_equal [35], @eyal.age
  end
  
  def test_delete
    assert_equal "not found", @eyal.email.delete("nothing"){"not found"}

    # two ways to delete
    @eyal.email.delete(@eyal.email.index("eyal@cs.vu.nl"))
    @eyal.email.delete("eyal.oren@deri.org")
    assert_nil @eyal.email   # direct predicate removed. unknown predicates return nil

    # delete numbers (non-strings)
    @eyal.age = 30
    @eyal.age.delete(30)
    assert @eyal.age.empty?
  end

  def test_clear
    @eyal.email.clear
    assert_nil @eyal.email   # direct predicate removed. unknown predicates return nil
    @eyal.age.clear
    assert @eyal.age.empty?  # class predicates return empty RDF::Property
  end

  def test_collect!
    @eyal.email.collect!{|email| email + "_XX"}
    assert @eyal.email == ["eyal@cs.vu.nl_XX", "eyal.oren@deri.org_XX"]
  end
  
  def test_delete_if
    @eyal.email.delete_if{|key, val| val == "eyal@cs.vu.nl"}
    assert_equal ["eyal.oren@deri.org"], @eyal.email
  end

  def test_equals
    assert @eyal.eye == "blue"
    # Order doesn't matter when comparing Property to Array
    assert_equal @eyal.email, ["eyal@cs.vu.nl","eyal.oren@deri.org"]
    assert_equal @eyal.email, ["eyal.oren@deri.org","eyal@cs.vu.nl"]
    assert_equal ["eyal@cs.vu.nl","eyal.oren@deri.org"], @eyal.email
    assert_equal ["eyal.oren@deri.org","eyal@cs.vu.nl"], @eyal.email
    
    assert_equal @eyal.email, TEST::email
    assert_equal TEST::email, @eyal.email
    assert_equal @eyal.eye, TEST::eye
    assert_equal TEST::eye, @eyal.eye
    
    # test property w/o subject
    assert_equal RDF::Property.new(TEST::email), TEST::email
  end
  
  def test_each_index
    @eyal.email.each_key do |idx|
      assert_not_nil @eyal.email[idx]
    end
  end
  
  def test_fetch
    idx = @eyal.email.index("eyal@cs.vu.nl")
    assert_equal "eyal@cs.vu.nl", @eyal.email.fetch(idx)
    @eyal.email.delete(idx)
    assert_equal "default", @eyal.email.fetch(idx,"default")
    assert_equal idx, @eyal.email.fetch(idx){|i| i}
    assert_raise IndexError do
      @eyal.email.fetch(idx)
    end
  end

  def test_include?
    assert @eyal.email.include?("eyal@cs.vu.nl")
  end

  def test_keys
    assert_equal 2, @eyal.email.keys.size
    assert @eyal.email.keys.include?("fe82da4f0b32cd8ca4f1e8eb7683fcb1")
    assert @eyal.email.keys.include?("48ba5c9312b3400d28a72b637b0b3748")
  end

  def test_length
    assert_equal 2, @eyal.email.length
    assert_equal 2, @eyal.email.size
  end

  def test_values_at
    idx1 = @eyal.email.index("eyal@cs.vu.nl")
    idx2 = @eyal.email.index("eyal.oren@deri.org")
    assert_equal ["eyal@cs.vu.nl", "eyal.oren@deri.org"], @eyal.email.values_at(idx1, idx2)
    assert_equal ["eyal@cs.vu.nl"], @eyal.email.values_at(idx1)
    assert_equal ["eyal.oren@deri.org"], @eyal.email.values_at(idx2)
  end

  def test_false_value
    @eyal.email = false
    assert @eyal.email == false
  end
end