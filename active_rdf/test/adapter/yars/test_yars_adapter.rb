# = test_yars_adapter.rb
#
# Unit Test of Yars adapter
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
require 'adapter/yars/yars_adapter'

class TestYarsAdapter < Test::Unit::TestCase

	def test_A_initialize
    adapter = setup_yars
		assert_not_nil(adapter)
		assert_kind_of(AbstractAdapter, adapter)
		assert_instance_of(YarsAdapter, adapter)
	end
	
	def test_B_initialise_with_no_parameters
		adapter = YarsAdapter.new
		assert_not_nil(adapter)
		assert_kind_of(AbstractAdapter, adapter)
		assert_instance_of(YarsAdapter, adapter)
	end
	
	def test_C_error_initialise_with_nil_parameter
		assert_raise(YarsError) {
			adapter = YarsAdapter.new(nil)
		}
	end

	def test_query_string_escaped
		adapter = setup_yars
		s = '@prefix ql: <http://www.w3.org/2004/12/ql#> .  <> ql:select { ?s ?p ?o . };
			ql:where { ?s ?p ";/?:@&=+$,\\[\\]" . } .'
		assert_nothing_raised { adapter.query s }
	end
	
end
