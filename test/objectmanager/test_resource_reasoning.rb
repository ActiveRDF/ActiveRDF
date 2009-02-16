require 'active_rdf'
if $activerdf_internal_reasoning
  require 'test/unit'
  require 'set'
  require "#{File.dirname(__FILE__)}/../common"

  class TestResourceReasoning < Test::Unit::TestCase
    include SetupAdapter

    def setup
      super
      test_dir = "#{File.dirname(__FILE__)}/.."
      @adapter.load "#{test_dir}/rdf.nt"
      @adapter.load "#{test_dir}/rdfs.nt"
      @adapter.load "#{test_dir}/test_person_data.nt"
      @adapter.load "#{test_dir}/test_relations.nt"
    end

    def test_person
      assert_equal Set[TEST::age, TEST::car, TEST::eye, TEST::ancestor, TEST::child, TEST::parent, TEST::relative, TEST::sibling] | RDFS::Resource.predicates,
                   Set.new(TEST::Person.predicates)
    end

    # TODO: add more tests
  end
end