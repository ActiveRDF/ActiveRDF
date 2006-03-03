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

module Resource
	def self.test_get_local_part(element)
		return Resource.get_local_part(element)
	end
	
	def self.test_return_distinct_results(results)
		return Resource.return_distinct_results(results)
	end
end

class TestResource < Test::Unit::TestCase

	def test_1_namespace
		assert_equal("http://www.w3.org/2000/01/rdf-schema#", Resource.namespace)
	end
	
	def test_2_classuri
		class_uri = Resource.classURI
		assert_not_nil(class_uri)
		assert(class_uri.kind_of?(BasicIdentifiedResource))
		assert_equal("http://www.w3.org/2000/01/rdf-schema#Resource", class_uri.uri)
	end
	
	def test_3_get_local_part_error
		assert_raise(ActiveRdfError) {
			Resource.test_get_local_part(nil)
		}
		assert_raise(ResourceTypeError) {
			Resource.test_get_local_part("42")
		}
	end
	
	def test_4_get_local_part
		assert_equal('Resource', Resource.test_get_local_part(Resource.classURI))
	end
	
	def test_5_return_distinct_results_error
		assert_raise(ActiveRdfError) {
			Resource.test_return_distinct_results(nil)
		}
		assert_raise(ActiveRdfError) {
			Resource.test_return_distinct_results(Hash.new)
		}
	end
	
	def test_6_return_distinct_results
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
	
end
