# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'queryengine/ntriples_parser'
require "#{File.dirname(__FILE__)}/../common"

class TestNTriplesParser < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_the_parser
    str = <<EOF
<http://www.johnbreslin.com/blog/author/cloud/#foaf> <http://xmlns.com/foaf/0.1/surname> "Breslin" .
<http://www.johnbreslin.com/blog/author/cloud/#foaf> <http://xmlns.com/foaf/0.1/firstName> "John" .
<http://www.johnbreslin.com/blog/author/cloud/> <http://purl.org/dc/terms/created> "1999-11-30T00:00:00" .  				
EOF
    
    results = NTriplesParser.parse(str)
    assert_equal 9, results.flatten.size
    assert_equal 3, results[0].size
    require "pp"
    pp results
#    adapter = ConnectionPool.add_data_source(:type => :sparql)
#    assert_instance_of RDFS::Resource, results[0][0]
#    assert_instance_of String, results[0][2]

  end
 
end
