module TestContextAwareAdapter
  def test_single_context
    adapter = ConnectionPool.add_data_source :type => :rdflite
    file = File.dirname(File.expand_path(__FILE__)) + '/../test_data.nt'
    adapter.load(file)

    context = Query.new.distinct(:c).where(:s,:p,:o,:c).execute(:flatten => true)
    assert_instance_of RDFS::Resource, context
    assert_equal RDFS::Resource.new("file:#{file}"), context
  end

  def test_multiple_context
    adapter = ConnectionPool.add_data_source :type => :rdflite
    file = File.dirname(File.expand_path(__FILE__)) + '/../test_data.nt'
    adapter.load(file)
    file_context = RDFS::Resource.new("file:#{file}")

    eyal = RDFS::Resource.new 'eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test'
    adapter.add(eyal, age, test, 'context')

    context = Query.new.distinct(:c).where(:s,:p,:o,:c).execute
    assert_equal file_context, context[0]
    assert_equal 'context', context[1]

    assert_equal 10, Query.new.count.distinct(:s).where(:s, :p, :o, nil).execute
    assert_equal 1, Query.new.count.distinct(:s).where(:s, :p, :o, 'context').execute
    assert_equal 9, Query.new.count.distinct(:s).where(:s, :p, :o, file_context).execute
  end
end