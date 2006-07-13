# = test_sesame_adapter.rb
#
# Unit Test of Sesame adapter
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
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../../..")

require 'test/unit'
require 'active_rdf'
require 'node_factory'

class Person < IdentifiedResource
  set_class_uri 'http://foaf/Person'
  
end

class TestSesameAdapter < Test::Unit::TestCase

  def setup
  end
  
	def test_A_initialize
		params = { :adapter => :sesame, :location => 'temp.rdf' }
		@connection = NodeFactory.connection(params)
		
		assert_not_nil(@connection)
		assert_kind_of(AbstractAdapter, @connection)
		assert_instance_of(SesameAdapter, @connection)
		
		assert(File.exists?('temp.rdf'))
	end

	def test_B_save
		params = { :adapter => :sesame, :location => 'temp.rdf' }
		@connection = NodeFactory.connection(params)
				
		subject = NodeFactory.create_identified_resource('http://m3pe.org/subject')
		predicate = NodeFactory.create_identified_resource('http://m3pe.org/predicate')
		object = NodeFactory.create_identified_resource('http://m3pe.org/object')
		
		@connection.add(subject, predicate, object)
		
		assert_nothing_raised {
			@connection.save
		}
		
	end
	
	def test_C_query
		params = { :adapter => :sesame, :location => 'temp.rdf' }
		@connection = NodeFactory.connection(params)
		Person.add_predicate 'http://foaf/Person#firstName'
    Person.add_predicate 'http://foaf/Person#lastName'
    
	  dema = Person.create('http://sr/dema')
    dema.firstName = 'Demetrius'
    dema.lastName = 'Nunes'
    dema.save
    
    dema2 = Person.find_by_firstName('Demetrius')[0]
    dema3 = Person.find_by_lastName('Nunes')[0]
    assert_equal(dema, dema2)
    assert_equal(dema, dema3)
  end
end