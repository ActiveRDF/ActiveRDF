# = test_yars_parse.rb
#
# Unit Test of Yars adapter parsing
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
require 'adapter/yars/yars_adapter'

class YarsAdapter
	def public_match_object s
		scanner = StringScanner.new s
		match_object scanner
	end
end

class TestYarsAdapter < Test::Unit::TestCase
	def setup
		@adapter = YarsAdapter.new
	end

	def test_object_literal_parse
		assert_kind_of Literal, @adapter.public_match_object('""')
		assert_kind_of Literal, @adapter.public_match_object('"literal"')
		assert_kind_of Literal, @adapter.public_match_object('"urn:aoesuta:aesutaeu"')
		assert_kind_of Literal, @adapter.public_match_object('"\""')
		assert_kind_of Literal, @adapter.public_match_object('"te\"st"')
		assert_kind_of Literal, @adapter.public_match_object('"Chandrabose Aravindan and J{\\\\\\\\\\\\\\\"u}rgen Dix and Ilkka Niemel{\\\\\\\\\\\\\\\"a}"')

		assert_raise(NTriplesParsingYarsError) do @adapter.public_match_object('') end
		assert_raise(NTriplesParsingYarsError) do @adapter.public_match_object('"abc') end

		# these wrong literals do not raise an error because of our simplistic 
		# pattern matching. But the database should just not feed us these incorrect 
		# n3 literals. We do not choke (i.e. die) on it, but just return an incorrect (smaller) 
		# substring as literal value.
		#assert_raise(NTriplesParsingYarsError) do @adapter.public_match_object('"abc\"') end
		#assert_raise(NTriplesParsingYarsError) do @adapter.public_match_object('"\"') end
		assert_equal 'abc\\',@adapter.public_match_object('"abc\"').value
		assert_equal 'abc\\',@adapter.public_match_object('"abc\"defaeu').value
		assert_equal '\\',@adapter.public_match_object('"\"').value
	end

end
