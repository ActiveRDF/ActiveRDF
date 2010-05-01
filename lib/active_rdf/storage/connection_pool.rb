# Maintains pool of adapter instances that are connected to datasources. Returns
# right adapter for a given datasource, by either reusing an
# existing adapter-instance or creating new a adapter-instance.

module ActiveRDF
  class ConnectionPool
    class << self
      attr_accessor :write_adapter

      # sets automatic flushing of data from adapters to original datasources
      # (e.g. redland on-file database). If disabled, changes to an adapter are
      # not written back into the original source: you need to invoke
      # ConnectionPool.flush manually
      bool_accessor :auto_flush
    end
    # pool of all adapters
    @@adapter_pool = Array.new

    # pool of connection parameters to all adapter
    @@adapter_parameters = Array.new

    # currently active write-adapter (we can only write to one at a time)
    self.write_adapter = nil

    # default setting for auto_flush
    self.auto_flush = true

    # adapters-classes known to the pool, registered by the adapter-class
    # itself using register_adapter method, used to select new
    # adapter-instance for requested connection type
    @@registered_adapter_types = Hash.new

    # clears the pool: removes all registered data sources
    def ConnectionPool.clear
      ActiveRdfLogger::log_info "Clear called", self
      @@adapter_pool = []
      @@adapter_parameters = []
      self.write_adapter = nil
    end

    def ConnectionPool.adapters
      @@adapter_pool.dup
    end

    # flushes all openstanding changes into the original datasource.
    def ConnectionPool.flush
      write_adapter.flush
    end

    def ConnectionPool.adapter_types
      @@registered_adapter_types.keys
    end

    # returns the set of currently registered read-access datasources
    def ConnectionPool.read_adapters
      @@adapter_pool.select {|adapter| adapter.reads? && adapter.enabled?}
    end

    def ConnectionPool.write_adapters
      @@adapter_pool.select {|adapter| adapter.writes? && adapter.enabled?}
    end

    # returns adapter-instance for given parameters (either existing or new)
    def ConnectionPool.add_data_source(connection_params)
      ActiveRdfLogger::log_info(self) { "add_data_source with params: #{connection_params.inspect}" }

      # either get the adapter-instance from the pool
      # or create new one (and add it to the pool)
      index = @@adapter_parameters.index(connection_params)
      
      if connection_params[:new]
        # create a new connection when requested
        # these adapters are not cached
        connection = get_connection(connection_params)
      elsif index.nil?
        # connection not in the pool yet: create it,
        # register its connection parameters in parameters-array
        # and add it to the pool (at same index-position as parameters)
        connection = get_connection(connection_params)
        @@adapter_parameters << connection_params
        @@adapter_pool << connection
      else
        # if adapter parametrs registered already,
        # then adapter must be in the pool, at the same index-position as its parameters
        ActiveRdfLogger::log_debug("Reusing existing adapter")
        connection = @@adapter_pool[index]
      end

      # sets the adapter as current write-source if it can write
      ConnectionPool.write_adapter = connection if connection.writes?

      connection
    end

    # remove one adapter from activerdf
    def ConnectionPool.remove_data_source(adapter)
      ActiveRdfLogger.log_info(self) { "ConnectionPool: remove_data_source with params: #{adapter.to_s}" }

      index = @@adapter_pool.index(adapter)

      # remove_data_source mit be called repeatedly, e.g because the adapter object is stale
      unless index.nil?
        @@adapter_parameters.delete_at(index)
        @@adapter_pool.delete_at(index)
        if self.write_adapters.empty?
          self.write_adapter = nil
        else
          self.write_adapter = self.write_adapters.first
        end
      end

    end

    # closes and removes adapter from pool
    def ConnectionPool.close_data_source(adapter)
      remove_data_source(adapter)
      adapter.close
    end


    # sets adapter-instance for connection parameters (if you want to re-enable an existing adapter)
    def ConnectionPool.set_data_source(adapter, connection_params = {})
      # FIXME: remove in future version
      warn "Warning: ConnectionPool.set_data_source deprecated. Use add_data_source instead which will return the old connection given the connection_params"
      index = @@adapter_parameters.index(connection_params)
      if index.nil?
        @@adapter_parameters << connection_params
        @@adapter_pool << adapter
      else
        @@adapter_pool[index] = adapter
      end
      self.write_adapter = adapter if adapter.writes?
      adapter
    end

    # aliasing add_data_source as add
    # (code bit more complicad since they are class methods)
    class << self
      alias add add_data_source
      alias close close_data_source
    end

    # adapter-types can register themselves with connection pool by
    # indicating which adapter-type they are
    def ConnectionPool.register_adapter(type, klass)
      ActiveRdfLogger::log_info(self) { "Registering adapter of type #{type} for class #{klass}" }
      @@registered_adapter_types[type] = klass
    end

    # unregister adapter-type
    def ConnectionPool.unregister_adapter(type)
      ActiveRdfLogger::log_info(self) { "ConnectionPool: deregistering adapter of type #{type}" }
      @@registered_adapter_types.delete type
    end

    def ConnectionPool.load_adapter(name)
      name = name.to_s.strip.downcase.to_sym
      begin 
        case name
        when :rdflite
          require 'activerdf_rdflite/rdflite'
          require 'activerdf_rdflite/fetching'
          require 'activerdf_rdflite/suggesting'
        when :fetching
          require 'activerdf_rdflite/fetching'
        when :redland
          require 'activerdf_redland/redland'
        when :sparql
          require 'activerdf_sparql/sparql'
        when :jars
          require 'activerdf_yars/jars2'
        when :jena
          require 'activerdf_jena/jena'
        when :sesame
          require 'activerdf_sesame/sesame'
        else
          # raise error if adapter type unknown
          ActiveRdfLogger::log_error "Unknown adapter #{name}"
          raise ActiveRdfError, "Unknown adapter #{name}"
        end

        @@registered_adapter_types[name]
        
      rescue Exception => e
        ActiveRdfLogger::log_info "Could not load adapter #{name}: #{e}"
        raise ActiveRdfError, "Could not load adapter #{name}: #{e}"
      end
    end

    # create new adapter from connection parameters
    def ConnectionPool.get_connection(connection_params)
      ActiveRdfLogger::log_debug(self) { "Create a new adapter for parameters #{connection_params.inspect}" }

      name = connection_params[:type].to_s.strip.downcase.to_sym
      
      # return registered adapter class otherwise load requested adapter
      adapter = @@registered_adapter_types[name] || load_adapter(name)

      # create new adapter instance
      adapter.send(:new,connection_params)
    end    
    private_class_method :get_connection

  end
end