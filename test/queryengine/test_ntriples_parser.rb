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

    assert_equal RDFS::Resource, results[0][0].class
    assert_equal String, results[0][2].class
  end

  # make sure that encoded content (as in RSS feeds) which contains a lot of <something> is not 
  # interpreted as just a single URL, bit is instead interpreted as a string 
  def test_parsing_of_encoded_content
    str = <<EOF
  <http://b4mad.net/datenbrei/archives/2004/07/15/brainstream-his-own-foafing-in-wordpress/#comment-10> <http://purl.o
rg/rss/1.0/modules/content/encoded> "<p>Heh - excellent. Are we leaving Morten in the dust? :) I know he had some bu
gs to fix in his version.</p>\n<p>Also, I think we should really add the foaf: in front of the foaf properties to ma
ke it easier to read. </p>\n<p>Other hack ideas:</p>\n<p>* Birthdate in month/date/year (seperate fields) to add bio
:Event/ bio:Birth and then say who can see the birth year, birth day/mo and full birth date.<br />\n* Add trust leve
ls to friends<br />\n* Storing ones PGP key/key fingerprint in Wordpress and referencing it as user_pubkey/user_pubk
eyprint respectively<br />\n* Add gender, depiction picture for profile, myers-brigs, astrological sign fields to Pr
ofile.<br />\n* Add the option to create Projects/Groups user is involved with re: their Profile.<br />\n* Maybe add
 phone numbers/address/geo location? Essentially make it a VCard that can be foafified.\n</p>\n" .
EOF

    results = NTriplesParser.parse(str)
    assert_equal 1, results.size
 
    assert_equal String, results[0][2].class
    # and now do something to check if e.g. the string "PGP" is contained in results[0][2]
    assert_true results[0][2] =~ "PGP" # or something like this

  end
  
end
