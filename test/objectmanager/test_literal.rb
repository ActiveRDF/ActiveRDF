# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require "#{File.dirname(__FILE__)}/../common"

class TestLiteral < Test::Unit::TestCase
  def setup
		ConnectionPool.clear
    @adapter = get_adapter
  end

  def teardown
  end

  def test_xsd_string
    test = Literal.typed('test', XSD::string)
    assert_equal '"test"^^<http://www.w3.org/2001/XMLSchema#string>', test.to_ntriple
  end

  def test_automatic_conversion
    # infer string
    test = 'test'
    assert_equal '"test"^^<http://www.w3.org/2001/XMLSchema#string>', test.to_ntriple

    # infer integer
    test = 18
    assert_equal '"18"^^<http://www.w3.org/2001/XMLSchema#integer>', test.to_ntriple

    # infer boolean
    test = true
    assert_equal '"true"^^<http://www.w3.org/2001/XMLSchema#boolean>', test.to_ntriple
  end
  
  def test_equality
    test1 = 'test'
    test2 = Literal.typed('test', XSD::string)  
    assert_equal test2.to_ntriple, test1.to_ntriple
  end
  
  def test_language_tag
    cat = 'cat'
    cat_en = LocalizedString.new('cat', '@en')
    assert_equal '"cat"@en', cat_en.to_ntriple
    assert_not_equal cat.to_ntriple, cat_en.to_ntriple

    assert_equal '"dog"@en-GB', LocalizedString.new('dog', '@en-GB').to_ntriple
    assert_equal '"dog"@en@test', LocalizedString.new('dog', '@en@test').to_ntriple
  end
end
