require 'test/unit'
require 'active_rdf'
require 'adapter/sparql'
require 'federation/federation_manager'
require 'queryengine/query'
# require 'active_rdf/test/common'

class TestObjectCreation < Test::Unit::TestCase
	def setup
		ConnectionPool.clear
	end
	
	def teardown
	end
	
	def test_registration
		adapter = ConnectionPool.add_data_source(:type => :sparql)
		assert_instance_of SparqlAdapter, adapter
	end
	
	def test_redland_connections
		adapter = SparqlAdapter.new
		assert_instance_of SparqlAdapter, adapter
	end
	
	def test_simple_query
		adapter = ConnectionPool.add_data_source(:type => :sparql)
		
		title = RDFS::Resource.new('http://purl.org/dc/elements/1.1/title')
		result = Query.new.select(:b).where(:b, title, :t).execute.first

		assert_instance_of RDFS::Resource, result
	end
	
#	def test_federated_query
#		adapter1 = ConnectionPool.add_data_source(:type => :redland)
#		adapter2 = ConnectionPool.add_data_source(:type => :redland, :fake_symbol_to_get_unique_adapter => true)
#		
#		eyal = RDFS::Resource.new 'eyaloren.org'
#		age = RDFS::Resource.new 'foaf:age'
#		test = RDFS::Resource.new 'test'
#		test2 = RDFS::Resource.new 'test2'
#		
#		adapter1.add(eyal, age, test)
#		adapter2.add(eyal, age, test2)
#		
#		results = Query.new.select(:s, :p, :o).where(:s, :p, :o).execute
#		assert_equal 2, results.size
#		assert_instance_of RDFS::Resource, results[0][0]
#		
#		literals = [results[0][2].uri, results[1][2].uri]
#		assert literals.include?('test')
#		assert literals.include?('test2')
#	end
#	
#	def test_query_with_block
#		adapter = ConnectionPool.add_data_source(:type => :redland)
#		
#		eyal = RDFS::Resource.new 'eyaloren.org'
#		age = RDFS::Resource.new 'foaf:age'
#		test = RDFS::Resource.new 'test'
#		
#		adapter.add(eyal, age, test)
#		Query.new.select(:s,:p).where(:s,:p,:o).execute do |s,p|
#			assert_equal 'eyaloren.org', s.uri
#			assert_equal 'foaf:age', p.uri
#		end
#	end
#	
#  def test_person_data
#    ConnectionPool.add_data_source :type => :redland, :location => 'test/test-person'
#    
#    eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
#    eye = RDFS::Resource.new 'http://activerdf.org/test/eye'
#    type = RDFS::Resource.new 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
#    person = RDFS::Resource.new 'http://activerdf.org/test/Person'
#    resource = RDFS::Resource.new 'http://www.w3.org/2000/01/rdf-schema#Resource'
#    
#    color = Query.new.select(:o).where(eyal, eye,:o).execute
#    assert 'blue', color
#    assert_instance_of String, color
#    
#    types = Query.new.select(:o).where(eyal, type, :o).execute
#    assert types.include?(person)
#    assert types.include?(resource)
#  end
end
