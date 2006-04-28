# = test_identified_resource.rb
#
# Unit Test of IdentifiedResource Class method
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

require 'test/unit'
require 'active_rdf'
require 'node_factory'

class TestIdentifiedResource < Test::Unit::TestCase
	def setup
		NodeFactory.connection :adapter => :yars, :host => DB_HOST, :port => 8080, :context => 'nothing'
	end
	
	def test_A_classuri_on_class_level
		class_uri = IdentifiedResource.class_URI
		assert_not_nil(class_uri)
		assert_kind_of(IdentifiedResource, class_uri)
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource', class_uri.uri)
	end

	def test_equality_identified_resources
		a = IdentifiedResource.new 'abc'
		b = IdentifiedResource.new 'abc'
		assert_equal a,b
	end
	
	def test_B_classuri_on_instance_level
		resource = IdentifiedResource.new('http://m3pe.org/activerdf/test/identifiedresource')
		class_uri = resource.class_URI
		assert_not_nil(class_uri)
		assert_kind_of(IdentifiedResource, class_uri)
		assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource', class_uri.uri)
	end
	
end
