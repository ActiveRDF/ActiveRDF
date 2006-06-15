
# = test_equals.rb
#
# Unit Test of resource equality
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
require 'active_rdf/test/common'

class TestResourceEquality < Test::Unit::TestCase
  def setup 
    setup_any
  end
  
  def teardown
    delete_any
  end
  
	def test_equality
		a = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
    NodeFactory.clear
    setup_any
		b = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')

		assert a.object_id != b.object_id
		assert_equal a,b
		assert a == b
		assert a.eql?(b)
		assert !(a.equal? b)
	end
end
