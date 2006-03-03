# = test_redland_adapter.rb
#
# Unit Test of Redland adapter
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

	def test_1_initialize
		adapter = RedlandAdapter.new
		assert_not_nil(adapter)
		assert(adapter.kind_of?(AbstractAdapter))
		assert(adapter.instance_of?(RedlandAdapter))
	end
	
	def test_2_save
		adapter = RedlandAdapter.new
		
		subject = NodeFactory.create_basic_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_basic_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_basic_identified_resource('http://m3pe.org/object')
		
		adapter.add(subject, predicate, object)
		
		assert_nothing_raised(RedlandAdapterError) {
			adapter.save
		}
	end
	
end