# Author: Michele Nucci
# License: LGPL
#
# Test for new syntax in ActiveRDF for Talia

require 'test/unit'
require 'active_rdf'
require 'federation/connection_pool'
require "#{File.dirname(__FILE__)}/../common"

class TestTaliaSyntax < Test::Unit::TestCase
  def setup
   ConnectionPool.clear
 end
  
 def test_syntax
   adapter = get_write_adapter
   adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
   
   Namespace.register(:test, 'http://activerdf.org/test/')
   
   eyal    = RDFS::Resource.new 'http://activerdf.org/test/eyal'
   michele = RDFS::Resource.new 'http://activerdf.org/test/michele'
    
   # Adding some triples 
   adapter.add(michele, RDFS::subClassOf, RDF::Resource)
   adapter.add(michele, RDF::type, Namespace.lookup(:rdfs, 'Class') )
   adapter.add(michele, RDF::type, Namespace.lookup(:test, 'Person') )
   adapter.add(eyal, Namespace.lookup(:test, 'friendOf'), michele)
   
   assert_nothing_raised(ActiveRdfError) { 
     michele.car = 'car1'
     michele.car = 'car2'
   }
  
  # new syntax (shortcut) to get all properties values about TEST::car
  x = michele[TEST::car]
  assert_not_equal [], x
  
  # Adding new property (new triple) with the new syntax
  x << 'car3'
  assert_equal ['car2', 'car3'], x
  
  # test inverse ===========================================================
  y = michele.inverse
  assert_equal '<http://activerdf.org/test/eyal>', y[Namespace.lookup(:test, 'friendOf')].to_s
  # ========================================================================
  
  # test deletion triple with new syntax ===================================
  
  # remove a triple whose value is specified relater to TEST::car
  x.remove('car3')
  assert_equal ['car2'], x
  
  # remove every triples related to TEST::car
  x.remove
  assert_equal [], x
  
  # remove EVERY triples related to a specified resource
  FederationManager.delete_all(michele)
  result = Query.new.select(:p, :o).where(michele, :p, :o).execute
  assert_equal [], result
  # ======================================================================== 
 
 
 end
  
end