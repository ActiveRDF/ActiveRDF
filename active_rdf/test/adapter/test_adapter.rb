# = test_adapter.rb
#
# Unit Test of adapter
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

require 'active_rdf'
require 'active_rdf/test/common'

class TestAdapter < Test::Unit::TestCase
	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_methods_exist
		adapter = NodeFactory.connection
		assert adapter.respond_to?(:add)
		assert adapter.respond_to?(:remove)
		assert adapter.respond_to?(:save)		
		assert adapter.respond_to?(:query)	
		assert adapter.respond_to?(:query_count)	
	end
	
	def test_adding
		adapter = NodeFactory.connection
		n = IdentifiedResource.new 'abc'
		
		assert !adapter.add(nil,nil,nil)
		assert_raise(ActiveRdfError) { adapter.add!(nil,nil,nil) }
		
		assert adapter.add(n,n,n)
		assert adapter.add!(n,n,n)
	end
	
	def test_removal
		adapter = NodeFactory.connection
		n = IdentifiedResource.new 'abc'
		
		# removal should fail, given wrong input
		assert !adapter.remove('abc',n,n)
		assert_raise(ActiveRdfError) { adapter.remove!('abc',n,n) }
	
		# removal should succeed
		adapter.add(n,n,n)		
		assert adapter.remove(n,n,n)
		
		adapter.add(n,n,n)
		assert adapter.remove!(n,n,n)		
		
		# removal should succeed if statements not in model
		assert adapter.remove(n,n,n)
		assert adapter.remove!(n,n,n)
	end
	
	def test_query
		adapter = NodeFactory.connection
		
		qe = QueryEngine.new
		qe.add_binding_variables :s
		qe.add_condition :s,:p,:o
		qs = qe.generate
		
		# querying for :s, :p, :o should succeed
		assert adapter.query(qs)
		assert adapter.query!(qs)
		
		# querying with empty query string should fail
		assert !adapter.query('')		
		assert_raise(ActiveRdfError) { adapter.query! '' }
	end
	
	def test_query_count
		adapter = NodeFactory.connection
		
		qe = QueryEngine.new
		qe.add_binding_variables :s
		qe.add_condition :s,:p,:o
		qs = qe.generate
		
		assert_equal adapter.query_count(qs), 0
		assert_nothing_raised { adapter.query_count('') }
		assert_raise(ActiveRdfError) { adapter.query_count!('') } 
		
		n = IdentifiedResource.new 'abc'
		adapter.add(n,n,n)		
		assert_equal adapter.query_count(qs), 1		
	end
	
	def test_save
		adapter = NodeFactory.connection
		assert adapter.save
		assert adapter.save!
	end
	
end