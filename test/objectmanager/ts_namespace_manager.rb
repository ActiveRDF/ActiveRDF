require 'test/unit'
require 'active_rdf'

class TestObjectCreation < Test::Unit::TestCase
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

		assert_equal rdftype, Namespace.instance.expand(:rdf, :type)
		assert_equal rdftype, Namespace.instance.expand(:rdf, 'type')
		assert_equal rdftype, Namespace.instance.expand('rdf', :type)
		assert_equal rdftype, Namespace.instance.expand('rdf', 'type')

		assert_equal rdfsresource, Namespace.instance.expand(:rdfs, :Resource)
		assert_equal rdfsresource, Namespace.instance.expand(:rdfs, 'Resource')
		assert_equal rdfsresource, Namespace.instance.expand('rdfs', :Resource)
		assert_equal rdfsresource, Namespace.instance.expand('rdfs', 'Resource')
	end

	def test_default_ns_lookup
		rdftype = RDFS::Resource.lookup RdfType
		rdfsresource = RDFS::Resource.lookup RdfsResource

		assert_equal rdftype, Namespace.instance.lookup(:rdf, :type)
		assert_equal rdfsresource, Namespace.instance.lookup(:rdfs, :Resource)
	end

	def test_find_prefix
		assert_equal :rdf, Namespace.instance.prefix(Namespace.instance.lookup(:rdf, :type))
		assert_equal :rdf, Namespace.instance.prefix(Namespace.instance.expand(:rdf, :type))

		assert_equal :rdfs, Namespace.instance.prefix(Namespace.instance.lookup(:rdfs, :Resource))
		assert_equal :rdfs, Namespace.instance.prefix(Namespace.instance.expand(:rdfs, :Resource))
	end
end
