
# = test_identified_resource.rb
#
# Unit Test of Literal
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

class TestLiteral < Test::Unit::TestCase
	
	def test_eql
		a = Literal.create 'abc'
		b = Literal.create 'abc'
		c = Literal.create 'cde'
		assert_equal a,b
		assert_not_equal a,c
	end
	
end
