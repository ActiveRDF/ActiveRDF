# = test_resource.rb
#
# Unit Test of Resource
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
require 'test/adapter/yars/manage_yars_db'
require 'test/adapter/redland/manage_redland_db'
DB_HOST = 'opteron'

class A < IdentifiedResource
	set_class_uri 'http://test/A'
end
	
class TestResource < Test::Unit::TestCase
	$logger.level = Logger::DEBUG

	def setup
		setup_yars 'test_resource'
		NodeFactory.connection :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_resource'
	end

	def teardown
		delete_yars 'test_resource'
	end

	def test_add_predicate_identified_resource
		p = IdentifiedResource.create 'http://test/test'
		assert_nothing_raised { A.add_predicate p }

		assert A.predicates.include?('test')
		assert_kind_of IdentifiedResource, A.predicates['test'] 
		assert_equal 'http://test/test', A.predicates['test'].uri
	end
	
	def test_add_predicate_to_lowerclass
		assert_nothing_raised { A.add_predicate 'http://test/test' }

		assert A.predicates.include?('test')
		assert_kind_of IdentifiedResource, A.predicates['test'] 
		assert_equal 'http://test/test', A.predicates['test'].uri
	end

	def test_added_predicate_adds_schema_data
		A.add_predicate 'http://test/test'
		p = IdentifiedResource.create 'http://test/test'

		# TODO implement
		# assert all_predicates.include?(p)
	end

	def test_a_use_added_predicate
		A.add_predicate 'http://test/test'
		c = A.new 'c'

		assert_nothing_raised { c.test }
		assert_nil c.test
		c.test = 'test-value'
		assert_equal 'test-value', c.test
		assert_nothing_raised { c.save }
	end

	def test_b_use_load_added_predicate
		A.add_predicate 'http://test/test'
		c = A.new 'c'
		c.test = 'test-value'
		c.save

		NodeFactory.clear
		d = A.new 'c'
		assert_not_equal c.object_id, d.object_id
		assert_equal c,d
		assert_equal 'test-value', d.test
	end

	def test_add_predicate_collision
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_nothing_raised { IdentifiedResource.add_predicate 'http://test/test' }
		assert_raise(ActiveRdfError) { IdentifiedResource.add_predicate 'http://othernamespace/test' }
	end

end
