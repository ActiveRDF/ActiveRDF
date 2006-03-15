# = test_resource.rb
#
# Unit Test of Resource Class method
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
require 'node_factory'

class Resource
	def self.test_return_distinct_results(results)
		return Resource.return_distinct_results(results)
	end
	
	def self.test_find_predicates(class_uri)
		return Resource.find_predicates(class_uri)
	end
end

class TestResource < Test::Unit::TestCase
	
	def test_A_classuri
		class_uri = Resource.class_URI
		assert_not_nil(class_uri)
		assert_kind_of(IdentifiedResource, class_uri)
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource', class_uri.uri)
	end
	
	def test_B_return_distinct_results_error
		assert_raise(ActiveRdfError) {
			Resource.test_return_distinct_results(nil)
		}
		assert_raise(ActiveRdfError) {
			Resource.test_return_distinct_results(Hash.new)
		}
	end
	
	def test_C_return_distinct_results
		result = Resource.test_return_distinct_results(Array.new)
		assert_nil(result)
	
		result = Resource.test_return_distinct_results(['42'])
		assert_not_nil(result)
		assert(result.kind_of?(String))
		assert_equal('42', result)
		
		result = Resource.test_return_distinct_results(['42', '9'])
		assert_not_nil(result)
		assert(result.kind_of?(Array))
		assert_equal(2, result.size)
		
		result = Resource.test_return_distinct_results(['42', '42'])
		assert_not_nil(result)
		assert(result.kind_of?(String))
		assert_equal('42', result)
	end
	
	def test_D_find_predicates_error_class_uri_nil
		assert_raise(ActiveRdfError) {
			Resource.test_find_predicates(nil)
		}
	end
	
	def test_E_find_predicates_error_class_uri_not_resource
		assert_raise(ActiveRdfError) {
			Resource.test_find_predicates(String.new)
		}		
	end
	
	def test_F_find_predicates
		params = { :adapter => :yars, :host => 'opteron', :port => 8080, :context => 'test_query' }
		NodeFactory.connection(params)
		
		class_uri = NodeFactory.create_identified_resource('http://protege.stanford.edu/rdfPerson')
		
		predicates = Resource.test_find_predicates(class_uri)
		assert_not_nil(predicates)
		assert_instance_of(Hash, predicates)
		assert_equal(3, predicates.size)
		predicates.each { |attribute, uri|
			case attribute
			when 'rdfage'
				assert_equal('http://protege.stanford.edu/rdfage', uri)
			when 'rdfknows'
				assert_equal('http://protege.stanford.edu/rdfknows', uri)
			when 'rdfname'
				assert_equal('http://protege.stanford.edu/rdfname', uri)
			end
		}
	end
	
	def test_G_try_to_instantiate_resource
		assert_raise(NoMethodError) {
			resource = Resource.new
		}
	end
	
end
