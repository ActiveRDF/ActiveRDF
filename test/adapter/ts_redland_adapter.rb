require 'test/unit'
require 'active_rdf'
require 'adapter/redland_adapter'
require 'federation/federation_manager'
require 'queryengine/query'
# require 'active_rdf/test/common'

class TestObjectCreation < Test::Unit::TestCase
	def setup
		ConnectionPool.instance.clear
	end
	
	def teardown
	end
	
	def test_registration
		adapter = ConnectionPool.instance.add_data_source(:type => :redland)
		assert_instance_of RedlandAdapter, adapter
	end
	
	def test_redland_connections
		adapter = RedlandAdapter.new({})
		assert_instance_of RedlandAdapter, adapter
	end
	
	def test_simple_query
		adapter = ConnectionPool.instance.add_data_source(:type => :redland)

		eyal = RDFS::Resource.lookup 'eyaloren.org'
		age = RDFS::Resource.lookup 'foaf:age'
		test = RDFS::Resource.lookup 'test'
		
		adapter.add(eyal, age, test)
		result = Query.new.select(:s).where(:s, :p, :o).execute

		assert_instance_of RDFS::Resource, result
		assert_equal 'eyaloren.org', result.uri
	end
	
	def test_federated_query
		adapter1 = ConnectionPool.instance.add_data_source(:type => :redland)
		adapter2 = ConnectionPool.instance.add_data_source(:type => :redland, :fake_symbol_to_get_unique_adapter => true)
		
		eyal = RDFS::Resource.lookup 'eyaloren.org'
		age = RDFS::Resource.lookup 'foaf:age'
		test = RDFS::Resource.lookup 'test'
		test2 = RDFS::Resource.lookup 'test2'
		
		adapter1.add(eyal, age, test)
		adapter2.add(eyal, age, test2)
		
		results = Query.new.select(:s, :p, :o).where(:s, :p, :o).execute
		assert_equal 2, results.size
		assert_instance_of RDFS::Resource, results[0][0]
		
		literals = [results[0][2].uri, results[1][2].uri]
		assert literals.include?('test')
		assert literals.include?('test2')
	end
	
	def test_query_with_block
		adapter = ConnectionPool.instance.add_data_source(:type => :redland)
		
		eyal = RDFS::Resource.lookup 'eyaloren.org'
		age = RDFS::Resource.lookup 'foaf:age'
		test = RDFS::Resource.lookup 'test'
		
		adapter.add(eyal, age, test)
		Query.new.select(:s,:p).where(:s,:p,:o).execute do |s,p|
			assert_equal 'eyaloren.org', s.uri
			assert_equal 'foaf:age', p.uri
		end
	end
	
  def test_person_data
    ConnectionPool.instance.add_data_source :type => :redland, :location => 'test/test-person'
    
    eyal = RDFS::Resource.lookup 'http://activerdf.org/test/eyal'
    eye = RDFS::Resource.lookup 'http://activerdf.org/test/eye'
    type = RDFS::Resource.lookup 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    person = RDFS::Resource.lookup 'http://activerdf.org/test/Person'
    resource = RDFS::Resource.lookup 'http://www.w3.org/2000/01/rdf-schema#RDFS::Resource'
    
    color = Query.new.select(:o).where(eyal, eye,:o).execute
    assert 'blue', color
    assert_instance_of String, color
    
    types = Query.new.select(:o).where(eyal, type, :o).execute
    assert types.include?(person)
    assert types.include?(resource)
  end
end