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
require "#{File.dirname(__FILE__)}/manage_yars_db"

class YarsAdapter
	def public_match_object s
		scanner = StringScanner.new s
		match_object scanner
	end

	def public_match_triple t
		scanner = StringScanner.new t
		parse_n3_triple scanner
	end
end

class TestYarsAdapter < Test::Unit::TestCase
	DB_HOST = 'opteron'
	def setup
		@adapter = YarsAdapter.new
		NodeFactory.connection :adapter => :yars, :host => DB_HOST
	end

	def test_uri_parse
		assert_kind_of IdentifiedResource, @adapter.public_match_object('<abc>')
		assert_kind_of IdentifiedResource, @adapter.public_match_object('<test:abc:blabla>')

		assert_equal 'abc', @adapter.public_match_object('<abc>').uri
		assert_equal 'test:abc:blabla', @adapter.public_match_object('<test:abc:blabla>').uri

		assert_raise(NTriplesParsingYarsError){ @adapter.public_match_object('<>') }
	end

	def test_triple_parse
		assert_nothing_raised { @adapter.public_match_triple('<s> <p> <o> .') }
		assert_nothing_raised { @adapter.public_match_triple('<s><p>"test" .') }
		assert_nothing_raised { @adapter.public_match_triple('<s> <p> "" .') }
		assert_raise(NTriplesParsingYarsError) { @adapter.public_match_triple('<s> <> "" .') }
		assert_raise(NTriplesParsingYarsError) { @adapter.public_match_triple('<> <p> "" .') }
		assert_raise(NTriplesParsingYarsError) { @adapter.public_match_triple('<s> <p> " .') }
		assert @adapter.public_match_triple('<s> <p> "test".').size == 3
		assert @adapter.public_match_triple('<s><p>"test".').all? { |node| node.kind_of? Node }
		assert @adapter.public_match_triple('<s><p>"test".').any? { |node| node.kind_of? Literal }
		assert @adapter.public_match_triple('<s><p>"test".').any? { |node| node.kind_of? IdentifiedResource }
	end

	def test_object_literal_parse
		assert_kind_of Literal, @adapter.public_match_object('""')
		assert_kind_of Literal, @adapter.public_match_object('"literal"')
		assert_kind_of Literal, @adapter.public_match_object('"urn:aoesuta:aesutaeu"')
		assert_kind_of Literal, @adapter.public_match_object('"\""')
		assert_kind_of Literal, @adapter.public_match_object('"te\"st"')
		assert_kind_of Literal, @adapter.public_match_object('"Chandrabose Aravindan and J{\\\\\\\\\\\\\\\"u}rgen Dix and Ilkka Niemel{\\\\\\\\\\\\\\\"a}"')

		assert_equal '', @adapter.public_match_object('""').value
		assert_equal 'literal', @adapter.public_match_object('"literal"').value
		assert_equal 'urn:test', @adapter.public_match_object('"urn:test"').value
		assert_equal 'te\"st', @adapter.public_match_object('"te\"st"').value

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
