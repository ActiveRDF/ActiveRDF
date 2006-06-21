# = test_identifiedresource_get.rb
#
# Unit Test of identifiedResource get method
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

class TestIdentifiedResourceGet < Test::Unit::TestCase

	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_empty_db
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		assert_nothing_raised do
			result = IdentifiedResource.get(subject, predicate)
			assert result.empty?
		end
	end
	
	def test_subject_exists_and_predicate_not_exists
		return unless load_test_data
	
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate_not_exists")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate)
			assert result.empty?
		}
	end
	
	def test_subject_and_predicate_exist_with_object_empty_string
		return unless load_test_data
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate3")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(Literal, result)
			assert_equal('', result.value)
		}		
	end
	
	def test_subject_and_predicate_exist_with_object_literal
		return unless load_test_data
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate1")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(Literal, result)
			assert_equal('42', result.value)
		}
	end
	
	def test_subject_and_predicate_exist_with_object_resource
		return unless load_test_data
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate2")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(IdentifiedResource, result)
			assert_equal('http://m3pe.org/object2', result.uri)
		}
	end
	
	def test_error_subject_nil
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		assert_raise(ResourceTypeError) { IdentifiedResource.get(nil, predicate) }		
    
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		assert_raise(ResourceTypeError) { IdentifiedResource.get(subject, nil) }		
	end
	
	
end
