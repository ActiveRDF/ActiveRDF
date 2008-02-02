require 'federation/connection_pool'

# Manages the federation of datasources: distributes queries to right 
# datasources and merges their results

class FederationManager
  # add triple s,p,o (context is optional) to the currently selected write-adapter
  def FederationManager.add(s,p,o,c=nil)
    # TODO: allow addition of full graphs
    raise ActiveRdfError, "cannot write without a write-adapter" unless ConnectionPool.write_adapter
    ConnectionPool.write_adapter.add(s,p,o,c)
  end
  
  # delete triple s,p,o (context is optional) to the currently selected write-adapter
  def FederationManager.delete(s,p,o,c=nil)
    raise ActiveRdfError, "cannot write without a write-adapter" unless ConnectionPool.write_adapter
    ConnectionPool.write_adapter.delete(s,p,o,c)
  end
  
  # delete every triples about a specified resource
  def FederationManager.delete_all(resource)
    to_delete = Query.new.select(:p, :o).where(resource, :p, :o).execute
    to_delete.each{|p, o|
      delete(resource, p, o)
    }
  end
  
  # executes read-only queries
  # by distributing query over complete read-pool
  # and aggregating the results
  def FederationManager.query(q, options={:flatten => true, :result_format => nil})
    if (q.class != String)
      $activerdflog.debug "querying #{q.to_sp}"
    else
      $activerdflog.debug "querying #{q}"
    end
    if ConnectionPool.read_adapters.empty?
      raise ActiveRdfError, "cannot execute query without data sources" 
    end
    
    # ask each adapter for query results
    # and yield them consequtively
    if block_given?
      ConnectionPool.read_adapters.each do |source|
        source.query(q) do |*clauses|
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
        if (q.class != String)
          source_results = source.query(q)
        else
          source_results = source.get_sparql_query_results(q, options[:result_format])
        end
        source_results.each do |clauses|
          results << clauses
        end
      end
      
      # filter the empty results
      results.reject {|ary| ary.empty? }
      
      # remove duplicate results from multiple
      # adapters if asked for distinct query
      # (adapters return only distinct results,
      # but they cannot check duplicates against each other)
      results.uniq! if ((q.class != String) && (q.distinct?))
      
      # flatten results array if only one select clause
      # to prevent unnecessarily nested array [[eyal],[renaud],...]
      if (q.class != String)
        results.flatten! if (q.select_clauses.size == 1 or q.ask?)
      else
        results.flatten! if q.scan(/[?]/).length == 2
      end
      
      # remove array (return single value or nil) if asked to
      if options[:flatten] or ((q.class != String)  && (q.count?))
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
