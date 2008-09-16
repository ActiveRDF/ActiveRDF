# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'rubygems'
require 'active_rdf'
require 'federation/federation_manager'
require 'queryengine/query'

class TestRedlandAdapter < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
  end

  def teardown
  end

  def test_registration
    adapter = ConnectionPool.add_data_source(:type => :redland)
    assert_instance_of RedlandAdapter, adapter
  end

  #def test_redland_postgres
  #  adapter = ConnectionPool.add(:type => :redland, :name => 'db1', :location => :postgresql,
  #        :host => 'localhost', :database => 'redland_test',
  #            :user => 'eyal', :password => 'lief1234')
  #end

  def test_redland_connections
    adapter = RedlandAdapter.new({})
    assert_instance_of RedlandAdapter, adapter
  end

  def test_simple_query
    adapter = ConnectionPool.add_data_source(:type => :redland)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    adapter.add(eyal, age, test)
    result = Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten)

    assert_instance_of RDFS::Resource, result
    assert_equal 'eyaloren.org', result.uri
  end

  def test_federated_query
    adapter1 = ConnectionPool.add_data_source(:type => :redland)
    adapter2 = ConnectionPool.add_data_source(:type => :redland, :fake_symbol_to_get_unique_adapter => true)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'
    test2 = RDFS::Resource.new 'test2'

    adapter1.add(eyal, age, test)
    adapter2.add(eyal, age, test2)

    # assert only one distinct subject is found (same one in both adapters)
    assert_equal 1, Query.new.distinct(:s).where(:s, :p, :o).execute.size

    # assert two distinct objects are found
    results = Query.new.distinct(:o).where(:s, :p, :o).execute
    assert_equal 2, results.size

    results.all? {|result| assert result.instance_of?(RDFS::Resource) }
  end

  def test_query_with_block
    adapter = ConnectionPool.add_data_source(:type => :redland)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    adapter.add(eyal, age, test)
    Query.new.select(:s,:p).where(:s,:p,:o).execute do |s,p|
      assert_equal 'eyaloren.org', s.uri
      assert_equal 'foaf:age', p.uri
    end
  end
  
  def test_load_from_file
    adapter = ConnectionPool.add_data_source :type => :redland
    # adapter.load("/tmp/test_person_data.nt", "turtle")
    # adapter.load("/home/metaman/workspaces/deri-workspace/activerdf/test/test_person_data.nt", "turtle")
    adapter.load("#{File.dirname(__FILE__)}/test_person_data.nt", "turtle")
    assert_equal 28, adapter.size  
  end

  def test_remote_load
    adapter = ConnectionPool.add_data_source :type => :redland
    adapter.load('http://www.eyaloren.org/foaf.rdf', 'rdfxml')
    assert_equal 9, adapter.size
  end

  def test_load_and_clear
    adapter = ConnectionPool.add_data_source :type => :redland
    adapter.load('http://www.eyaloren.org/foaf.rdf', 'rdfxml')
    assert_equal 9, adapter.size
    adapter.clear
    assert_equal 0, adapter.size
  end

  def test_close
    adapter = ConnectionPool.add_data_source :type => :redland, :location => '/tmp/test.db'
    adapter.load('http://www.eyaloren.org/foaf.rdf', 'rdfxml')
    assert_equal 9, adapter.size
    adapter.close
    assert_equal 0, ConnectionPool.adapters.size
  end

  def test_person_data
    ConnectionPool.add_data_source :type => :redland, :location => 'test/test-person'
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

  def test_federated_query
    adapter1 = ConnectionPool.add_data_source(:type => :redland)
    adapter2 = ConnectionPool.add_data_source(:type => :redland, :fake_symbol_to_get_unique_adapter => true)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'
    test2 = RDFS::Resource.new 'test2'

    adapter1.add(eyal, age, test)
    adapter2.add(eyal, age, test2)

    # assert only one distinct subject is found (same one in both adapters)
    assert_equal 1, Query.new.distinct(:s).where(:s, :p, :o).execute.size

    # assert two distinct objects are found
    results = Query.new.distinct(:o).where(:s, :p, :o).execute
    assert_equal 2, results.size

    results.all? {|result| assert result.instance_of?(RDFS::Resource) }
  end

  def test_query_with_block
    adapter = ConnectionPool.add_data_source(:type => :redland)

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
    adapter = ConnectionPool.add_data_source :type => :redland
    adapter.load("#{File.dirname(__FILE__)}/test_person_data.nt", "turtle")

    Namespace.register(:test, 'http://activerdf.org/test/')

    eyal = Namespace.lookup(:test, :eyal)
    eye = Namespace.lookup(:test, :eye)
    person = Namespace.lookup(:test, :Person)
    type = Namespace.lookup(:rdf, :type)
    resource = Namespace.lookup(:rdfs,:resource)

    assert_equal 'blue', eyal.test::eye

    ObjectManager.construct_classes
    assert eyal.instance_of?(TEST::Person)
    assert eyal.instance_of?(RDFS::Resource)
  end
  
  def test_write_to_file_and_reload
    require 'tmpdir'
    location = "#{Dir.tmpdir}/redland-temp"
    adapter = ConnectionPool.add_data_source(:type => :redland, :location => location)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    adapter.add(eyal, age, test)
    adapter.save 
    
    # flush the pool and freshly load the file we just wrote into
    ConnectionPool.clear
    adapter2 = ConnectionPool.add_data_source(:type => :redland, :location => location)

    assert adapter2.object_id != adapter.object_id
    assert_equal 1, adapter2.size
  end

	def test_sparql_query
		adapter = ConnectionPool.add_data_source :type => :redland

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'
    adapter.add(eyal, age, test)

    adapter.save 
		query = Query.new.distinct(:s).where(:s,:p,:o)
		results = adapter.get_query_results(query)

		# TODO: test if results are correct; but we do this only when redland 
		# supports this method in release
		assert results.include?('eyaloren.org')
	end
end
