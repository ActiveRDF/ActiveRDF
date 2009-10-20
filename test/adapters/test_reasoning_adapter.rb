module TestReasoningAdapter
  include ActiveRDF

  def test_subproperties
    if $activerdf_internal_reasoning
      @adapter.load(File.dirname(File.expand_path(__FILE__)) + '/../test_relations.nt')
      assert_equal Set[TEST::grandmother], Set.new(Query.new.distinct(:s).where(:s, TEST::ancestor, TEST::mother).reasoning(true).execute)
      assert_equal Set[TEST::mother,TEST::son], Set.new(Query.new.distinct(:s).where(:s, TEST::relative, TEST::daughter).reasoning(true).execute)
    end
  end
end