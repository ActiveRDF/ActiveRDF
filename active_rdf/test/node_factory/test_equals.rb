
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
require 'node_factory'
require 'test/adapter/yars/manage_yars_db'
require 'test/adapter/redland/manage_redland_db'

class TestResourceEquality < Test::Unit::TestCase
	def setup
		case DB
		when :yars
			setup_yars('test_create_person')
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_create_person' }
			@connection = NodeFactory.connection(params)
		when :redland
			setup_redland
			params = { :adapter => :redland }
			@connection = NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end

	def teardown
		case DB
		when :yars
			delete_yars('test_create_person')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end

	def test_equality
		a = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		b = NodeFactory.create_basic_resource('http://m3pe.org/basicresource')
		assert a.object_id != b.object_id
		assert_equal a,b
		assert a == b
		assert a.eql? b
		assert !(a.equal? b)
	end
end
