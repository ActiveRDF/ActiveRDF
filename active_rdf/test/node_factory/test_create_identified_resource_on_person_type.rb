# = test_create_identified_resource_on_person_type.rb
#
# Unit Test of IdentifiedResource creation on person type
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
require 'test/node_factory/person'
require 'test/adapter/yars/manage_yars_db'
require 'test/adapter/redland/manage_redland_db'

class TestNodeFactoryIdentifiedResource < Test::Unit::TestCase

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

	def test_A_create_identified_resource_with_know_type_and_no_attributes
		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_not_nil(person)
		assert_instance_of(Person, person)
	end

	def test_B_read_uri_of_known_type
		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_equal('http://m3pe.org/activerdf/test/test_set_Instance_7', person.uri)
	end

	def test_C_type_of_known_type
		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_instance_of(Person, person)
	end

	def test_D_subclass_type_of_known_type
		person = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_kind_of(IdentifiedResource, person)
		assert_kind_of(Resource, person)
		assert_kind_of(Node, person)
	end

	def test_E_create_same_instance_of_known_type
		person1 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		person2 = NodeFactory.create_identified_resource('http://m3pe.org/activerdf/test/test_set_Instance_7')
		assert_equal(person1,person2, "Not the same instance of Person.")
	end
end
