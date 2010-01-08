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
	end

	def test_initialise
		adapter = ConnectionPool.add_data_source(:type => :rdflite, :keyword => false)
		assert !adapter.keyword_search? 
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

  def test_escaped_literals
    adapter = ConnectionPool.add_data_source(:type => :rdflite)
    eyal = RDFS::Resource.new 'eyal'
    comment = RDFS::Resource.new 'comment'
    string = 'test\nbreak\"quoted\"'
    interpreted = "test\nbreak\"quoted\""

    adapter.add(eyal, comment, string)
    assert_equal interpreted, eyal.comment

    description = RDFS::Resource.new 'description'
    string = 'ümlaut and \u00ebmlaut'
    interpreted = "ümlaut and ëmlaut"

    adapter.add(eyal, description, string)
    assert_equal interpreted, eyal.description
  end

  def test_load_escaped_literals
    adapter = ConnectionPool.add_data_source(:type => :rdflite)
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_escaped_data.nt')
    eyal = RDFS::Resource.new('http://activerdf.org/test/eyal')

    assert_equal 2, adapter.size
    assert_equal "ümlauts and ëmlauts", eyal.comment
    assert_equal "line\nbreaks, <p>'s and \"quotes\"", eyal.encoded
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

    adapter.clear
    adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/ntriples/test.nt')
    assert_equal 30, adapter.size

    adapter.clear
    adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema.rdf')
    assert_equal 76, adapter.size
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
    adapter.add(eyal, age, test, 'context')

		context = Query.new.distinct(:c).where(:s,:p,:o,:c).execute
		assert_equal file_context, context[0]
		assert_equal 'context', context[1]

		assert_equal 10, Query.new.count.distinct(:s).where(:s, :p, :o, nil).execute
		assert_equal 1, Query.new.count.distinct(:s).where(:s, :p, :o, 'context').execute
		assert_equal 9, Query.new.count.distinct(:s).where(:s, :p, :o, file_context).execute
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
    
    # we cant garantuee that ferret is installed
    if adapter.keyword_search?
  		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"blue").execute(:flatten => true)
  		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"27").execute(:flatten => true)
  		assert_equal eyal, Query.new.distinct(:s).where(:s,:keyword,"eyal oren").execute(:flatten => true)
		end
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

	def test_multi_join
		adapter = ConnectionPool.add_data_source :type => :rdflite
		type = Namespace.lookup(:rdf, 'type')
		transProp = Namespace.lookup(:owl, 'TransitiveProperty')

		Namespace.register(:test, 'http://test.com/')
		ancestor = Namespace.lookup(:test, 'ancestor')
		sue = Namespace.lookup(:test, 'Sue')
		mary = Namespace.lookup(:test, 'Mary')
		anne = Namespace.lookup(:test, 'Anne')

		adapter.add ancestor, type, transProp
		adapter.add sue, ancestor, mary
		adapter.add mary, ancestor, anne

		# test that query with multi-join (joining over 1.p==2.p and 1.o==2.s) works
		query = Query.new.select(:Sue, :p, :Anne)
		query.where(:p, type, transProp)
		query.where(:Sue, :p, :Mary)
		query.where(:Mary, :p, :Anne)
		assert_equal 1, query.execute.size
	end

  def test_limit_and_offset
    adapter = ConnectionPool.add_data_source :type => :rdflite
		adapter.load(File.dirname(File.expand_path(__FILE__)) + '/test_data.nt')
    Namespace.register(:test, 'http://activerdf.org/test/')

    assert_equal 7, RDFS::Resource.find(:all).size
    assert_equal 5, RDFS::Resource.find(:all, :limit => 5).size
    assert_equal 4, RDFS::Resource.find(:all, :limit => 4, :offset => 3).size
    assert RDFS::Resource.find(:all, :limit => 4, :offset => 3) != RDFS::Resource.find(:all, :limit => 4)

    assert_equal [TEST::eyal, TEST::age, TEST::car], RDFS::Resource.find(:all, :limit => 3, :order => RDF::type)
  end
end
