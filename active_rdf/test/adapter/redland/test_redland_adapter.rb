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

require 'test/unit'
require 'active_rdf'
require 'active_rdf/test/common'
require 'fileutils'

class TestRedlandAdapter < Test::Unit::TestCase
	def setup
		@connection = NodeFactory.connection :adapter => :redland, :location => :memory
	end

	def teardown
		NodeFactory.clear
	end

	def test_in_memory
		assert_not_nil(@connection)
		assert_kind_of(AbstractAdapter, @connection)
		assert_instance_of(RedlandAdapter, @connection)
	end
	
	def test_on_bdb
    # removing memory connection
    NodeFactory.clear
    
    # initialising bdb connection
		connection = NodeFactory.connection(:adapter => :redland, :location => "#{Dir.tmpdir}/test-redland")
  
		assert_not_nil(connection)
		assert_kind_of(AbstractAdapter, connection)
		assert_instance_of(RedlandAdapter, connection)
	
		Dir.chdir(Dir.tmpdir) do
			redland_files = 'test-redland-*.db'
			assert Dir.glob(redland_files).size == 4
			FileUtils.rm Dir.glob(redland_files)
		end		
	end
end
