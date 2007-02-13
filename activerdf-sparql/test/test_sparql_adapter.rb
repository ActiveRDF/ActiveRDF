# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'active_rdf'
require 'test/unit'
require 'federation/federation_manager'
require 'queryengine/query'

class TestSparqlAdapter < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
		@adapter = ConnectionPool.add(:type => :sparql,
																:url => "http://m3pe.org:8080/repositories/test-people/",
																:results => :sparql_xml)
  end

  def teardown
  end

  def test_registration
    assert_instance_of SparqlAdapter, @adapter
  end

  def test_simple_query
		begin
			result = Query.new.select(:s).where(:s, Namespace.lookup(:rdf,:type), :t).execute.first
		rescue
			# don't fail if SPARQL server doesn't respond
		else
			assert_instance_of RDFS::Resource, result

			second_result = Query.new.select(:s, :p).where(:s, :p, 27).execute.flatten
			assert_equal 2, second_result.size
			assert_instance_of RDFS::Resource, second_result[0]
			assert_instance_of RDFS::Resource, second_result[1]
		end
  end

  def test_query_with_block
		begin
			reached_block = false
			Query.new.select(:s,:p).where(:s,:p, 27).execute do |s,p|
				reached_block = true
				assert_equal 'http://activerdf.org/test/eyal', s.uri
				assert_equal 'http://activerdf.org/test/age', p.uri
			end
			assert reached_block, "querying with a block does not work"
		rescue
		end
  end

  def test_refuse_to_write
		begin
			eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
			age = RDFS::Resource.new 'foaf:age'
			test = RDFS::Resource.new 'test'

			# NameError gets thown if the method is unknown
			assert_raises NoMethodError do
				@adapter.add(eyal, age, test)
			end
		rescue
		end
  end

  def test_federated_query
		begin
			# we first ask one sparql endpoint
			first_size = Query.new.select(:o).where(:s, :p, :o).execute(:flatten => false).size
			ConnectionPool.clear

			# then we ask the second endpoint
			ConnectionPool.add_data_source(:type => :sparql, 
																		 :url => "http://www.m3pe.org:8080/repositories/mindpeople",
																		 :results => :sparql_xml)

			second_size = Query.new.select(:o).where(:s, :p, :o).execute.size

			ConnectionPool.clear

			# now we ask both
			ConnectionPool.add_data_source(:type => :sparql,
																		 :url => "http://www.m3pe.org:8080/repositories/test-people/",
																		 :results => :sparql_xml)
			ConnectionPool.add_data_source(:type => :sparql,
																		 :url => "http://www.m3pe.org:8080/repositories/mindpeople",
																		 :results => :sparql_xml)

			union_size = Query.new.select(:o).where(:s, :p, :o).execute.size
			assert_equal union_size, first_size + second_size
		rescue
		end
  end

  def test_person_data
		begin
			eyal = RDFS::Resource.new("http://activerdf.org/test/eyal")
			eye = RDFS::Resource.new("http://activerdf.org/test/eye")
			type = RDFS::Resource.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
			age = RDFS::Resource.new("http://activerdf.org/test/age")
			person = RDFS::Resource.new("http://www.w3.org/2000/01/rdf-schema#Resource")
			resource = RDFS::Resource.new("http://activerdf.org/test/Person")

			color = Query.new.select(:o).where(eyal, eye,:o).execute.first
			assert_equal 'blue', color
			assert_instance_of String, color

			age_result = Query.new.select(:o).where(eyal, age, :o).execute.first.to_i
			assert_equal 27, age_result

			types_result = Query.new.select(:o).where(eyal, type, :o).execute
			assert types_result.include?(person)
			assert types_result.include?(resource)
		rescue
		end
  end
end
