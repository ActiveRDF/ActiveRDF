# Maintains pool of adapter instances that are connected to datasources
# returns right adapter for a given datasource, by either reusing
# existing adapter-instance or creating new adapter-instance
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL

class ConnectionPool
  # pool of all adapters
  @@adapter_pool = Array.new

  # pool of connection parameters to all adapter
  @@adapter_parameters = Array.new

  # currently active write-adapter (we can only write to one at a time)
  @@write_adapter = nil

	@@auto_flush = true

  # adapters-classes known to the pool, registered by the adapter-class
  # itself using register_adapter method, used to select new
  # adapter-instance for requested connection type
  @@registered_adapter_types = Hash.new

  # clears the pool: removes all registered data sources
  def ConnectionPool.clear
    $log.info "ConnectionPool: clear called"
    @@adapter_pool = []
    @@adapter_parameters = []
    @@write_adapter = nil
  end

	# enable/disable automatic flushing
	# if enabled (default) all changes to a datasource adapter are flushed to the 
	# original source immediately (e.g. changes are written to the filesystem)
	#
	# if disabled, changes to an adapter are not written back into the original 
	# source: you need to invoke ConnectionPool.flush manually
	def ConnectionPool.auto_flush=(flag)
		@@auto_flush = flag
	end

	def ConnectionPool.auto_flush
		@@auto_flush
	end

	# flushes all openstanding changes into the original datasource (e.g. to the 
	# filesystem).
	def ConnectionPool.flush
		@@write_adapter.flush
	end

  # returns the set of currently registered read-access datasources
  def ConnectionPool.read_adapters
    @@adapter_pool.select {|adapter| adapter.reads? }
  end

  # returns the currently selected data source for write-access
  def ConnectionPool.write_adapter
    @@write_adapter
  end

  # sets the given adapter as currently selected writeable adapter
  # (sets currently selected writer to nil if given adapter does not support writing)
  def ConnectionPool.write_adapter= adapter
    $log.info "ConnectionPool: setting write adapter to #{adapter.type}"
    @@write_adapter = adapter.writes? ? adapter : nil
  end

  # returns adapter-instance for given parameters (either existing or new)
  def ConnectionPool.add_data_source(connection_params)
    $log.info "ConnectionPool: add_data_source with params: #{connection_params.inspect}"

    # either get the adapter-instance from the pool
    # or create new one (and add it to the pool)
    index = @@adapter_parameters.index(connection_params)
    if index.nil?
      # adapter not in the pool yet: create it,
      # register its connection parameters in parameters-array
      # and add it to the pool (at same index-position as parameters)
      $log.debug("Create a new adapter for parameters #{connection_params.inspect}")
      adapter = create_adapter(connection_params)
      @@adapter_parameters << connection_params
      @@adapter_pool << adapter
    else
      # if adapter parametrs registered already,
      # then adapter must be in the pool, at the same index-position as its parameters
      $log.debug("Reusing existing adapter")
      adapter = @@adapter_pool[index]
    end

    # sets the adapter as current write-source if it can write
    @@write_adapter = adapter if adapter.writes?

    return adapter
  end

  # adapter-types can register themselves with connection pool by
  # indicating which adapter-type they are
  def ConnectionPool.register_adapter(type, klass)
    $log.info "ConnectionPool: registering adapter of type #{type} for class #{klass}"
    @@registered_adapter_types[type] = klass
  end

  private
  # create new adapter from connection parameters
  def ConnectionPool.create_adapter connection_params
    # lookup registered adapter klass
    klass = @@registered_adapter_types[connection_params[:type]]

    # raise error if adapter type unknown
    raise(ActiveRdfError, "unknown adapter type #{connection_params[:type]}") if klass.nil?

    # create new adapter-instance
    klass.send(:new,connection_params)
  end
end
