module TestNetworkAwareAdapter
  def test_parse_foaf
    @adapter.load("http://eyaloren.org/foaf.rdf#me", 'rdfxml')
    assert @adapter.size > 0
  end

  def test_sioc_schema
    @adapter.load("http://rdfs.org/sioc/ns#", 'rdfxml')
    # sioc contains 545 triples but with two duplicates (SIOC::has_moderator.type & SIOC::related_to.type)
    assert_equal 543, @adapter.size
  end

  def test_foaf_schema
    @adapter.load("http://xmlns.com/foaf/spec/index.rdf", 'rdfxml')
    # foaf contains 573 triples but with two duplicates (FOAF::family_name.domain & FOAF::Agent.type)
    assert_equal 571, @adapter.size
  end

  def test_remote_load_and_clear
    @adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/ntriples/test.nt', 'ntriples')
    assert_equal 30, @adapter.size

    @adapter.clear
    assert_equal 0, @adapter.size

    @adapter.load('http://www.w3.org/2000/10/rdf-tests/rdfcore/testSchema.rdf', 'rdfxml')
    assert_equal 76, @adapter.size
  end
end