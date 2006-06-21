# Unit Test of Logger
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

class TestLogger < Test::Unit::TestCase
	def setup
	   setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_logger
		assert !$logger.nil?
		assert_kind_of Logger, $logger
	end
end