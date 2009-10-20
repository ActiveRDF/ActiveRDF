# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'queryengine/ntriples_parser'
require "#{File.dirname(__FILE__)}/../common"

class TestNTriplesParser < Test::Unit::TestCase
  include ActiveRDF

  def setup
  end

  def teardown
  end

  def test_simple_triples
    str = <<EOF
<http://www.johnbreslin.com/blog/author/cloud/#foaf> <http://xmlns.com/foaf/0.1/surname> "Breslin" .
<http://www.johnbreslin.com/blog/author/cloud/#foaf> <http://xmlns.com/foaf/0.1/firstName> "John" .
<http://www.johnbreslin.com/blog/author/cloud/> <http://purl.org/dc/terms/created> "1999-11-30T00:00:00" .
EOF

    triples = NTriplesParser.parse(str)
    assert_equal 9, triples.flatten.size
    assert_equal 3, triples[0].size

    assert_equal RDFS::Resource.new('http://www.johnbreslin.com/blog/author/cloud/#foaf'), triples[0][0]
    assert_equal RDFS::Resource.new('http://xmlns.com/foaf/0.1/surname'), triples[0][1]
    assert_equal 'Breslin', triples[0][2]
  end

  def test_encoded_content
    str = <<'EOF'
  <http://b4mad.net/datenbrei/archives/2004/07/15/brainstream-his-own-foafing-in-wordpress/#comment-10> <http://purl.org/rss/1.0/modules/content/encoded> "<p>Heh - excellent. Are we leaving Morten in the dust? :) I know he had some bu gs to fix in his version.</p>\n<p>Also, I think we should really add the foaf: in front of the foaf properties to ma ke it easier to read. </p>\n<p>Other hack ideas:</p>\n<p>* Birthdate in month/date/year (seperate fields) to add bio :Event/ bio:Birth and then say who can see the birth year, birth day/mo and full birth date.<br />\n* Add trust leve ls to friends<br />\n* Storing ones PGP key/key fingerprint in Wordpress and referencing it as user_pubkey/user_pubk eyprint respectively<br />\n* Add gender, depiction picture for profile, myers-brigs, astrological sign fields to Pr ofile.<br />\n* Add the option to create Projects/Groups user is involved with re: their Profile.<br />\n* Maybe add phone numbers/address/geo location? Essentially make it a VCard that can be foafified.\n</p>\n" .
EOF
    literal = '<p>Heh - excellent. Are we leaving Morten in the dust? :) I know he had some bu gs to fix in his version.</p>\n<p>Also, I think we should really add the foaf: in front of the foaf properties to ma ke it easier to read. </p>\n<p>Other hack ideas:</p>\n<p>* Birthdate in month/date/year (seperate fields) to add bio :Event/ bio:Birth and then say who can see the birth year, birth day/mo and full birth date.<br />\n* Add trust leve ls to friends<br />\n* Storing ones PGP key/key fingerprint in Wordpress and referencing it as user_pubkey/user_pubk eyprint respectively<br />\n* Add gender, depiction picture for profile, myers-brigs, astrological sign fields to Pr ofile.<br />\n* Add the option to create Projects/Groups user is involved with re: their Profile.<br />\n* Maybe add phone numbers/address/geo location? Essentially make it a VCard that can be foafified.\n</p>\n'

    triples = NTriplesParser.parse(str)
    assert_equal 1, triples.size

    encoded_content = triples.first[2]
    assert_equal literal, encoded_content
    assert_equal String, encoded_content.class
    assert encoded_content.include?('PGP')
  end

  def test_escaped_quotes
    string = '<subject> <predicate> "test string with \n breaks and \" escaped quotes" .'
    literal = 'test string with \n breaks and \" escaped quotes'
    triples = NTriplesParser.parse(string)

    assert_equal 1, triples.size
    assert_equal literal, triples.first[2]
  end

  def test_datatypes
    string =<<EOF
<s> <p> "blue" .
<s> <p> "29"^^<http://www.w3.org/2001/XMLSchema#integer> .
<s> <p> "false"^^<http://www.w3.org/2001/XMLSchema#boolean> .
<s> <p> "2002-10-10T00:00:00+13"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
EOF
    triples = NTriplesParser.parse(string)
    assert_equal 4, triples.size
    assert_equal 'blue', triples[0][2]
    assert_equal 29, triples[1][2]
    assert_equal triples[2][2], false
    assert_equal triples[3][2], DateTime.parse('2002-10-10T00:00:00+13')
  end
end
