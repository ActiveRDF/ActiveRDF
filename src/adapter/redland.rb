# (read-only) adapter to Redland databse
# uses SPARQL for querying
require 'federation/connection_pool'
require 'queryengine/query2sparql'
require 'rdf/redland'

class RedlandAdapter
  ConnectionPool.register_adapter(:redland,self)

  # instantiate connection to Redland database
  def initialize(params = {})

    if params[:location] and params[:location] != :memory
      # setup file locations for redland database
      path, file = File.split(params[:location])
      type = 'bdb'
    else
      # fall back to in-memory redland
      type = 'memory'; path = '';	file = '.'
    end

    @store = Redland::HashStore.new(type, file, path, false)
    @model = Redland::Model.new @store
  end

  # yields query results (as many as requested in select clauses) executed on data source
  def query(query)
    qs = Query2SPARQL.translate(query)
    clauses = query.select_clauses.size
    redland_query = Redland::Query.new(qs, 'sparql')
    query_results = @model.query_execute(redland_query)

    # verify if the query has failed
    return false if query_results.nil?
    return false unless query_results.is_bindings?

    # convert the result to array
    results = query_result_to_array(query_results)

    if block_given?
      results.each do |clauses|
        yield(*clauses)
      end
    else
      results
    end
  end

  # add triple to datamodel
  def add(s, p, o)
    # verify input
    return false if s.nil? or p.nil? or o.nil?
    return false if !s.kind_of?(RDFS::Resource) or !p.kind_of?(RDFS::Resource)

    begin
      @model.add(wrap(s), wrap(p), wrap(o))
    rescue Redland::RedlandError => e
      return false
    end
  end

  def reads?
    true
  end

  def writes?
    true
  end

  ################ helper methods ####################
  def query_result_to_array(query_results)
    results = []
    number_bindings = query_results.binding_names.size

    # walk through query results, and construct results array
    # by looking up each result (if it is a resource) and adding it to the result-array
    # for literals we only add the values

    # redland results are set that needs to be iterated
    while not query_results.finished?
      # we collect the bindings in each row and add them to results
      results << (0..number_bindings-1).collect do |i|
        # node is the query result for one binding
        node = query_results.binding_value(i)

        # we determine the node type
        if node.literal?
          # for literal nodes we just return the value
          node.to_s
        elsif node.blank?
          # blank nodes we ignore
          nil
        else
          # other nodes are rdfs:resources
          RDFS::Resource.new(node.uri.to_s)
        end
      end
      # iterate through result set
      query_results.next
    end
    results
  end

  def wrap node
    case node
    when RDFS::Resource
      Redland::Uri.new(node.uri)
    else
      Redland::Literal.new(node)
    end
  end
end
