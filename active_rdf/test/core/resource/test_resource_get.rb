# = test_resource_get.rb
#
# Unit Test of Resource get method
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

class TestResourceGet < Test::Unit::TestCase

	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_empty_db
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		assert_nothing_raised {
			result = Resource.get(subject, predicate)
			assert result.empty?
		}
	end
	
	def test_get_with_data
		return unless load_test_data
	
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate_not_exists")
		assert_nothing_raised {
			result = Resource.get(subject, predicate)
			assert result.empty?
		}
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate3")
		assert_nothing_raised {
			result = Resource.get(subject, predicate).first
			assert_not_nil(result)
			assert_equal('', result.value)
		}		
	
  	
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate1")
		assert_nothing_raised {
			result = Resource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(Literal, result)
			assert_equal('42', result.value)
		}
			
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate2")
		assert_nothing_raised {
			result = Resource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(IdentifiedResource, result)
			assert_equal('http://m3pe.org/object2', result.uri)
		}
	end
	
	def test_error_subject_nil
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		assert_raise(ResourceTypeError) { Resource.get(nil, predicate) }

		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		assert_raise(ResourceTypeError) { Resource.get(subject, nil) }
	end
end
