# = test_yars_adapter_add.rb
#
# Unit Test of Yars adapter add method
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
require 'adapter/yars/yars_adapter'

class TestYarsAdapterAdd < Test::Unit::TestCase

	@@params = { :adapter => :yars, :host => 'opteron', :port => 8080, :context => 'test_add' }

	def test_1_add_triples_error_object_nil
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add(subject, predicate, nil)
		}
	end
	
	def test_2_add_triples_error_predicate_nil
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add(subject, nil, object)
		}
	end

	def test_3_add_triples_error_subject_nil
		adapter = YarsAdapter.new(@@params)
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add(nil, predicate, object)
		}
	end

	def test_4_add_triples_error_object_not_node
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add(subject, predicate, 'test')
		}
	end
	
	def test_5_add_triples_error_predicate_not_resource
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add(subject, 'test', object)
		}
	end
	
	def test_6_add_triples_error_subject_not_resource
		adapter = YarsAdapter.new(@@params)
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementAdditionYarsError) {
			adapter.add('test', predicate, object)
		}
	end
	
	def test_7_add_triples_object_literal
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_nothing_raised(StatementAdditionYarsError) {
			adapter.add(subject, predicate, object)
		}
	end
	
	def test_8_add_triples_object_resource
		adapter = YarsAdapter.new(@@params)
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_nothing_raised(StatementAdditionYarsError) {
			adapter.add(subject, predicate, object)
		}
	end
end
