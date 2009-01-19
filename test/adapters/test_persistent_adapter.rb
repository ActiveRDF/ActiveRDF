require File.dirname(File.expand_path(__FILE__)) + '/test_writable_adapter'

module TestPersistentAdapter
  include TestWritableAdapter

  def test_close_and_reload_persistence
    @adapter.add(@@eyal, @@name, "eyal oren")
    @adapter.add(@@eyal, @@age, @@ageval)

    dump1 = @adapter.dump
    @adapter.close
    ConnectionPool.clear

    (args = @adapter_args.dup).delete(:new)  # remove possible new key to prevent reinitialization of datastore on adapter creation where applicable
    adapter2 = ConnectionPool.add(args)
    assert_not_equal @adapter.object_id, adapter2.object_id

    assert_equal dump1, adapter2.dump
    adapter2.close
  end
end