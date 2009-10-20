require 'federation/connection_pool'

# Manages the federation of datasources: distributes queries to right
# datasources and merges their results

module ActiveRDF
  class FederationManager
    def FederationManager.contexts
      ConnectionPool.adapters.collect{|adapter| adapter.contexts if adapter.respond_to?(:contexts)}.flatten.compact
    end

    # add triple s,p,o to the currently selected write-adapter
    def FederationManager.add(s,p,o)
      # TODO: allow addition of full graphs
      raise ActiveRdfError, "cannot write without a write-adapter" unless ConnectionPool.write_adapter
      ConnectionPool.write_adapter.add(s,p,o)
    end

    # delete triple s,p,o from the currently selected write adapter (s and p are
    # mandatory, o is optional, nil arguments and all symbols are interpreted as wildcards)
    def FederationManager.delete(s,p,o=:all)
      raise ActiveRdfError, "cannot write without a write-adapter" unless ConnectionPool.write_adapter

      # transform wildcard symbols to nil (for the adaptors)
      s = nil if s.is_a? Symbol
      p = nil if p.is_a? Symbol
      o = nil if o.is_a? Symbol

      ConnectionPool.write_adapter.delete(s,p,o)
    end

    # executes read-only queries
    # by distributing query over complete read-pool
    # and aggregating the results
    def FederationManager.execute(q, options={:flatten => false})
      if ConnectionPool.read_adapters.empty?
        raise ActiveRdfError, "cannot execute query without data sources"
      end

      # ask each adapter for query results
      # and yield them consequtively
      if block_given?
        ConnectionPool.read_adapters.each do |source|
          source.execute(q) do |*clauses|
            yield(*clauses)
          end
        end
      else
        # build Array of results from all sources
        # TODO: write test for sebastian's select problem
        # (without distinct, should get duplicates, they
        # were filtered out when doing results.union)
        results = []
        ConnectionPool.read_adapters.each do |source|
          source_results = source.execute(q)
          source_results.each do |clauses|
            results << clauses
          end
        end

        # count
        return results.flatten.inject{|mem,c| mem + c} if q.count?

        # filter the empty results
        results.reject {|ary| ary.empty? }

        # remove duplicate results from multiple
        # adapters if asked for distinct query
        # (adapters return only distinct results,
        # but they cannot check duplicates against each other)
        results.uniq! if q.distinct?

        # flatten results array if only one select clause
        # to prevent unnecessarily nested array [[eyal],[renaud],...]
        results.flatten! if q.select_clauses.size == 1 or q.ask?

        # remove array (return single value or nil) if asked to
        if options[:flatten]
          case results.size
          when 0
            results = nil
          when 1
            results = results.first
          end
        end
      end

      results
    end
  end
end