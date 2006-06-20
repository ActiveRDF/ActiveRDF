# = test_adapter_remove.rb
#
# Unit Test of adapter remove method
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

require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'

class TestAdapterRemove < Test::Unit::TestCase

	def setup
		@adapter = setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_remove_triples_without_nodes
		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		assert_raise(ActiveRdfError) { @adapter.remove!(subject, predicate, 'test') }
		assert_raise(ActiveRdfError) { @adapter.remove!(subject, 'test', object) }
		assert_raise(ActiveRdfError) { @adapter.remove!('test', predicate, object)	}
	end
	
	def test_remove_non_existing_triples
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_delete(subject, predicate, object)
	
		@adapter.add(subject, predicate, object)
		assert_delete(subject, predicate, object)
	
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		@adapter.add(subject, predicate, object)		
		assert_delete(subject, predicate, object)
	end
	
	def test_remove_triples_with_wildcards
		subject1 = NodeFactory.create_identified_resource('http://m3pe.org/subject1')
		subject2 = NodeFactory.create_identified_resource('http://m3pe.org/subject2')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		@adapter.add(subject1, predicate, object)
		@adapter.add(subject2, predicate, object)
		
		assert_delete(nil, predicate, object)
		assert_delete(nil, predicate, object)	
    
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/predicate1')
		object1 = NodeFactory.create_identified_resource('http://m3pe.org/object')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/predicate2')
		object2 = NodeFactory.create_literal('42', 'xsd:integer')
		
		@adapter.add(subject1, predicate1, object1)
		@adapter.add(subject1, predicate2, object2)		
		assert_delete(subject1, nil, nil)
	  
		@adapter.add(subject1, predicate, object)
		@adapter.add(subject2, predicate, object)    
		assert_delete(nil, nil, nil)
	end

	private 

	def assert_delete(s,p,o)
		assert @adapter.remove(s,p,o)
		
		# verify if deletion worked
		s = :s if s.nil?
		p = :p if p.nil?
		o = :o if o.nil?
		
		qe = QueryEngine.new
		qe.add_binding_variables :o
		qe.add_condition s,p,:o
		objects = qe.execute
		
		# querying for all objects s,p,o and verifying that the deleted object is not included in results
		assert !objects.include?(o)
	end

end
