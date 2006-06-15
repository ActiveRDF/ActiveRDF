# Unit Test of subclassing IdentifiedResource

require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'


class TestResource < Test::Unit::TestCase
  def setup
    setup_any
  end
  
  def teardown
    delete_any
  end
  
#  def test_subclass
#    # subclassing IdentifiedResource is ok
#     assert_nothing_raised do
#      eval 'class Test < IdentifiedResource; end'
#     end
#  
#    # error if trying to instantiate subclass when no class URI given
#    assert_raise(ActiveRdfError) do
#      eval "class Test < IdentifiedResource; end; Test.create 'abc'"
#    end
#    
#    assert_nothing_raised do
#      eval "class Test < IdentifiedResource; set_class_uri 'uri'; end; Test.create 'abc'"
#    end
#  end
  
#  def test_using_undefined_predicate
#    eyal = IdentifiedResource.create 'uri:eyal'
#    assert_raise ActiveRdfError { eyal.undefined_predicate = 'value' }
#  end
end