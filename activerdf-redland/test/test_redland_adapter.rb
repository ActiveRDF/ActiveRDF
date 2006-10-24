# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'rubygems'
require 'active_rdf'
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
    adapter = ConnectionPool.add_data_source(:type => :redland)
    assert_instance_of RedlandAdapter, adapter
  end

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
    result = Query.new.distinct(:s).where(:s, :p, :o).execute

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
    assert_equal 1, Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten=>false).size

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

  def test_person_data
    ConnectionPool.add_data_source :type => :redland, :location => 'test/test-person'
    Namespace.register(:test, 'http://activerdf.org/test/')

    eyal = Namespace.lookup(:test, :eyal)
    eye = Namespace.lookup(:test, :eye)
    person = Namespace.lookup(:test, :Person)
    type = Namespace.lookup(:rdf, :type)
    resource = Namespace.lookup(:rdfs,:resource)

    p eyal.predicates

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
    assert_equal 1, Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten=>false).size

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

  # test fails
  def test_update_value
    # TODO: move to generic test suite: this test is not redland specific,
    # but currently redland is the only datasource to which we can write
    # but we should move this to a generic test suite, check whether we have a write_adapter,
    # and if so run this test
    
    # ConnectionPool.add_data_source :type => :redland, :location => 'test/test-person'
    adapter = ConnectionPool.add_data_source :type => :redland
    adapter.load("#{File.dirname(__FILE__)}/test_person_data.nt", "turtle")
    Namespace.register(:test, 'http://activerdf.org/test/')
    eyal = Namespace.lookup(:test, :eyal)

    assert_equal '27', eyal.age
    eyal.age = 30
  end

  # test fails 
  def test_person_data
    adapter = ConnectionPool.add_data_source :type => :redland
    adapter.load("#{File.dirname(__FILE__)}/test_person_data.nt", "turtle")

    Namespace.register(:test, 'http://activerdf.org/test/')

    eyal = Namespace.lookup(:test, :eyal)
    eye = Namespace.lookup(:test, :eye)
    person = Namespace.lookup(:test, :Person)
    type = Namespace.lookup(:rdf, :type)
    resource = Namespace.lookup(:rdfs,:resource)

    color = Query.new.select(:o).where(eyal, eye,:o).execute
    assert_equal 'blue', color
    assert_instance_of String, color

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
end
