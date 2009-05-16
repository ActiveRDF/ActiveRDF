# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'

class TestLiteral < Test::Unit::TestCase
  def test_automatic_conversion
    test = 'test'
    assert_equal '"test"^^<http://www.w3.org/2001/XMLSchema#string>', test.to_literal_s

    # infer integer
    test = 18
    assert_equal '"18"^^<http://www.w3.org/2001/XMLSchema#integer>', test.to_literal_s

    # infer float
    test = 3.1415
    assert_equal '"3.1415"^^<http://www.w3.org/2001/XMLSchema#double>', test.to_literal_s

    # infer boolean
    test = true
    assert_equal '"true"^^<http://www.w3.org/2001/XMLSchema#boolean>', test.to_literal_s

    # infer Time
    test = Time.parse("Sat Nov 22 00:33:23 Z 2008").utc
    assert_equal '"2008-11-22T00:33:23Z"^^<http://www.w3.org/2001/XMLSchema#time>', test.to_literal_s

    $activerdf_without_datatype = true
    assert_equal '"2008-11-22T00:33:23Z"', test.to_literal_s
    $activerdf_without_datatype = false
  end

  def test_equality
    test1 = 'test'
    test2 = RDFS::Literal.typed('test', XSD::string)
    assert_equal test2.to_literal_s, test1.to_literal_s
  end

  def test_language_tag
    cat = 'cat'
    cat_en = LocalizedString.new('cat', '@en')
    assert_equal '"cat"@en', cat_en.to_literal_s
    assert_not_equal cat.to_literal_s, cat_en.to_literal_s

    assert_equal '"dog"@en-GB', LocalizedString.new('dog', '@en-GB').to_literal_s
    assert_equal '"dog"@en@test', LocalizedString.new('dog', '@en@test').to_literal_s
  end
end

class TestLocalizedString < Test::Unit::TestCase
  def setup
    @ls_en = LocalizedString.new('localized string','@en')
  end

  def test_lang
    assert_equal 'en', @ls_en.lang
    assert_equal @ls_en, LocalizedString.new('localized string','en')
  end

  def test_equality
    assert @ls_en == "localized string"
    assert @ls_en == LocalizedString.new('localized string','en')
    assert @ls_en != LocalizedString.new('localized string','@gb')
  end

  def test_to_literal_s
    assert_equal '"localized string"@en', @ls_en.to_literal_s
    $activerdf_without_datatype = true
    assert_equal '"localized string"', @ls_en.to_literal_s
    $activerdf_without_datatype = false
  end
end
