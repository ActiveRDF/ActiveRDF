# = test_redland_adapter_add.rb
#
# Unit Test of Redland adapter add method
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
# == To-do
#
# * To-do 1
#

require 'test/unit'
require 'active_rdf'
require 'adapter/redland/redland_adapter'

class TestRedlandAdapter < Test::Unit::TestCase

	def test_1_add_triples_error_object_nil
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add(subject, predicate, nil)
		}
	end
	
	def test_2_add_triples_error_predicate_nil
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add(subject, nil, object)
		}
	end
	
	def test_3_add_triples_error_subject_nil
		adapter = RedlandAdapter.new
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add(nil, predicate, object)
		}
	end
	
	def test_4_add_triples_error_object_not_node
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add(subject, predicate, 'test')
		}
	end
	
	def test_5_add_triples_error_predicate_not_resource
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add(subject, 'test', object)
		}
	end
	
	def test_6_add_triples_error_subject_not_resource
		adapter = RedlandAdapter.new
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionRedlandError) {
			adapter.add('test', predicate, object)
		}
	end
	
	def test_7_add_triples_object_literal
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_nothing_raised(StatementAdditionRedlandError) {
			adapter.add(subject, predicate, object)
		}
	end
	
	def test_8_add_triples_object_resource
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_nothing_raised(StatementAdditionRedlandError) {
			adapter.add(subject, predicate, object)
		}
	end
end