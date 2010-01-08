# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL
# require 'active_rdf'
require 'federation/connection_pool'
require 'queryengine/query2sparql'
require 'rdf/redland'

# Adapter to Redland database
# uses SPARQL for querying
class RedlandAdapter < ActiveRdfAdapter
  ActiveRdfLogger::log_info "Loading Redland adapter", self
  ConnectionPool.register_adapter(:redland,self)

  # instantiate connection to Redland database
  # * location: Data location (:memory, :mysql, :postgresql)
  # * database: Database name
  # * new: Create new database
  # * host: Database server address
  # * password: Password
  # * port: Database server port
  # * reconnect: Set automatic reconnect to database server
  # * user: Username
  def initialize(params = {})
    super()

    if params[:location] and params[:location] == :postgresql
      initialize_postgresql(params)
      return
    end

    if params[:location] and params[:location] != :memory
      # setup file defaults for redland database
      type = 'bdb'
      want_new = false    # create new or use existing store
      write = true
      contexts = true

      if params[:want_new] == true
        want_new = true
      end
      if params[:write] == false
        write = false
      end
      if params[:contexts] == false
        contexts = false
      end

      if params[:location].include?('/')
        path, file = File.split(params[:location])
      else
        path = '.'
        file = params[:location]
      end
    else
      # fall back to in-memory redland 	
      type = 'memory'; path = '';	file = '.'; want_new = false; write = true; contexts = true
    end

    ActiveRdfLogger::log_info(self) { "Initializing with type: #{type} file: #{file} path: #{path}" }

    begin
      @store = Redland::HashStore.new(type, file, path, want_new, write, contexts)
      @model = Redland::Model.new @store
      @reads = true
      @writes = true
      ActiveRdfLogger.log_info(self) { "Initialised Redland adapter to #{@model.inspect}" }

    rescue Redland::RedlandError => e
      raise ActiveRdfError, "Could not initialise Redland database: #{e.message}"
    end
  end	

  # instantiate connection to Redland database in Postgres or MySQL
  # * database: Database name
  # * new: Create new database
  # * host: Database server address
  # * password: Password
  # * port: Database server port
  # * reconnect: Set automatic reconnect to database server
  # * user: Username
  def initialize_postgresql(params = {})
    # author: Richard Dale
    type = 'postgresql'
    name = params[:name]

    options = []
    options << "new='#{params[:new]}'" if params[:new]
    options << "bulk='#{params[:bulk]}'" if params[:bulk]
    options << "merge='#{params[:merge]}'" if params[:merge]
    options << "host='#{params[:host]}'" if params[:host]
    options << "database='#{params[:database]}'" if params[:database]
    options << "user='#{params[:user]}'" if params[:user]
    options << "password='#{params[:password]}'" if params[:password]
    options << "port='#{params[:port]}'" if params[:port]


    ActiveRdfLogger::log_info "Initializing with type: #{type} name: #{name} options: #{options.join(',')}", self

    begin
      @store = Redland::TripleStore.new(type, name, options.join(','))
      @model = Redland::Model.new @store
      @reads = true
      @writes = true
    rescue Redland::RedlandError => e
      raise ActiveRdfError, "Could not initialise Redland database: #{e.message}"
    end
  end	

  # load a file from the given location with the given syntax into the model.
  # use Redland syntax strings, e.g. "ntriples" or "rdfxml", defaults to "ntriples"
  # * location: location of file to load.
  # * syntax: syntax of file
  def load(location, syntax="ntriples")
    parser = Redland::Parser.new(syntax, "", nil)
    if location =~ /^http/
      raise ActiveRdfError, "Redland load error for #{location}" unless (parser.parse_into_model(@model, location) == 0)
    else
      raise ActiveRdfError, "Redland load error for #{location}" unless (parser.parse_into_model(@model, "file:#{location}") == 0)
    end
  end

  # yields query results (as many as requested in select clauses) executed on data source
  def query(query)
    qs = Query2SPARQL.translate(query)
    ActiveRdfLogger::log_debug(self) { "Executing SPARQL query #{qs}" }

    clauses = query.select_clauses.size
    redland_query = Redland::Query.new(qs, 'sparql')
    query_results = @model.query_execute(redland_query)

    # return Redland's answer without parsing if ASK query
    return [[query_results.get_boolean?]] if query.ask?

    ActiveRdfLogger::log_debug(self) { "Found #{query_results.size} query results" }

    # verify if the query has failed
    if query_results.nil?
      ActiveRdfLogger::log_debug "Query has failed with nil result", self
      return false
    end

    if not query_results.is_bindings?
      ActiveRdfLogger::log_debug "Query has failed without bindings", self
      return false
    end

    # convert the result to array
    #TODO: if block is given we should not parse all results into array first
    results = query_result_to_array(query_results, false, query.resource_class) 

    if block_given?
      results.each do |clauses|
        yield(*clauses)
      end
    else
      results
    end
  end

  # executes query and returns results as SPARQL JSON or XML results
  # requires svn version of redland-ruby bindings
  # * query: ActiveRDF Query object
  # * result_format: :json or :xml
  def get_query_results(query, result_format=nil)
    get_sparql_query_results(Query2SPARQL.translate(query), result_format, query.resource_class)
  end

  # executes sparql query and returns results as SPARQL JSON or XML results
  # * query: sparql query string
  # * result_format: :json or :xml
  # * result_type: Is the type that is used for "resource" results
  def get_sparql_query_results(qs, result_type, result_format=nil)
    # author: Eric Hanson

    # set uri for result formatting
    result_uri = 
    case result_format
    when :json
      Redland::Uri.new('http://www.w3.org/2001/sw/DataAccess/json-sparql/')
    when :xml
      Redland::Uri.new('http://www.w3.org/TR/2004/WD-rdf-sparql-XMLres-20041221/')
    end

    # query redland
    redland_query = Redland::Query.new(qs, 'sparql')
    query_results = @model.query_execute(redland_query)

    if (result_format != :array)
      # get string representation in requested result_format (json or xml)
      query_results.to_string()
    else
      # get array result
      query_result_to_array(query_results, true, result_type) 
    end
  end

  # add triple to datamodel
  # * s: subject
  # * p: predicate
  # * o: object
  def add(s, p, o, c=nil)
    result = false
    ActiveRdfLogger::log_debug(self) { "Adding triple #{s} #{p} #{o}" }

    # verify input
    if s.nil? || p.nil? || o.nil?
      ActiveRdfLogger::log_debug "Cannot add triple with empty subject, exiting", self
      return false
    end 

    unless (((s.class == String) && (p.class == String) && (o.class == String)) && 
      ((s[0..0] == '<') && (s[-1..-1] == '>')) && 
      ((p[0..0] == '<') && (p[-1..-1] == '>'))) || (s.respond_to?(:uri) && p.respond_to?(:uri))
      ActiveRdfLogger::log_debug "Cannot add triple where s/p are not resources, exiting", self
      return false
    end

    begin
      if ((s.class != String) || (p.class != String) || (o.class != String))
        result = (@model.add(wrap(s), wrap(p), wrap(o)) == 0)
      else
        result = (@model.add(wrapString(s), wrapString(p), wrapString(o)) == 0)
      end
      if (result == true)
        result = save if ConnectionPool.auto_flush?
      end
      return result
    rescue Redland::RedlandError => e
      ActiveRdfLogger::log_warn "Adding triple failed in Redland library: #{e}", self
      return false
    end		
  end

  # deletes triple(s,p,o) from datastore
  # nil parameters match anything: delete(nil,nil,nil) will delete all triples
  # * s: subject
  # * p: predicate
  # * o: object
  def delete(s,p,o,c=nil)
    if ((s.class != String) && (p.class != String) && (o.class != String))
      s = wrap(s) unless s.nil?
      p = wrap(p) unless p.nil?
      o = wrap(o) unless o.nil?

      # if any parameter is nil we need to iterate over all matching triples
      if (s.nil? or p.nil? or o.nil?)
        @model.find(s,p,o) { |s,p,o| @model.delete(s,p,o) }
      else
        @model.delete(s,p,o)
      end
    end

    @model.delete(s,p,o) == 0
  end

  # saves updates to the model into the redland file location
  def save
    Redland::librdf_model_sync(@model.model) == 0
  end
  alias flush save

  # returns all triples in the datastore
  # * type: dump syntax
  def dump(type = 'ntriples')
    Redland.librdf_model_to_string(@model.model, nil, type)
  end

  # returns size of datasources as number of triples
  # warning: expensive method as it iterates through all statements
  def size
    # we cannot use @model.size, because redland does not allow counting of 
    # file-based models (@model.size raises an error if used on a file)
    # instead, we just dump all triples, and count them
    @model.triples.size
  end

  # clear all real triples of adapter
  def clear
    @model.find(nil, nil, nil) {|s,p,o| @model.delete(s,p,o)}
  end

  # close adapter and remove it from the ConnectionPool
  def close
    ConnectionPool.remove_data_source(self)
  end

  private
  ################ helper methods ####################
  #TODO: if block is given we should not parse all results into array first
  # result_type is the type that should be used for "resource" properties.
  def query_result_to_array(query_results, to_string, result_type)
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
          Redland.librdf_node_get_literal_value(node.node)
        elsif node.blank?
          # blank nodes we ignore
          if to_string == false
            nil
          else
            # check blank node id
            if node.blank_identifier
              "_:#{node.blank_identifier}"
            else
              "_:"
            end
          end
        else
          # other nodes are rdfs:resources
          if to_string == false
            result_type.new(node.uri.to_s)
          else
            "<#{node.uri.to_s}>"
          end
        end
      end
      # iterate through result set
      query_results.next
    end

    results
  end	 	

  def wrap node
    if(node.respond_to?(:uri))
      Redland::Uri.new(node.uri.to_s)
    else
      Redland::Literal.new(node.to_s)
    end
  end

  def wrapString node
    node = node.to_s
    if ((node[0..0] == '<') && (node[-1..-1] == '>')) 
      return Redland::Uri.new(node[1..-2]) 
    elsif (node[0..1] == '_:') 
      if (node.length > 2) 
        return Redland::BNode.new(node[2..-1]) 
      else 
        return Redland::BNode.new 
      end
    else
      return Redland::Literal.new(node) 
    end 
  end

end