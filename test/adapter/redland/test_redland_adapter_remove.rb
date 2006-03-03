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
# == To-do
#
# * To-do 1
#

require 'test/unit'
require 'active_rdf'
require 'adapter/redland/redland_adapter'

class TestRedlandAdapter < Test::Unit::TestCase

	def setup
		# Load the data file
		system("cd /tmp; rm test-store*")
	end

	def test_1_remove_triples_error_object_nil
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(subject, predicate, nil)
		}
	end
	
	def test_2_remove_triples_error_predicate_nil
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(subject, nil, object)
		}
	end
	
	def test_3_remove_triples_error_subject_nil
		adapter = RedlandAdapter.new
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(nil, predicate, object)
		}
	end
	
	def test_4_remove_triples_error_object_not_node
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(subject, predicate, 'test')
		}
	end
	
	def test_5_remove_triples_error_predicate_not_resource
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(subject, 'test', object)
		}
	end
	
	def test_6_remove_triples_error_subject_not_resource
		adapter = RedlandAdapter.new
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove('test', predicate, object)
		}
	end
	
	def test_7_remove_triples_error_triple_dont_exist
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_raise(StatementRemoveRedlandError) {
			adapter.remove(subject, predicate, object)
		}
	end
	
	def test_8_remove_triples_object_literal
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')

		adapter.add(subject, predicate, object)
		adapter.save
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			adapter.remove(subject, predicate, object)
		}
	end
	
	def test_9_remove_triples_object_resource
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		adapter.add(subject, predicate, object)
		adapter.save
		
		assert_nothing_raised(StatementRemoveRedlandError) {
			adapter.remove(subject, predicate, object)
		}
	end
end