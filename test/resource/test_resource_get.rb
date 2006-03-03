# = test_resource_get.rb
#
# Unit Test of Resource get method
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
require 'node_factory'

class TestResourceGet < Test::Unit::TestCase

	def setup
		params = { :adapter => :redland }
		NodeFactory.connection(params)
	end
	
	def test_1_empty_db
		subject = NodeFactory.create_basic_identified_resource("http://m3pe.org/subject")
		predicate = NodeFactory.create_basic_identified_resource("http://m3pe.org/predicate")
		result = Resource.get(subject, predicate)
	end
	
end
