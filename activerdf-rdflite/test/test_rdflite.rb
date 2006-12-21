# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'rubygems'
require 'test/unit'
require 'active_rdf'
require 'federation/federation_manager'
require 'queryengine/query'

class TestRdfLiteAdapter < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
  end

  def teardown
  end

  def test_registration
    adapter = ConnectionPool.add_data_source(:type => :rdflite)
		assert_instance_of RDFLite, adapter
		assert adapter.keyword_search?
	end

	def test_initialise
		adapter = ConnectionPool.add_data_source(:type => :rdflite, :keyword => false)
		assert !adapter.keyword_search? 
	end

	def test_initialise_with_user_params
		#TODO: FIXME
	end

	def test_duplicate_registration
    adapter1 = ConnectionPool.add_data_source(:type => :rdflite)
    adapter2 = ConnectionPool.add_data_source(:type => :rdflite)

		assert_equal adapter1, adapter2
		assert_equal adapter1.object_id, adapter2.object_id
	end


  def test_simple_query
    adapter = ConnectionPool.add_data_source(:type => :rdflite)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    adapter.add(eyal, age, test)

    result = Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten => true)
    assert_instance_of RDFS::Resource, result
    assert_equal 'eyaloren.org', result.uri
  end

  def test_federated_query
    adapter1 = ConnectionPool.add_data_source(:type => :rdflite)
    adapter2 = ConnectionPool.add_data_source(:type => :rdflite, :fake_symbol_to_get_unique_adapter => true)

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
    adapter = ConnectionPool.add_data_source(:type => :rdflite)

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'

    adapter.add(eyal, age, test)
    Query.new.select(:s,:p).where(:s,:p,:o).execute(:flatten => false) do |s,p|
      assert_equal 'eyaloren.org', s.uri
      assert_equal 'foaf:age', p.uri
    end
  end

	def test_loading_data
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')
		assert_equal 32, adapter.size
	end

	def test_load_bnodes
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_bnode_data.nt')

		# loaded five triples in total
		assert_equal 5, adapter.size

		# triples contain two distinct bnodes
		assert_equal 2, Query.new.count.distinct(:s).where(:s,:p,:o).execute

		# collecting the bnodes
		bnodes = Query.new.distinct(:s).where(:s,:p,:o).execute
		# assert that _:#1 occurs in three triples
		assert_equal 3, Query.new.select(:p,:o).where(bnodes[0], :p, :o).execute.size
		# assert that _:#2 occurs in two triples
		assert_equal 2, Query.new.select(:p,:o).where(bnodes[1], :p, :o).execute.size
	end

	def test_count_query
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')
		assert_kind_of Fixnum, Query.new.count(:s).where(:s,:p,:o).execute
		assert_equal 32, Query.new.count(:s).where(:s,:p,:o).execute
	end

	def test_single_context
    adapter = ConnectionPool.add_data_source :type => :rdflite
		file = File.dirname(File.expand_path(__FILE__)) + '/test_data.nt'
		adapter.load(file)

		context = Query.new.distinct(:c).where(:s,:p,:o,:c).execute(:flatten => true)
		assert_instance_of RDFS::Resource, context
		assert_equal RDFS::Resource.new("file:#{file}"), context
	end

	def test_multiple_context
    adapter = ConnectionPool.add_data_source :type => :rdflite
		file = File.dirname(File.expand_path(__FILE__)) + '/test_data.nt'
		adapter.load(file)
		file_context = RDFS::Resource.new("file:#{file}") 
		
    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'
    adapter.add(eyal, age, test)

		context = Query.new.distinct(:c).where(:s,:p,:o,:c).execute
		assert_equal file_context, context[0]
		assert_equal '', context[1]

		n1 = Query.new.distinct(:s).where(:s, :p, :o, '').execute
		n2 = Query.new.distinct(:s).where(:s, :p, :o, file_context).execute
		assert_equal 1, n1.size
		assert_equal 9, n2.size
	end

	def test_person_data 
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')

    Namespace.register(:test, 'http://activerdf.org/test/')
    eyal = Namespace.lookup(:test, :eyal)
    eye = Namespace.lookup(:test, :eye)
    person = Namespace.lookup(:test, :Person)
    type = Namespace.lookup(:rdf, :type)
    resource = Namespace.lookup(:rdfs,:resource)

    color = Query.new.select(:o).where(eyal, eye,:o).execute(:flatten => true)
    assert 'blue', color
    assert_instance_of String, color

    ObjectManager.construct_classes
    assert eyal.instance_of?(TEST::Person)
    assert eyal.instance_of?(RDFS::Resource)
	end

	def test_delete_data
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')
		assert_equal 32, adapter.size

    eyal = RDFS::Resource.new('http://activerdf.org/test/eyal')
		adapter.delete(eyal, nil, nil)
		assert_equal 27, adapter.size

		adapter.delete(nil, nil, nil)
		assert_equal 0, adapter.size
	end

	def test_keyword_search
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')

    eyal = RDFS::Resource.new('http://activerdf.org/test/eyal')
		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"blue").execute(:flatten => true)
		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"27").execute(:flatten => true)
		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"eyal oren").execute(:flatten => true)
	end

	def test_bnodes
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')

    Namespace.register(:test, 'http://activerdf.org/test/')
    ObjectManager.construct_classes
    assert_equal 2, TEST::Person.find_all.size
		assert_equal 29, TEST::Person.find_all[1].age.to_i
		assert_equal "Another Person", TEST::Person.find_all[1].name
	end
end
