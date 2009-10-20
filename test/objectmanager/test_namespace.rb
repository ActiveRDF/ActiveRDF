# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'objectmanager/namespace'
require "#{File.dirname(__FILE__)}/../common"

class TestNamespace < Test::Unit::TestCase
  include ActiveRDF

  Rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  Rdfs = 'http://www.w3.org/2000/01/rdf-schema#'
  RdfType = RDFS::Resource.new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
  RdfsResource = RDFS::Resource.new('http://www.w3.org/2000/01/rdf-schema#Resource')

  def setup
  end

  def teardown
  end

  def test_default_ns_expansion
    rdftype = RdfType
    rdfsresource = RdfsResource

    assert_equal rdftype, RDF::type
    assert_equal rdftype, Namespace.lookup(:rdf, :type)
    assert_equal rdftype, Namespace.lookup(:rdf, 'type')
    assert_equal rdftype, Namespace.lookup('rdf', :type)
    assert_equal rdftype, Namespace.lookup('rdf', 'type')

    assert_equal rdfsresource, RDFS::Resource
    assert_equal rdfsresource, Namespace.lookup(:rdfs, :Resource)
    assert_equal rdfsresource, Namespace.lookup(:rdfs, 'Resource')
    assert_equal rdfsresource, Namespace.lookup('rdfs', :Resource)
    assert_equal rdfsresource, Namespace.lookup('rdfs', 'Resource')
  end

  def test_registration_of_rdf_and_rdfs
    rdftype = RDFS::Resource.new RdfType
    rdfsresource = RDFS::Resource.new RdfsResource

    assert_equal rdftype, RDF::type
    assert_equal rdfsresource, RDFS::Resource
  end

  def test_find_prefix
    assert_equal :rdf, Namespace.prefix(Namespace.lookup(:rdf, :type))
    assert_equal :rdf, Namespace.prefix(Namespace.expand(:rdf, :type))

    assert_equal :rdfs, Namespace.prefix(Namespace.lookup(:rdfs, :Resource))
    assert_equal :rdfs, Namespace.prefix(Namespace.expand(:rdfs, :Resource))
  end

  def test_class_localname
    assert_equal 'type', Namespace.lookup(:rdf, :type).localname
    assert_equal 'type', RDF::type.localname

    assert_equal 'Class', Namespace.lookup(:rdfs, :Class).localname
    assert_equal 'Class', RDFS::Class.localname
  end

  def test_class_register
    test = 'http://activerdf.org/test/'
    abc = RDFS::Resource.new("#{test}abc")
    Namespace.register :test, test

    assert_equal abc, Namespace.lookup(:test, :abc)
    assert_equal abc, TEST::abc
  end

  def test_attributes
    assert_nothing_raised { RDFS::domain }
    assert_nothing_raised { RDF::type }
    assert_raise(NameError) { FOAF::type }

    foaf = 'http://xmlns.com/foaf/0.1/'
    Namespace.register :foaf, foaf

    foafname = RDFS::Resource.new(foaf + 'name')
    assert_equal foafname, FOAF::name
  end
end
