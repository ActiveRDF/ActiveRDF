# = test_create_literal.rb
#
# Unit Test of Literal creation
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
require 'node_factory'

class TestNodeFactoryLiteral < Test::Unit::TestCase

	def test_1_create_literal
		literal = NodeFactory.create_literal("test literal", 'string')
		assert_not_nil(literal)
	end
	
	def test_2_read_value_and_type
		literal = NodeFactory.create_literal('42', 'xsd:integer')
		
		assert_equal('42', literal.value)
		assert_equal("xsd:integer", literal.type)
	end
	
	def test_3_write_value_and_type
		literal = NodeFactory.create_literal('42', 'xsd:integer')
		
		literal.value = '42.0'
		literal.type = 'xsd:decimal'
		
		assert_equal('42.0', literal.value)
		assert_equal('xsd:decimal', literal.type)
	end
	
	def test_4_type
		literal = NodeFactory.create_literal('42', 'xsd:integer')
		assert(literal.kind_of?(Literal))
	end
	
	def test_5_node_subclass
		literal = NodeFactory.create_literal('42', 'xsd:integer')
		assert(literal.kind_of?(Node))
	end
	
end
