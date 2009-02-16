require 'active_rdf'
require "#{File.dirname(File.expand_path(__FILE__))}/../common"

module TestActiveRdfAdapter
  include SetupAdapter

  @@test = TEST::test
  @@eyal = TEST::eyal
  @@eye = TEST::eye
  @@name = TEST::name
  @@mbox = TEST::mbox
  @@age = TEST::age
  @@ageval = 27
  @@mboxval = 'aahfgiouhfg'

  # override setup in TestCase. define @adapter_args & finally call super
  def test_simple_query
    @adapter.add(@@eyal, @@name, "eyal oren")
    @adapter.add(@@eyal, @@age, @@ageval)

    result = Query.new.distinct(:s).where(:s, :p, :o).execute(:flatten => true)
    assert_instance_of RDFS::Resource, result
    assert_equal @@eyal.uri, result.uri

    result = Query.new.distinct(:o).where(@@eyal,@@age,:o).execute(:flatten => true)
    assert_equal @@ageval, result
  end

  def test_query_with_block
    @adapter.add(@@eyal, @@age, @@ageval)
    Query.new.select(:s,:p,:o).where(:s,:p,:o).execute(:flatten => false) do |s,p,o|
      assert_equal @@eyal.uri, s.uri
      assert_equal @@age.uri, p.uri
      assert_equal @@ageval, o
    end
  end

  def test_close
    @adapter.add(@@eyal, @@age, @@test)
    results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    assert results.flatten.size > 0

    @adapter.close
    assert_equal 0, ConnectionPool.adapters.size
    assert_raises ActiveRdfError do
      results = Query.new.select(:s,:p,:o).where(:s,:p,:o).execute
    end
  end

  def test_dump
    @adapter.add(@@eyal, @@age, @@test)

    dump = @adapter.dump
    assert_kind_of Array, dump
  end

  def test_size
    @adapter.add(@@eyal, @@age, @@test)
    assert 1, @adapter.size
  end


#  def test_escaped_literals
#    string = 'test\nbreak\"quoted\"'
#    interpreted = "test\nbreak\"quoted\""
#
#    @adapter.add(@@eyal, TEST::newline_quotes_string, string)
#    assert_equal string, @@eyal.newline_quotes_string.only
#
#    @adapter.add(@@eyal, TEST::newline_quotes_interpreted, interpreted)
#    assert_equal interpreted, @@eyal.newline_quotes_interpreted.only
#
#    string = 'ümlaut and \u00ebmlaut'
#    interpreted = "ümlaut and ëmlaut"
#
#    @adapter.add(@@eyal, TEST::umlaut_string, string)
#    assert_equal string, @@eyal.umlaut_string.only
#
#    @adapter.add(@@eyal, TEST::umlaut_interpreted, interpreted)
#    assert_equal string, @@eyal.umlaut_interpreted.only
#  end

  def test_retrieve_a_triple_with_only_uris
    @adapter.add(@@eyal, @@age, @@test)
    result = Query.new.distinct(:o).where(@@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@@eyal, @@age, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @@age, @@test).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@@eyal, :p, @@test).execute
    assert_equal 1, result.flatten.size
  end

  def test_retrieve_a_triple_with_string
    @adapter.add(@@eyal, @@mbox, @@mboxval)
    result = Query.new.distinct(:o).where(@@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@@eyal, @@mbox, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @@mbox, @@mboxval).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@@eyal, :p, @@mboxval).execute
    assert_equal 1, result.flatten.size
    #@adapter.close
  end
#
  def test_retrieve_a_triple_with_fixnum
    @adapter.add(@@eyal, @@age, @@ageval)

    result = Query.new.distinct(:o).where(@@eyal, :p, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p, :o).where(@@eyal, :p, :o).execute
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:o).where(@@eyal, @@age, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, @@age, @@ageval).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(@@eyal, :p, @@ageval).execute
    assert_equal 1, result.flatten.size
  end
end