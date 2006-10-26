# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'active_rdf'
require 'test/unit'
require 'federation/federation_manager'
require 'queryengine/query'


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
    
    result = Query.new.select(:s).where(:s, Namespace.lookup(:rdf,:type), :t).execute.first
    assert_instance_of RDFS::Resource, result
    
    second_result = Query.new.select(:s, :p).where(:s, :p, 27).execute.flatten
    assert_equal 2, second_result.size
    assert_instance_of RDFS::Resource, second_result[0]
    assert_instance_of RDFS::Resource, second_result[1]
    
#    TODO move the test with this error test to the main body of tests
#    second_result = Query.new.select(:o).where("http://activerdf.org/test/eyal",:p, :o).execute
    
  end

# TODO: check on errors and exceptions when we try to write

	def test_query_with_block
		adapter = ConnectionPool.add_data_source(:type => :sparql)
  
    # this has to be defined in front of the block, to afterwards verify that the contents of the
    # block were indeed executed
    reached_block = false

		Query.new.select(:s,:p).where(:s,:p, 27).execute do |s,p|
		  reached_block = true
			assert_equal 'http://activerdf.org/test/eyal', s.uri
			assert_equal 'http://activerdf.org/test/age', p.uri
		end
		
		assert reached_block, "query with a block does not work"
		
	end

  # TODO: move this to the query test cases
  def test_query_refuses_string_in_where_clause_subject_or_predicate
    adapter = ConnectionPool.add_data_source(:type => :sparql)
    assert_raises ActiveRdfError do
      Query.new.select(:s).where("http://test.org/uri",:p, :o).execute
    end
  end
 
  def test_refuse_to_write
    adapter = ConnectionPool.add_data_source(:type => :sparql)
		eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
		age = RDFS::Resource.new 'foaf:age'
		test = RDFS::Resource.new 'test'

    # NameError gets thown if the method is unknown
    assert_raises NameError do
  		adapter1.add(eyal, age, test)
		end
  
  end


	def test_federated_query
    # we need two disjunct queries and first ask one sparl endpoint
		adapter1 = ConnectionPool.add_data_source(:type => :sparql)
		results_first_source = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size
	
    ConnectionPool.clear
    
    # then we ask the second endpoint
    # sparql endpoint at: http://www.m3pe.org:8080/repositories//mindpeople
		adapter2 = ConnectionPool.add_data_source(:type => :sparql, :host => "m3pe.org", 
		                                          :path => "repositories/", :port => "8080", :context => "mindpeople")
  		results_second_source = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size


      ConnectionPool.clear    
      
      # now we ask them both and the size of the returned statements should be the sum of the sizes of the
    # seperate results
  
		adapter3 = ConnectionPool.add_data_source(:type => :sparql)
		adapter4 = ConnectionPool.add_data_source(:type => :sparql, :host => "m3pe.org", 
		                                          :path => "repositories/", :port => "8080", :context => "mindpeople")
		results_union = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size
    assert_equal results_first_source + results_second_source, results_union
  
	end
  	


  def test_person_data
		adapter1 = ConnectionPool.add_data_source(:type => :sparql)
  
    eyal = RDFS::Resource.new("http://activerdf.org/test/eyal")
    eye = RDFS::Resource.new("http://activerdf.org/test/eye")
# ??    age = RDFS::Resource.new("http://activerdf.org/test/eyal> <http://activerdf.org/test/age")
    type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
    age = RDFS::Resource.new("http://activerdf.org/test/age")
    person = RDFS::Resource.new("http://www.w3.org/2000/01/rdf-schema#Resource")
    resource = RDFS::Resource.new("http://activerdf.org/test/Person")
    
# <http://activerdf.org/test/eyal> <http://activerdf.org/test/age> "27" .
# <http://activerdf.org/test/eyal> <http://activerdf.org/test/eye> "blue" .
    color = Query.new.select(:o).where(eyal, eye,:o).execute
    assert 'blue', color
    assert_instance_of String, color

    age_result = Query.new.select(:o).where(eyal, age, :o).execute
    assert 27, age_result
    
    types_result = Query.new.select(:o).where(eyal, type, :o).execute
    assert types_result.include?(person)
    assert types_result.include?(resource)
  end
end
