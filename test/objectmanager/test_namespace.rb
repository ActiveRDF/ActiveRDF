# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'objectmanager/namespace'
require "#{File.dirname(__FILE__)}/../common"

class TestNamespace < Test::Unit::TestCase
  Rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  RdfType = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
  RdfsResource = 'http://www.w3.org/2000/01/rdf-schema#Resource'
  Rdfs = 'http://www.w3.org/2000/01/rdf-schema#'

  def setup
  end

  def teardown
  end

  def test_default_ns_expansion
    rdftype = RdfType
    rdfsresource = RdfsResource

    assert_equal rdftype, Namespace.expand(:rdf, :type)
    assert_equal rdftype, Namespace.expand(:rdf, 'type')
    assert_equal rdftype, Namespace.expand('rdf', :type)
    assert_equal rdftype, Namespace.expand('rdf', 'type')

    assert_equal rdfsresource, Namespace.expand(:rdfs, :Resource)
    assert_equal rdfsresource, Namespace.expand(:rdfs, 'Resource')
    assert_equal rdfsresource, Namespace.expand('rdfs', :Resource)
    assert_equal rdfsresource, Namespace.expand('rdfs', 'Resource')
  end

  def test_default_ns_lookup
    rdftype = RDFS::Resource.new RdfType
    rdfsresource = RDFS::Resource.new RdfsResource

    assert_equal rdftype, Namespace.lookup(:rdf, :type)
    assert_equal rdfsresource, Namespace.lookup(:rdfs, :Resource)
  end

  def test_find_prefix
    assert_equal :rdf, Namespace.prefix(Namespace.lookup(:rdf, :type))
    assert_equal :rdf, Namespace.prefix(Namespace.expand(:rdf, :type))

    assert_equal :rdfs, Namespace.prefix(Namespace.lookup(:rdfs, :Resource))
    assert_equal :rdfs, Namespace.prefix(Namespace.expand(:rdfs, :Resource))
  end

  def test_class_localname
		assert_equal 'type', Namespace.localname(Namespace.lookup(:rdf, :type))
		assert_equal 'Class', Namespace.localname(Namespace.lookup(:rdfs, :Class))
  end

  def test_class_register
		test = 'http://test.org/'
		abc = "#{test}abc"
		Namespace.register :test, test

		assert_equal abc, Namespace.expand(:test, :abc)
  end
end
