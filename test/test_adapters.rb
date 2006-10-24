# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

require 'test/unit'
require 'active_rdf'
require 'federation/federation_manager'
require 'queryengine/query'

class TestAdapter < Test::Unit::TestCase
	def setup
		ConnectionPool.clear

		begin
			# we try to use rdflite
			@adapter = ConnectionPool.add_data_source :type => :rdflite
		rescue ActiveRdfError
			begin
				@adapter = ConnectionPool.add_data_source :type => :redland
			rescue ActiveRdfError
				raise ActiveRdfError, "no suitable adapter found for running the tests in #{__FILE__}.\nPlease install rdflite or Redland and run these tests again, or ignore this message."
			end
		end
	end

	def teardown
	end

  def test_update_value
    # TODO: move to generic test suite: this test is not redland specific,
    # but currently redland is the only datasource to which we can write
    # but we should move this to a generic test suite, check whether we have a write_adapter,
    # and if so run this test
    ConnectionPool.add_data_source :type => :redland, :location => 'test/test-person'
    Namespace.register(:test, 'http://activerdf.org/test/')
    eyal = Namespace.lookup(:test, :eyal)

    assert_equal '27', eyal.age
    eyal.age = 30
    assert_equal
  end
end

