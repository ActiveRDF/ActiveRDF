# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'test/unit'
require 'active_rdf'
require 'test_helper'
require 'active_rdf/objectmanager/ordered_set'

class TestOrderedSet < Test::Unit::TestCase

  def setup
    ConnectionPool.clear
    
    adapter = get_default_primary_write_adapter
    adapter.load "#{File.dirname(__FILE__)}/../test_person_data.nt"
    adapter.load "#{File.dirname(__FILE__)}/../test_rdf_data.nt"
    ObjectManager.construct_classes
   
    @ordered_set = OrderedSet.new('http://activerdf.org/test/ordered_set')
      
    @item_1 = RDFS::Resource.new 'http://activerdf.org/test/item_1'
    @item_2 = RDFS::Resource.new 'http://activerdf.org/test/item_2'
    @item_3 = RDFS::Resource.new 'http://activerdf.org/test/item_3'      
  end
    
  def test_resource_type
    assert_kind_of OrderedSet, @ordered_set
  end

  def test_query
    # add items to container
    @ordered_set.add @item_1
    @ordered_set.add @item_2
    @ordered_set.add @item_3
    
    # check if all items are inserted
    assert_equal 3, @ordered_set.elements.size
    
    # check elements array
    assert @ordered_set.elements.include?(@item_1)
    assert @ordered_set.elements.include?(@item_2)
    assert @ordered_set.elements.include?(@item_3)
  end
  
    def test_at
    # add items to container
    @ordered_set.add @item_1
    @ordered_set.add @item_2
    @ordered_set.add @item_3
    
    # check if all items are inserted
    assert_equal 3, @ordered_set.elements.size
    
    # check item for each position
    assert_equal @item_1.uri, @ordered_set.at(1).uri
    assert_equal @item_2.uri, @ordered_set.at(2).uri
    assert_equal @item_3.uri, @ordered_set.at(3).uri
  end
  
  def test_order
    # add items to container
    @ordered_set.add @item_1
    @ordered_set.add @item_2
    @ordered_set.add @item_3
    
    # check if container include each item
    assert_equal @ordered_set.elements[0].uri, @item_1.uri
    assert_equal @ordered_set.elements[1].uri, @item_2.uri
    assert_equal @ordered_set.elements[2].uri, @item_3.uri
  end
  
  def test_delete
    # add items to container
    @ordered_set.add @item_1
    @ordered_set.add @item_2
    @ordered_set.add @item_3
    
    # check item number
    assert_equal 3, @ordered_set.elements.size
    
    # delete item 2
    @ordered_set.delete(2)
    assert_equal 2, @ordered_set.elements.size
    assert_equal @ordered_set.elements[0].uri, @item_1.uri
    assert_equal @ordered_set.elements[1].uri, @item_3.uri 
    
    # delete all items
    @ordered_set.delete_all
    assert_equal 0, @ordered_set.elements.size
  end
  
  def test_replace
    # add items to container
    @ordered_set.add @item_1
    @ordered_set.add @item_2
    
    assert_equal 2, @ordered_set.elements.size
    
    # replace item 2
    @ordered_set.replace(2, @item_3)
    
    # check if item 2 is replaced
    assert_equal 2, @ordered_set.elements.size
    assert_equal @ordered_set.elements[0].uri, @item_1.uri
    assert_equal @ordered_set.elements[1].uri, @item_3.uri
  end
    
end
