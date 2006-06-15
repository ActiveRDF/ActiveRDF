# = test_resource.rb
#
# Unit Test of Resource instances
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#
require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'

class Person < IdentifiedResource
  setup_any
  set_class_uri 'http://test/Person'
end

TempLocation = "#{Dir.tmpdir}/test"
	
class TestResource < Test::Unit::TestCase
	def setup
		setup_any
	end

	def teardown
		delete_any
	end

	def test_add_predicate_identified_resource
		p = IdentifiedResource.create 'http://test/test'
		assert_nothing_raised { Person.add_predicate p }

		assert Person.predicates.include?('test')
		assert_kind_of IdentifiedResource, Person.predicates['test'] 
		assert_equal 'http://test/test', Person.predicates['test'].uri
	end
	
	def test_add_predicate_to_lowerclass
		assert_nothing_raised { Person.add_predicate 'http://test/test' }

		assert Person.predicates.include?('test')
		assert_kind_of IdentifiedResource, Person.predicates['test'] 
		assert_equal 'http://test/test', Person.predicates['test'].uri
	end

	def test_added_predicate_adds_schema_data
		Person.add_predicate 'http://test/test'
		p = IdentifiedResource.create 'http://test/test'

		# TODO implement
		# assert all_predicates.include?(p)
	end

	def test_use_added_predicate
		Person.add_predicate 'http://test/test'
		c = Person.new 'c'

		assert_nothing_raised { c.test }
		assert_nil c.test
		c.test = 'test-value'
		assert_equal 'test-value', c.test
		assert_nothing_raised { c.save }
	end
  
  
  ## TODO: enable after we get either YARS with delete working, or Redland with save!
	def test_load_added_predicate
    # we cannot run this test in memory
    # TODO: change setup_redland to setup_any (need to fix YARS delete)
    return unless $adapters.include?(:redland)
    NodeFactory.clear
    setup_redland('/tmp/test-save')
    Person.add_predicate 'http://test/test'
    
    uri = 'http://m3pe.org/eyal'
		eyal = Person.create uri
		eyal.test = 'test-value'
		eyal.save

    # clear the cache, reopen the connection
		NodeFactory.clear
    con = setup_redland('/tmp/test-save')
    eyal2 = Person.create uri    
    
    # assert we have a different object, but with equal values
		assert_not_equal eyal.object_id, eyal2.object_id
		assert_equal eyal, eyal2
		assert_equal eyal2.test, 'test-value'

    delete_redland('/tmp/test-save')
	end

	def test_predicate_collision
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_raise(ActiveRdfError) { IdentifiedResource.add_predicate 'http://othernamespace/test' }
	end

end
