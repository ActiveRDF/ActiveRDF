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

class TestClassModel < Test::Unit::TestCase
	def setup
		setup_any
		require 'active_rdf/test/node_factory/person'
	end
	
	def teardown
		delete_any
	end

	def test_class_model
    return unless load_test_data
    
    # test if Person class defined, and whether it has right predicates
    assert defined?(Person)    
    assert_equal ['name', 'age', 'knows'].sort, Person.predicates.keys.sort
    
    eyal = Person.create 'http://eyaloren.org'
    assert ['name','age','knows'].sort, eyal.attributes.sort
	end	
end