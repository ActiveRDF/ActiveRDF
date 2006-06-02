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
require 'node_factory'
require 'active_rdf/test/adapter/yars/manage_yars_db'
require 'active_rdf/test/adapter/redland/manage_redland_db'

class TestIdentifiedResourceGet < Test::Unit::TestCase

	def setup
		case DB
		when :yars
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_resource_get' }
			@connection = NodeFactory.connection(params)
		when :redland
			params = { :adapter => :redland }
			@connection = NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def teardown
		case DB
		when :yars
			delete_yars('test_resource_get')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end
	
	def test_A_empty_db
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate)
			assert result.empty?
		}
	end
	
	def test_B_subject_exists_and_predicate_not_exists
		init_db
	
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate_not_exists")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate)
			assert result.empty?
		}
	end
	
	def test_C_subject_and_predicate_exist_with_object_empty_string
		init_db
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate3")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(Literal, result)
			assert_equal('', result.value)
		}		
	end
	
	def test_D_subject_and_predicate_exist_with_object_literal
		init_db
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate1")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(Literal, result)
			assert_equal('42', result.value)
		}
	end
	
	def test_E_subject_and_predicate_exist_with_object_resource
		init_db
		
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate2")
		assert_nothing_raised {
			result = IdentifiedResource.get(subject, predicate).first
			assert_not_nil(result)
			assert_instance_of(IdentifiedResource, result)
			assert_equal('http://m3pe.org/object2', result.uri)
		}
	end
	
	def test_F_error_subject_nil
		predicate = NodeFactory.create_identified_resource("http://m3pe.org/predicate")
		
		assert_raise(ResourceTypeError) {
			IdentifiedResource.get(nil, predicate)
		}		
	end
	
	def test_G_error_predicate_nil
		subject = NodeFactory.create_identified_resource("http://m3pe.org/subject")
		
		assert_raise(ResourceTypeError) {
			IdentifiedResource.get(subject, nil)
		}		
	end
	
	private
	
	def init_db
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate1 = NodeFactory.create_identified_resource('http://m3pe.org/predicate1')
		object1 = NodeFactory.create_literal('42', 'xsd:integer')
		predicate2 = NodeFactory.create_identified_resource('http://m3pe.org/predicate2')
		object2 = NodeFactory.create_identified_resource('http://m3pe.org/object2')
		predicate3 = NodeFactory.create_identified_resource('http://m3pe.org/predicate3')
		object3 = NodeFactory.create_literal('', 'string')
				
		@connection.add(subject, predicate1, object1)
		@connection.add(subject, predicate2, object2)
		@connection.add(subject, predicate3, object3)
		@connection.save
	end
	
end
