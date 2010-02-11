# Author:: Benjamin Heitmann
# Copyright:: (c) 2007
# License:: LGPL

require 'test/unit'
require 'rubygems'
require 'pp'

require "java"


$CLASSPATH << "/Users/benjamin/Development/activerdf/activerdf-sesame/ext/slf4j-jdk14-1.3.0.jar"
$CLASSPATH << "/Users/benjamin/Development/activerdf/activerdf-sesame/ext/wrapper-sesame2.jar"
$CLASSPATH << "/Users/benjamin/Development/activerdf/activerdf-sesame/ext/openrdf-sesame-2.0-beta5-onejar.jar"
$CLASSPATH << "/Users/benjamin/Development/activerdf/activerdf-sesame/ext/slf4j-api-1.3.0.jar"


# require 'active_rdf'


class TestSesameAdapter < Test::Unit::TestCase
  include ActiveRDF

  # TODO maybe put more stuff into setup and teardown...
  def setup
    #ConnectionPool.clear
  end

  def teardown
  end


  def test_registration
#    puts "registration test"
    adapter = ConnectionPool.add_data_source(:type => :sesame)
    assert_instance_of SesameAdapter, adapter
    adapter.close
  end

  def test_equality
#    puts "equality test"
    adapter1 = ConnectionPool.add_data_source(:type => :sesame, :name => :funky)
    adapter2 = ConnectionPool.add_data_source(:type => :sesame, :name => :groovy)
    assert_not_equal adapter1, adapter2
    adapter1.close
    adapter2.close
  end

  def test_add_and_retrieve_triple_with_just_uris
#    puts "uri retr test"
    adapter = ConnectionPool.add_data_source(:type => :sesame)

    eyal = RDFS::Resource.new 'http://eyaloren.org'
    age = RDFS::Resource.new 'foaf:age'
    test = RDFS::Resource.new 'test:test'

    adapter.add(eyal, age, test)
    # pp Query.new.select(:p, :o).where(eyal, :p, :o).execute
    result = Query.new.distinct(:o).where(eyal, :p, :o).execute
    # sesame does rdfs inferencing and writes into the store that eyal is a resource
    assert_equal 2, result.flatten.size

    result = Query.new.distinct(:p, :o).where(eyal, :p, :o).execute
    # sesame does rdfs inferencing and writes into the store that eyal is a resource
    assert_equal 4, result.flatten.size

    result = Query.new.distinct(:o).where(eyal, age, :o).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:s).where(:s, age, test).execute
    assert_equal 1, result.flatten.size

    result = Query.new.distinct(:p).where(eyal, :p, test).execute
    assert_equal 1, result.flatten.size

    adapter.close
  end

