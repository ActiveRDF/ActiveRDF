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
#$:.unshift File.join(File.dirname(__FILE__),'../../../')

require 'test/unit'
require 'active_rdf'
require 'node_factory'
require 'active_rdf/test/adapter/yars/manage_yars_db'
require 'active_rdf/test/adapter/redland/manage_redland_db'

class Resource
	def self.test_find_predicates(class_uri)
		return Resource.find_predicates(class_uri)
	end
end

class TestResource < Test::Unit::TestCase
	def setup
		case DB
		when :yars
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_resource' }
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
			delete_yars('test_resource')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end
	
	def test_A_classuri
		class_uri = Resource.class_URI
		assert_not_nil(class_uri)
		assert_kind_of(IdentifiedResource, class_uri)
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource', class_uri.uri)
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
		initialise_db
		
		class_uri = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/Person')
		
		predicates = Resource.test_find_predicates(class_uri)
		assert_not_nil(predicates)
		assert_instance_of(Hash, predicates)
		assert_equal(3, predicates.size)
		predicates.each { |attribute, uri|
			case attribute
			when 'age'
				assert_equal('http://m3pe.org/activerdf/test/age', uri)
			when 'knows'
				assert_equal('http://m3pe.org/activerdf/test/knows', uri)
			when 'name'
				assert_equal('http://m3pe.org/activerdf/test/name', uri)
			end
		}
		
		clean_db
	end
	
	def test_G_try_to_instantiate_resource
		assert_raise(NoMethodError) {
			resource = Resource.new
		}
	end
	
	def test_H_exists_with_resource_as_parameter
		resource = IdentifiedResource.create('http://m3pe.org/activerdf/test/exist')
		
		assert(!Resource.exists?(resource))
		resource.save
		assert(Resource.exists?(resource))
		
		clean_db
	end
	
	def test_I_exists_with_uri_as_parameter
		resource = IdentifiedResource.create('http://m3pe.org/activerdf/test/exist2')

		assert(!Resource.exists?('http://m3pe.org/activerdf/test/exist2'))
		
		resource.save
		
		assert(Resource.exists?('http://m3pe.org/activerdf/test/exist2'))
		
		clean_db
	end
	
	private
	
	def initialise_db
		case DB
		when :yars
			setup_yars('test_resource')
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_resource' }
			NodeFactory.connection(params)
		when :redland
			setup_redland
			params = { :adapter => :redland }
			NodeFactory.connection(params)
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end
	end
	
	def clean_db
		case DB
		when :yars
			delete_yars('test_resource')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end
	
end
