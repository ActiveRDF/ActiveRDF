$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'directaccess/direct_access'

class TestDirectAccess < Test::Unit::TestCase
  
  def setup
    # load Redland Adapter
    ConnectionPool.clear
    adapter = load_adapter(:redland)
    adapter.load("#{File.dirname(__FILE__)}/../test_person_data.nt")
  end
  
  @@eyal = "<http://activerdf.org/test/eyal>"
  @@age = "<http://activerdf.org/test/age>"
  @@age_number = "18"
  
  
  def test_query
    # test SELECT query
    assert_not_equal nil, DirectAccess.sparql_query("SELECT ?p ?o WHERE {#{@@eyal} ?p ?o}")
    assert_not_equal nil, DirectAccess.sparql_query("SELECT ?o WHERE {#{@@eyal} #{@@age} ?o}")
    assert_raise(ActiveRdfError) {DirectAccess.sparql_query(nil)}
    assert_raise(ActiveRdfError) {DirectAccess.sparql_query(123)}
    
    # test return value
    assert_equal Array, DirectAccess.sparql_query("SELECT ?o WHERE {#{@@eyal} #{@@age} ?o}",:array).class
    assert_equal String, DirectAccess.sparql_query("SELECT ?p WHERE {#{@@eyal} ?p '27'}")[0].class
  end

  def test_propertylist
    # test creation
    assert_equal PropertyList, DirectAccess.find_all_by_subject_and_predicate(@@eyal, @@age).class
    assert_raise(ActiveRdfError) {DirectAccess.find_all_by_subject_and_predicate(nil, nil)}
    
    # test add
    pl = DirectAccess.find_all_by_subject_and_predicate(@@eyal, @@age)
    assert_equal false, pl.include?(@@age_number)
    assert_equal true, (pl << @@age_number)
    assert_equal true, pl.include?(@@age_number)
    
    # test remove
    assert_equal true, (pl.remove(@@age_number))
    assert_equal false, pl.include?(@@age_number)
    assert_equal true, (pl.remove)
    assert_equal 0, pl.size
    assert_equal 0, DirectAccess.find_all_by_subject_and_predicate(@@eyal, @@age).size
    
    # test replace
    pl << "123"
    assert_equal true, pl.replace("123", @@age_number)    
  end
end
