module TestBnodeCapableAdapter
  def test_load_bnodes
    @adapter.load(File.dirname(File.expand_path(__FILE__)) + '/../test_bnode_data.nt')

    # loaded five triples in total
    assert_equal 8, @adapter.size

    # collecting the bnodes
    bnodes = Query.new.distinct(:s).where(:s,:p,:o).execute

    # triples contain two distinct bnodes
    assert_equal 3, bnodes.size

    # assert that _:a1 occurs in three triples
    assert_equal 3, Query.new.select(:p,:o).where(bnodes[0], :p, :o).execute.size
    # assert that _:a2 occurs in two triples
    assert_equal 2, Query.new.select(:p,:o).where(bnodes[1], :p, :o).execute.size
    # assert that _:a3 occurs in two triples
    assert_equal 3, Query.new.select(:p,:o).where(bnodes[2], :p, :o).execute.size
  end

  def test_bnodes
    @adapter.load(File.dirname(File.expand_path(__FILE__)) + '/../test_bnode_data.nt')

    #ObjectManager.construct_classes
    people = TEST::Person.find_all
    assert_equal 2, people.size
    assert_equal 29, people[1].age
    assert_equal "Another Person", TEST::Person.find_all[1].name
  end
end