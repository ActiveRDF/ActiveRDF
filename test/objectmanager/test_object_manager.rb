# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require "#{File.dirname(__FILE__)}/../common"

class TestObjectManager < Test::Unit::TestCase
  def setup
    ConnectionPool.clear
  end

  def teardown
  end

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
		adapter = get_write_adapter
		adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"

		Namespace.register(:test, 'http://activerdf.org/test/')

		assert_equal RDFS::Resource.new('http://activerdf.org/test/Person'), TEST::Person
    assert_kind_of Class, TEST::Person
    assert TEST::Person.ancestors.include?(RDFS::Resource)
    assert_instance_of TEST::Person, TEST::Person.new('')
    assert TEST::Person.new('').respond_to?(:uri)

		assert_equal RDFS::Resource.new('http://www.w3.org/2000/01/rdf-schema#Class'), RDFS::Class
    assert RDFS::Class.ancestors.include?(RDFS::Resource)
    assert_kind_of Class, RDFS::Class
    assert_instance_of RDFS::Resource, RDFS::Class.new('')
    assert RDFS::Class.new('').respond_to?(:uri)
  end

  def test_custom_code
		Namespace.register(:test, 'http://activerdf.org/test/')

    TEST::Person.module_eval{ def hello; 'world'; end }
    assert_respond_to TEST::Person.new(''), :hello
    assert_equal 'world', TEST::Person.new('').hello
  end

  def test_class_uri
		adapter = get_write_adapter
		adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
		Namespace.register(:test, 'http://activerdf.org/test/')

    assert_equal RDFS::Resource.new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), RDF::type
    assert_equal RDF::type, RDFS::Resource.new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
    assert_equal TEST::Person, RDFS::Resource.new('http://activerdf.org/test/Person')
    assert_equal RDFS::Resource.new('http://activerdf.org/test/Person'), TEST::Person
  end

  def test_to_xml
    get_adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    Namespace.register(:test, 'http://activerdf.org/test/')

    eyal = RDFS::Resource.new 'http://activerdf.org/test/eyal'
    eyal.age = 29
    assert_equal 29, eyal.age
    snippet =
'<rdf:Description rdf:about="#eyal">
  <test:age rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">29</test:age>
  <test:eye rdf:datatype="http://www.w3.org/2001/XMLSchema#string">blue</test:eye>
  <rdf:type rdf:resource="http://activerdf.org/test/Person"/>
  <rdf:type rdf:resource="http://www.w3.org/2000/01/rdf-schema#Resource"/>
</rdf:Description>
</rdf:RDF>'
    assert eyal.to_xml.include?(snippet)


    url = 'http://gollem.swi.psy.uva.nl/cgi-bin/rdf-parser'
    uri = URI.parse(url)
    req = Net::HTTP::Post.new(url)
    req.set_form_data('rdf' => eyal.to_xml)
    res = Net::HTTP.new(uri.host, uri.port).start { |http| http.request(req) }
    assert_match /RDF statement parsed successfully/, res.body, "SWI-Prolog failed to parse XML output"
  end
end
