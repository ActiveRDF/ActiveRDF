# Unit Test of NodeFactory with SPARQL connections
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
require 'active_rdf/test/common'
require 'adapter/sparql/sparql_adapter'

class TestSparqlConnection < Test::Unit::TestCase
	def setup
		setup_any
	end
	
	def teardown
		delete_any
	end
	
	def test_connnection_json
		created = NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'my.opera.com', :port => 80 , :context => 'community/sparql/sparql', :result_format => :xml)
		current = NodeFactory.connection
		assert_equal created, current
	end
	
	def test_connection_xml
		created = NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'm3pe.org', :port => 2020 , :context => 'books', :result_format => :json)
		current = NodeFactory.connection
		assert_equal created, current
	end	
	
	def test_json_xml_connection
		NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'my.opera.com', :port => 80 , :context => 'community/sparql/sparql', :result_format => :xml)
		assert_equal :sparql, NodeFactory.connection.adapter_type
		assert_equal 'my.opera.com', NodeFactory.connection.host
		
		NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'm3pe.org', :port => 2020 , :context => 'books', :result_format => :json)
		assert_equal :sparql, NodeFactory.connection.adapter_type
		assert_equal 'm3pe.org', NodeFactory.connection.host

		NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'my.opera.com', :port => 80 , :context => 'community/sparql/sparql', :result_format => :xml)
		assert_equal :sparql, NodeFactory.connection.adapter_type
		assert_equal 'my.opera.com', NodeFactory.connection.host

		created = NodeFactory.connection(:construct_class_model => false, :adapter => :sparql, :host => 'm3pe.org', :port => 2020 , :context => 'books', :result_format => :json)
		current = NodeFactory.connection
		assert_equal created,current
	end
end
