require File.dirname(File.expand_path(__FILE__)) + '/test_activerdf_adapter'

module TestReadOnlyAdapter
  include TestActiveRdfAdapter

  def test_refuse_to_write
    # NameError gets thown if the method is unknown
    assert_raises NoMethodError do
      @adapter.add
    end
    assert_raises NoMethodError do
      @adapter.load
    end
  end
end