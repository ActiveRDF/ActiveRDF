# = test_adapter_add.rb
#
# Unit Test of adapter add method
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

require 'active_rdf'
require 'active_rdf/test/common'

class TestRedlandAdapterAdd < Test::Unit::TestCase

	def setup
    setup_any
	end
	
	def teardown
    delete_any
	end

	def test_add_triples_error_object_nil		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')		
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!(subject, predicate, nil) }
	end
	
	def test_add_triples_error_predicate_nil		
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')		
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!(subject, nil, object) }
	end
	
	def test_add_triples_error_subject_nil
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')		
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!(nil, predicate, object) }
	end
	
	def test_add_triples_error_object_not_node
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!(subject, predicate, 'test') }
	end
	
	def test_add_triples_error_predicate_not_resource
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!(subject, 'test', object) }
	end
	
	def test_add_triples_error_subject_not_resource
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		assert_raise(ActiveRdfError) { NodeFactory.connection.add!('test', predicate, object) }
	end
	
	def test_add_triples_object_literal
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_literal('42', 'xsd:integer')
		assert_nothing_raised(ActiveRdfError) { NodeFactory.connection.add!(subject, predicate, object) }
	end
	
	def test_add_triples_object_resource
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		assert_nothing_raised(ActiveRdfError) { NodeFactory.connection.add!(subject, predicate, object) }
	end
end
