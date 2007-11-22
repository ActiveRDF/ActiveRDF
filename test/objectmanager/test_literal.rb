# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require "#{File.dirname(__FILE__)}/../common"

class TestLiteral < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
    @adapter = get_read_only_adapter
  end

  def teardown
  end

  def test_xsd_string
    # test with explicit datatype
    test = Literal.new('test', XSD::string)
    assert_equal '"test"^^<http://www.w3.org/2001/XMLSchema#string>', test.to_s
  end

  def test_automatic_conversion
    # infer string
    test = Literal.new('test')
    assert_equal '"test"^^<http://www.w3.org/2001/XMLSchema#string>', test.to_s

    # infer integer
    test = Literal.new(18)
    assert_equal '"18"^^<http://www.w3.org/2001/XMLSchema#integer>', test.to_s

    # infer boolean
    test = Literal.new(true)
    assert_equal '"true"^^<http://www.w3.org/2001/XMLSchema#boolean>', test.to_s
  end
  
  def test_equality
    test1 = Literal.new('test')
    test2 = Literal.new('test', XSD::string)  
    assert_equal test2.to_s, test1.to_s
  end
  
  def test_language_tag
    cat = Literal.new('cat')
    cat_en = Literal.new('cat', '@en')
    assert_equal '"cat"@en', cat_en.to_s
    assert_not_equal cat.to_s, cat_en.to_s

    assert_equal '"dog"@en-GB', Literal.new('dog', '@en-GB').to_s
    assert_equal '"dog"@en@test', Literal.new('dog', '@en@test').to_s
  end
end
