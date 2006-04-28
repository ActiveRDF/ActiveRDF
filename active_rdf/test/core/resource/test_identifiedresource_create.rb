# = test_identifiedresource_create.rb
#
# Unit Test of IdentifiedResource create method
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

class TestIdentifiedResourceCreate < Test::Unit::TestCase

	def setup
		case DB
		when :yars
			setup_yars('test_identifiedresource_create')
			params = { :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'test_identifiedresource_create' }
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
			delete_yars('test_identifiedresource_create')
		when :redland
			delete_redland
		else
			raise(StandardError, "Unknown DB type : #{DB}")
		end	
	end

	def test_A_create_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
	end
	
	def test_B_create_two_times_same_identified_resource
		ir = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_not_nil(ir)
		assert_instance_of(IdentifiedResource, ir)
		ir2 = IdentifiedResource.create('http://m3pe.org/activerdf/test/identifiedresource')
		assert_equal(ir, ir2)
	end
	
	def test_C_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		assert(Resource.exists?(person))
	end
	
	def test_D_create_person
		person = Person.create('http://m3pe.org/activerdf/test/new_person2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		assert(Person.exists?(person))
	end
	
	def test_D_load_person
		regis = Person.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		assert_equal('45', regis.age)
	end
	
	def test_E_load_person_throught_identified_resource
		regis = IdentifiedResource.create('http://m3pe.org/activerdf/test/test_set_Instance_10')
		assert_not_nil(regis)
		assert_instance_of(Person, regis)
		assert_equal('regis', regis.name)
		assert_equal('45', regis.age)		
	end

end
