# = test_redland_adapter_remove.rb
#
# Unit Test of Redland adapter remove method
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

require 'active_rdf'
require 'adapter/redland/redland_adapter'
require 'active_rdf/test/common'
#require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestRedlandAdapterRemove < Test::Unit::TestCase

	def setup
		NodeFactory.connection :adapter => :redland, :location => :memory, :cache_server => :memory
		@adapter = RedlandAdapter.new :location => :memory
	end
	
	def teardown
    NodeFactory.clear
	end
	
	def test_A_remove_triples_error_object_not_node
		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			@adapter.remove(subject, predicate, 'test')
		}
	end
	
	def test_B_remove_triples_error_predicate_not_resource
		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementRemoveRedlandError) {
			@adapter.remove(subject, 'test', object)
		}
	end
	
	def test_C_remove_triples_error_subject_not_resource
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			@adapter.remove('test', predicate, object)
		}
	end
	
	def test_D_remove_triples_dont_exist
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			assert_equal(0, @adapter.remove(subject, predicate, object))
		}
	end
	
	def test_E_remove_triples_object_literal
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')

		@adapter.add(subject, predicate, object)
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			@adapter.remove(subject, predicate, object)
		}
	end
	
	def test_F_remove_triples_object_resource
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		@adapter.add(subject, predicate, object)
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			@adapter.remove(subject, predicate, object)
		}
	end
	
	def test_G_remove_triples_with_subject_as_wildcard
		subject1 = NodeFactory.create_identified_resource('http://m3pe.org/subject1')
		subject2 = NodeFactory.create_identified_resource('http://m3pe.org/subject2')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		@adapter.add(subject1, predicate, object)
		@adapter.add(subject2, predicate, object)
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			assert_equal(2, @adapter.remove(nil, predicate, object))
		}
	end
	
	def test_H_remove_triples_with_predicate_and_object_as_wildcard
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/predicate1')
		object1 = NodeFactory.create_identified_resource('http://m3pe.org/object')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/predicate2')
		object2 = NodeFactory.create_literal('42', 'xsd:integer')
		
		@adapter.add(subject, predicate1, object1)
		@adapter.add(subject, predicate2, object2)
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			assert_equal(2, @adapter.remove(subject, nil, nil))
		}
	end


end