#  def test_add_and_retrieve_triple_with_an_object_string
##    puts "string retr test"
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = "23"
#
#    adapter.add(eyal, age, test)
#
#    result = Query.new.distinct(:o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 2, result.flatten.size
#
#    result = Query.new.distinct(:p, :o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 4, result.flatten.size
#
#    result = Query.new.distinct(:o).where(eyal, age, :o).execute
#    assert_equal 1, result.flatten.size
#
#    result = Query.new.distinct(:s).where(:s, age, test).execute
#    assert_equal 1, result.flatten.size
#
#    result = Query.new.distinct(:p).where(eyal, :p, test).execute
#    assert_equal 1, result.flatten.size
#
#    adapter.close
#  end
#
#  def test_add_and_retrieve_triple_with_an_object_fixnum
##    puts "fixnum retr test"
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#
#    result = Query.new.distinct(:o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 2, result.flatten.size
#
#    result = Query.new.distinct(:p, :o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 4, result.flatten.size
#
#    result = Query.new.distinct(:o).where(eyal, age, :o).execute
#    assert_equal 1, result.flatten.size
#
#    result = Query.new.distinct(:s).where(:s, age, test).execute
#    assert_equal 1, result.flatten.size
#
#    result = Query.new.distinct(:p).where(eyal, :p, test).execute
#    assert_equal 1, result.flatten.size
#
#    adapter.close
#  end
#
#  def test_dump
##    puts "dump test"
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#
#    stringDump = adapter.dump
#
#    assert_not_nil stringDump
#    assert_kind_of String, stringDump
#    adapter.close
#  end
#
#  def test_size
##    puts "site test"
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#
#    assert_equal 1, adapter.size
#    adapter.close
#  end
#
#  def test_clear
##    puts "clear test"
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#    assert_equal 1, adapter.size
#
#    # calling this reveals an unclosed iterator over statements. maybe this is a bug in sesame2, unclear...
#    # TODO: maybe check this. dont know if this has a high impact
#    adapter.clear
#    assert_equal 0, adapter.size
#    adapter.close
#  end
#
#  def test_load
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    this_dir = File.dirname(File.expand_path(__FILE__))
#
#    adapter.load(this_dir + "/eyal-foaf.nt")
#
#    assert_not_equal 0, adapter.size
#
#    # puts adapter.dump
#
#    adapter.close
#  end
#
#  def test_remove_basic
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#    assert_equal 1, adapter.size
#
#    adapter.delete(:s,:p,:o)
#    assert_equal 0, adapter.size
#
#    adapter.close
#  end
#
#  def test_remove_permutations
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#    assert_equal 1, adapter.size
#    adapter.delete(:s,:p,test)
#    assert_equal 0, adapter.size
#
#    adapter.add(eyal, age, test)
#    assert_equal 1, adapter.size
#    adapter.delete(:s,age,:o)
#    assert_equal 0, adapter.size
#
#    adapter.add(eyal, age, test)
#    assert_equal 1, adapter.size
#    adapter.delete(eyal,:p,:o)
#    assert_equal 0, adapter.size
#
#    adapter.close
#  end
#
#  def test_remove_different_objects
#    adapter = ConnectionPool.add_data_source(:type => :sesame)
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test_uri = RDFS::Resource.new 'test:test'
#    test_string = "maple cured ham"
#    test_fixnum = 42
#
#    adapter.add(eyal, age, test_uri)
#    adapter.add(eyal, age, test_string)
#    adapter.add(eyal, age, test_fixnum)
#    assert_equal 3, adapter.size
#    adapter.delete(:s,:p,test_uri)
#    assert_equal 2, adapter.size
#    adapter.delete(:s,:p,test_string)
#    assert_equal 1, adapter.size
#    adapter.delete(:s,:p,test_fixnum)
#    assert_equal 0, adapter.size
#
#    adapter.close
#  end
#
#  def test_initialization
#    adapter1 = ConnectionPool.add_data_source(:type => :sesame)
#    assert_instance_of SesameAdapter, adapter1
#    adapter1.close
#
#    adapter2 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => true)
#    assert_instance_of SesameAdapter, adapter2
#    adapter2.close
#
#    adapter3 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => false)
#    assert_instance_of SesameAdapter, adapter3
#    adapter3.close
#
#    adapter1 = ConnectionPool.add_data_source(:type => :sesame, :location => :memory)
#    assert_instance_of SesameAdapter, adapter1
#    adapter1.close
#
#    adapter2 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => true, :location => :memory)
#    assert_instance_of SesameAdapter, adapter2
#    adapter2.close
#
#    adapter3 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => false, :location => :memory)
#    assert_instance_of SesameAdapter, adapter3
#    adapter3.close
#  end
#
#  def test_persistence_basic
#    this_dir = File.dirname(File.expand_path(__FILE__))
#
#    adapter1 = ConnectionPool.add_data_source(:type => :sesame,
#      :location => this_dir + "/sesame-persistence.s2")
#    assert_instance_of SesameAdapter, adapter1
#    adapter1.close
#    File.delete(this_dir + "/sesame-persistence.s2")
#
#    adapter1 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => false,
#      :location => this_dir + "/sesame-persistence.s2")
#    assert_instance_of SesameAdapter, adapter1
#    adapter1.close
#    File.delete(this_dir + "/sesame-persistence.s2")
#
#    adapter2 = ConnectionPool.add_data_source(:type => :sesame, :inferencing => true,
#      :location => this_dir + "/sesame-persistence.s2")
#    assert_instance_of SesameAdapter, adapter2
#    adapter2.close
#    File.delete(this_dir + "/sesame-persistence.s2")
#  end
#
#  def test_persistence_reloading
#    this_dir = File.dirname(File.expand_path(__FILE__))
#    adapter = ConnectionPool.add_data_source(:type => :sesame,
#      :location => this_dir + "/sesame-persistence.s2")
#
#    eyal = RDFS::Resource.new 'http://eyaloren.org'
#    age = RDFS::Resource.new 'foaf:age'
#    test = 23
#
#    adapter.add(eyal, age, test)
#
#    result = Query.new.distinct(:o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 2, result.flatten.size
#
#    adapter.close
#    ConnectionPool.clear
#
#    adapter2 = ConnectionPool.add_data_source(:name => :second_one, :type => :sesame,
#      :location => this_dir + "/sesame-persistence.s2")
#
#    result = Query.new.distinct(:o).where(eyal, :p, :o).execute
#    # sesame does rdfs inferencing and writes into the store that eyal is a resource
#    assert_equal 2, result.flatten.size
#
#    adapter2.close
#    File.delete(this_dir + "/sesame-persistence.s2")
#  end

end
