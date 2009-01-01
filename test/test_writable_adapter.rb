require File.join(File.dirname(File.expand_path(__FILE__)), 'test_activerdf_adapter')

module TestWritableAdapter
  include TestActiveRdfAdapter

  dir = File.dirname(File.expand_path(__FILE__))
  @@test_person_data = File.join(dir,'test_person_data.nt')
  @@test_escaped_data = File.join(dir,'test_escaped_data.nt')

  def test_count_query
    @adapter.load(@@test_person_data)
    assert_kind_of Fixnum, Query.new.count(:s).where(:s,:p,:o).execute
    assert_equal 21, Query.new.count(:s).where(:s,:p,:o).execute
  end

  def test_update_value
    @adapter.load @@test_person_data

    assert_equal 1, @@eyal.age.size
    assert_equal 27, @@eyal.age.to_a.first
    
    # add a Fixnum
    @@eyal.age += 30
    assert_equal 2, @@eyal.age.size
    assert @@eyal.age.include?(30)
    assert @@eyal.age.include?(27)

    @@eyal.age = 40
    assert_equal 1, @@eyal.age.size
    assert_equal @@eyal.age, 40
  end
  
#  def test_load_escaped_literals
#    @adapter.load(@@test_escaped_data)
#
#    assert_equal "ümlauts and ëmlauts", @@eyal.comment
#    assert_equal "line\nbreaks, <p>'s and \"quotes\"", @@eyal.encoded
#  end

  def test_person_data
    @adapter.load(@@test_person_data)

    color = Query.new.select(:o).where(@@eyal,@@eye,:o).execute(:flatten => true)

    assert_instance_of String, color
    assert_equal 'blue', color
    assert @@eyal.test::eye == color 

    assert @@eyal.instance_of?(TEST::Person)
    assert @@eyal.instance_of?(RDFS::Resource)
  end

  def test_delete_data
    @adapter.add(@@eyal, @@mbox, @@mboxval)

    @adapter.add(@@eyal, @@age, @@ageval)
    @adapter.delete(@@eyal, @@age, @@ageval)
    assert_equal 1, @adapter.size

    @adapter.add(@@eyal, @@age, @@ageval)
    @adapter.delete(:s, :p, @@ageval)
    assert_equal 1, @adapter.size
  
    @adapter.add(@@eyal, @@age, @@ageval)
    @adapter.delete(:s, @@age, :o)
    assert_equal 1, @adapter.size
  
    @adapter.add(@@eyal, @@age, @@ageval)
    @adapter.delete(@@eyal, :p, :o)
    assert_equal 0, @adapter.size

    @adapter.load(@@test_person_data)
    assert_equal 21, @adapter.size

    @adapter.delete(@@eyal, nil, nil)
    assert_equal 15, @adapter.size

    @adapter.delete(nil, nil, nil)
    assert_equal 0, @adapter.size
  end

  def test_clear
    @adapter.add(@@eyal, @@age, @@test)
    assert 0 < @adapter.size 
  
    @adapter.clear
    assert_equal 0, @adapter.size 
  end  

  def test_load_from_file_and_clear
    @adapter.load(@@test_person_data)
    assert_equal 21, @adapter.size
    @adapter.clear
    assert_equal 0, @adapter.size
  end

  def test_remote_load_and_clear
    @adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/ntriples/test.nt')
    assert_equal 30, @adapter.size
    
    @adapter.clear
    assert_equal 0, @adapter.size
    
    @adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema.rdf', 'rdfxml')
    assert_equal 76, @adapter.size
  end
end