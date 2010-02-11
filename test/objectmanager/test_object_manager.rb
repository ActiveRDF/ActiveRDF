# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require "#{File.dirname(__FILE__)}/../common"

class TestObjectManager < Test::Unit::TestCase
  include SetupAdapter

  def test_resource_creation
    assert_nothing_raised { RDFS::Resource.new('abc') }

    r1 = RDFS::Resource.new('abc')
    r2 = RDFS::Resource.new('cde')
    r3 = RDFS::Resource.new('cde')
    assert_equal r3, RDFS::Resource.new(r3)
    assert_equal r3, RDFS::Resource.new(r3.to_s)

    assert_equal 'abc', r1.uri
    assert_equal 'cde', r2.uri
    assert_equal r3, r2
  end

  def test_class_construct_classes
    assert_equal RDFS::Resource.new('http://activerdf.org/test/Person'), TEST::Person
    assert_kind_of Class, TEST::Person
    assert TEST::Person.ancestors.include?(RDFS::Resource)
    new_person = TEST::Person.new(TEST::michael)
    assert_instance_of TEST::Person, new_person
    assert new_person.respond_to?(:uri)

    assert_equal RDFS::Resource.new('http://www.w3.org/2000/01/rdf-schema#Class'), RDFS::Class
    assert_kind_of Class, RDFS::Class
    assert RDFS::Class.ancestors.include?(RDFS::Resource)
    new_class = RDFS::Class.new(TEST::klass)
    assert_instance_of RDFS::Resource, new_class
    assert new_class.respond_to?(:uri)
  end

  def test_invalid_resource
    assert_raise ActiveRdfError do
      Query.new.distinct(:o).where(TEST::Person.new(''),TEST::age,:o).execute
    end
  end

  def test_custom_code
    TEST::Person.module_eval{ def hello; 'world'; end }
    assert_respond_to TEST::Person.new(''), :hello
    assert_equal 'world', TEST::Person.new('').hello
  end

  def test_class_uri
    assert_equal RDFS::Resource.new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), RDF::type
    assert_equal RDF::type, RDFS::Resource.new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
    assert_equal TEST::Person, RDFS::Resource.new('http://activerdf.org/test/Person')
    assert_equal RDFS::Resource.new('http://activerdf.org/test/Person'), TEST::Person
  end

  def test_to_xml#
    @adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    eyal.age = 29
    assert_equal 29, eyal.age
    xml = eyal.to_xml
    ['<rdf:Description rdf:about="#eyal">',
    '<test:eye xml:lang="en">blue</test:eye>',
    '<test:email rdf:datatype="http://www.w3.org/2001/XMLSchema#string">eyal@cs.vu.nl</test:email>',
    '<test:email rdf:datatype="http://www.w3.org/2001/XMLSchema#string">eyal.oren@deri.org</test:email>',
    '<rdf:type rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>',
    '<rdf:type rdf:resource="http://activerdf.org/test/Person"/>',
    '<test:age rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">29</test:age>'].each do |str|
      assert xml.include?(str), "xml does not contain #{str}"
    end

    require 'net/http'
    url = 'http://librdf.org/parse'
    uri = URI.parse(url)
    req = Net::HTTP::Post.new(url)
    req.set_form_data('content'=>eyal.to_xml, 'language'=>'rdfxml')
    res = Net::HTTP.new(uri.host,uri.port).start {|http| http.request(req) }
    result = res.body.match(/Found.*triples/)[0]
    assert_equal "Found 6 triples", result, 'invalid XML generated (according to online parser at librdf.org)'
  end
end
