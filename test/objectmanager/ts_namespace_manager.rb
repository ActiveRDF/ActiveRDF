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
end
