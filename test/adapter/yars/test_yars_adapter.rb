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
# == To-do
#
# * To-do 1
#

require 'test/unit'
require 'active_rdf'
require 'adapter/yars/yars_adapter'

class TestYarsAdapter < Test::Unit::TestCase

	def test_1_initialize
		adapter = YarsAdapter.new({ :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test' })
		assert_not_nil(adapter)
		assert_kind_of(AbstractAdapter, adapter)
		assert_instance_of(YarsAdapter, adapter)
	end
	
end
