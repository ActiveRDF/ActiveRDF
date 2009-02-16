require File.dirname(File.expand_path(__FILE__)) + '/test_activerdf_adapter'

module TestWritableAdapter
  include TestActiveRdfAdapter

  dir = File.dirname(File.expand_path(__FILE__))
  @@test_person_data = dir + '/../test_person_data.nt'
  @@test_escaped_data = dir + '/../test_escaped_data.nt'

  def test_clear_on_new
    @adapter.load(@@test_person_data)
    @adapter.close
    ConnectionPool.clear
    adapter = ConnectionPool.add(@adapter_args.merge(:new => 'yes'))
    assert_equal 0, adapter.size, "datastore not cleared when requested"
    adapter.close
  end

  def test_count_query
    @adapter.load(@@test_person_data)
    assert_kind_of Fixnum, Query.new.count(:s).where(:s,:p,:o).execute
    assert_equal 21, Query.new.count(:s).where(:s,:p,:o).execute
  end

  def test_update_value
    @adapter.load(@@test_person_data)

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
#    eyal = TEST::eyal
#
#    assert_equal "ümlauts and ëmlauts", eyal.comment.only
#    assert_equal "line\nbreaks, <p>'s and \"quotes\"", eyal.encoded.only
#  end

  def test_person_data
    @adapter.load(@@test_person_data)

    color = Query.new.select(:o).where(@@eyal,@@eye,:o).execute(:flatten => true)

    assert_instance_of LocalizedString, color
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

  def test_multi_join
    sue = Namespace.lookup(:test, 'Sue')
    mary = Namespace.lookup(:test, 'Mary')
    anne = Namespace.lookup(:test, 'Anne')

    @adapter.add TEST::ancestor, RDF::type, OWL::TransitiveProproperty
    @adapter.add sue, TEST::ancestor, mary
    @adapter.add mary, TEST::ancestor, anne

    # test that query with multi-join (joining over 1.p==2.p and 1.o==2.s) works
    query = Query.new.select(:GP, :child)
    query.where(:p, RDF::type, OWL::TransitiveProproperty)
    query.where(:GP, :p, :c1)
    query.where(:c1, :p, :child)
    # TODO: check the results of this query
    assert_equal 1, query.execute.size

    sam = Namespace.lookup(:test, 'Sam')
    mike = Namespace.lookup(:test, 'Mike')
    adam = Namespace.lookup(:test, 'Adam')

    @adapter.add TEST::spouse, RDF::type, OWL::SymmetricProproperty
    @adapter.add sam, TEST::spouse, sue
    @adapter.add sam, TEST::ancestor, mary
    @adapter.add mike, TEST::spouse, mary
    @adapter.add mike, TEST::ancestor, adam
    @adapter.add adam, TEST::spouse, anne

    query = Query.new.select(:GP1,:GP2)
    query.where(:GP1, TEST::ancestor, :c1)
    query.where(:c1, TEST::ancestor, :c2)
    query.where(:x3, TEST::ancestor, :c2)
    query.where(:GP2, TEST::ancestor, :x3)
    # TODO: check the results of this query
    assert query.execute.size > 0

    # make sure order doesn't matter when building query
    query = Query.new.select(:GP1,:GP2)
    query.where(:GP1, TEST::ancestor, :c1)
    query.where(:GP2, TEST::ancestor, :x3)
    query.where(:c1, TEST::ancestor, :c2)
    query.where(:x3, TEST::ancestor, :c2)
    # TODO: check the results of this query
    assert query.execute.size > 0
  end

#  def test_limit_and_offset
#    @adapter.load(@@test_person_data)
#
#    assert_equal 7, RDFS::Resource.find(:all).size
#    assert_equal 5, RDFS::Resource.find(:all, :limit => 5).size
#    assert_equal 4, RDFS::Resource.find(:all, :limit => 4, :offset => 3).size
#    assert RDFS::Resource.find(:all, :limit => 4, :offset => 3) != RDFS::Resource.find(:all, :limit => 4)
#
#    assert_equal [TEST::eyal, TEST::age, TEST::car], RDFS::Resource.find(:all, :limit => 3, :order => RDF::type)
#  end
end