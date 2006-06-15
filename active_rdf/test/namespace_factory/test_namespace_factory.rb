# = test_all.rb
#
# Unit Test of NamespaceFactory
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#
# == To-do
#
# * To-do 1
#

require 'test/unit'
require 'active_rdf'
require 'namespace_factory'
require 'active_rdf/test/common'

class TestNamespaceFactory < Test::Unit::TestCase
	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end

  def test_add_namespace
    NamespaceFactory.add(:prefix, 'http://testuri#')
    resource = NamespaceFactory.get(:prefix, :test)
    assert_kind_of IdentifiedResource, resource
    assert_equal resource.uri, 'http://testuri#test'
    
    assert_raise(NamespaceFactoryError) { NamespaceFactory.get(:abc,:cde) }
  end
  
	def test_load_namespace
		rdf_type = NamespaceFactory.get(:rdf, :type)
		assert_not_nil(rdf_type)
		assert(rdf_type.instance_of?(IdentifiedResource))
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#type', rdf_type.uri)
		
		rdfs_domain = NamespaceFactory.get(:rdfs, :domain)
		assert_not_nil(rdfs_domain)
		assert(rdfs_domain.instance_of?(IdentifiedResource))
		assert_equal('http://www.w3.org/2000/01/rdf-schema#domain', rdfs_domain.uri)
		
		rdfs_subclass = NamespaceFactory.get(:rdfs, :subClassOf)
		assert_not_nil(rdfs_subclass)
		assert(rdfs_subclass.instance_of?(IdentifiedResource))
		assert_equal('http://www.w3.org/2000/01/rdf-schema#subClassOf', rdfs_subclass.uri)
		
		owl_thing = NamespaceFactory.get(:owl, :Thing)
		assert_not_nil(owl_thing)
		assert(owl_thing.instance_of?(IdentifiedResource))
		assert_equal('http://www.w3.org/2002/07/owl#Thing', owl_thing.uri)
	end
	
end
