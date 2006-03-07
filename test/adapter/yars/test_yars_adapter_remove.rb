# = test_yars_adapter_remove.rb
#
# Unit Test of Yars adapter remove method
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
# * TODO: See again the remove test with nil, I think it'is allowed in redland.
#

require 'test/unit'
require 'active_rdf'
require 'adapter/yars/yars_adapter'

class TestYarsAdapterRemove < Test::Unit::TestCase

	@@adapter = nil

	def setup		
		params = { :adapter => :yars, :host => 'opteron', :port => 8080, :context => 'test_remove' }
		@@adapter = NodeFactory.connection(params) if @@adapter.nil?
	end

	def test_1_remove_triples_error_object_nil
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove(subject, predicate, nil)
		}
	end
	
	def test_2_remove_triples_error_predicate_nil
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove(subject, nil, object)
		}
	end
	
	def test_3_remove_triples_error_subject_nil
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove(nil, predicate, object)
		}
	end
	
	def test_4_remove_triples_error_object_not_node
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove(subject, predicate, 'test')
		}
	end
	
	def test_5_remove_triples_error_predicate_not_resource
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove(subject, 'test', object)
		}
	end
	
	def test_6_remove_triples_error_subject_not_resource
		
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		
		assert_raise(StatementRemoveYarsError) {
			@@adapter.remove('test', predicate, object)
		}
	end
	
#	def test_7_remove_triples_error_triple_dont_exist
#		
#		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
#		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
#		object = NodeFactory.create_literal('42', 'xsd:integer')
#		
#		assert_raise(StatementRemoveYarsError) {
#			@@adapter.remove(subject, predicate, object)
#		}
#	end
	
	def test_8_remove_triples_object_literal
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')

		@@adapter.add(subject, predicate, object)
		@@adapter.save
		
		assert_nothing_raised(StatementRemoveYarsError) {
			@@adapter.remove(subject, predicate, object)
		}
	end
	
	def test_9_remove_triples_object_resource
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		@@adapter.add(subject, predicate, object)
		@@adapter.save
		
		assert_nothing_raised(StatementRemoveYarsError) {
			@@adapter.remove(subject, predicate, object)
		}
	end
end
