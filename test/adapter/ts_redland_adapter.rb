require 'test/unit'
require 'active_rdf'
require 'adapter/redland'
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

		eyal = RDFS::Resource.new 'eyaloren.org'
		age = RDFS::Resource.new 'foaf:age'
		test = RDFS::Resource.new 'test'
		
		adapter.add(eyal, age, test)
		result = Query.new.distinct(:s).where(:s, :p, :o).execute

		assert_instance_of RDFS::Resource, result
		assert_equal 'eyaloren.org', result.uri
	end
	
	def test_federated_query
		adapter1 = ConnectionPool.instance.add_data_source(:type => :redland)
		adapter2 = ConnectionPool.instance.add_data_source(:type => :redland, :fake_symbol_to_get_unique_adapter => true)
		
		eyal = RDFS::Resource.new 'eyaloren.org'
		age = RDFS::Resource.new 'foaf:age'
		test = RDFS::Resource.new 'test'
		test2 = RDFS::Resource.new 'test2'
		
		adapter1.add(eyal, age, test)
		adapter2.add(eyal, age, test2)
    
    # assert only one distinct subject is found (same one in both adapters)
		assert_equal 1, Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten=>false).size
		
		# assert two distinct objects are found
		results = Query.new.distinct(:o).where(:s, :p, :o).execute
		assert_equal 2, results.size

		results.all? {|result| assert result.instance_of?(RDFS::Resource) }
	end
	
	def test_query_with_block
		adapter = ConnectionPool.instance.add_data_source(:type => :redland)
		
		eyal = RDFS::Resource.new 'eyaloren.org'
		age = RDFS::Resource.new 'foaf:age'
		test = RDFS::Resource.new 'test'
		
		adapter.add(eyal, age, test)
		Query.new.select(:s,:p).where(:s,:p,:o).execute do |s,p|
			assert_equal 'eyaloren.org', s.uri
			assert_equal 'foaf:age', p.uri
		end
	end
	
  def test_person_data
    ConnectionPool.instance.add_data_source :type => :redland, :location => 'test/test-person'
    Namespace.register(:test, 'http://activerdf.org/test/')
        
    eyal = Namespace.lookup(:test, :eyal)
    eye = Namespace.lookup(:test, :eye)
		person = Namespace.lookup(:test, :Person)
    type = Namespace.lookup(:rdf, :type)
    resource = Namespace.lookup(:rdfs,:resource)
    
    color = Query.new.select(:o).where(eyal, eye,:o).execute
    assert 'blue', color
    assert_instance_of String, color
    
    ObjectManager.construct_classes
    assert eyal.instance_of?(TEST::Person)
    assert eyal.instance_of?(RDFS::Resource)
  end
end
