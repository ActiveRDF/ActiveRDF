# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL
require 'active_rdf'
require 'federation/connection_pool'
require 'queryengine/query2sparql'
require 'rdf/redland'

# Adapter to Redland database
# uses SPARQL for querying
module ActiveRDF
  class RedlandAdapter < ActiveRdfAdapter
    $activerdflog.info "RedlandAdapter: loading Redland adapter"
    ConnectionPool.register_adapter(:redland,self)

    # instantiate connection to Redland database
    def initialize(params = {})
      super
      location = params[:location]
      name = params[:name] || ''
      options = {}
      options[:write],options[:new],options[:contexts] = [@writes,@new,@contexts].collect{|bool| bool ? 'yes' : 'no'}

      # supported storage modules: mysql, postgresql, sqlite, hashes(as 'memory' or 'bdb')
      # unsupported storage modules: uri, file, memory, tstore, trees
      # see http://librdf.org/docs/api/redland-storage-modules.html
      case location
        when 'postgresql','mysql','sqlite'
          store_type = location
          if location == 'postgresql' or location == 'mysql'
            [:host, :port, :database, :user, :password].each{|k| options[k] = params[k] if params[k]}
            options[:host] ||= 'localhost'
          end
        when 'memory',nil
          # use storage module hashes with hash-type 'memory' instead of non-indexing storage module memory
          store_type = 'hashes'
          options[:hash_type] = 'memory';
          options.delete(:new)  # not used with this hash-type
        else
          # use storage module hashes with hash-type 'bdb' instead of non-indexing storage module file
          store_type = 'hashes'
          options[:hash_type] = 'bdb'

          if location.include?('/')
            options[:dir], name = File.split(location)
          else
            options[:dir] = '.'
            name = location
          end
      end

      hash_type = options.delete(:hash_type)
      options = options.collect{|k,v| "#{k}='#{v}'"}.join(',')
      options << "hash-type='#{hash_type}'" if hash_type   # convert option key from hash_type to hash-type. :hash-type is an invalid symbol
      @model = Redland::Model.new Redland::TripleStore.new(store_type, name, options)
      @options = options
      $activerdflog.info "RedlandAdapter: initialized adapter with type=\'#{store_type}\', name=\'#{name}\' options: #{options} => #{@model.inspect}"

      rescue Redland::RedlandError => e
        raise ActiveRdfError, "RedlandAdapter: could not initialise Redland database: #{e.message}\nstore_type=\'#{store_type}\', name=\'#{name}\' options: #{options}"
    end

    # load a file from the given location with the given syntax into the model.
    # use Redland syntax strings, e.g. "ntriples" or "rdfxml", defaults to "ntriples"
    def load(location, syntax="ntriples")
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      parser = Redland::Parser.new(syntax, "", nil)
      unless location =~ /^http/
        location = "file:#{location}"
      end

      context = @contexts ? Redland::Uri.new(location) : nil
      parser.parse_into_model(@model, location, nil, context)

      save if ConnectionPool.auto_flush?
      rescue Redland::RedlandError => e
        $activerdflog.warn "RedlandAdapter: loading #{location} failed in Redland library: #{e}"
        return false
    end

    # yields query results (as many as requested in select clauses) executed on data source
    def execute(query, &block)
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      qs = Query2SPARQL.translate(query)
      $activerdflog.debug "RedlandAdapter: executing SPARQL query #{qs}"

      redland_query = Redland::Query.new(qs, 'sparql')
      query_results = @model.query_execute(redland_query)

      # return Redland's answer without parsing if ASK query
      return [[query_results.get_boolean?]] if query.ask?

      # $activerdflog.debug "RedlandAdapter: found #{query_results.size} query results"

      # verify if the query has failed
      if query_results.nil?
        $activerdflog.debug "RedlandAdapter: query has failed with nil result"
        return false
      end
      if not query_results.is_bindings?
        $activerdflog.debug "RedlandAdapter: query has failed without bindings"
        return false
      end

      if query.count?
        while not query_results.finished?
          query_results.next
        end
        [[query_results.count]]
      else
        # convert the results to array
        query_result_to_array(query_results, &block)
      end
    end

    # executes query and returns results as SPARQL JSON or XML results
    # requires svn version of redland-ruby bindings
    # * query: ActiveRDF Query object
    # * result_format: :json or :xml
    def get_query_results(query, result_format=nil)
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      get_sparql_query_results(Query2SPARQL.translate(query), result_format)
    end

    # executes sparql query and returns results as SPARQL JSON or XML results
    # * query: sparql query string
    # * result_format: :json or :xml
    def get_sparql_query_results(qs, result_format=nil)
      # author: Eric Hanson
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled

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

      # get string representation in requested result_format (json or xml)
      query_results.to_string(result_uri)
    end

    # add triple to datamodel
    def add(s,p,o,c=nil)
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      $activerdflog.warn "RedlandAdapter: adapter does not support contexts" if (!@contexts and !c.nil?)
      #$activerdflog.debug "RedlandAdapter: adding triple #{s} #{p} #{o} #{c}"

      # verify input
      if s.nil? || p.nil? || o.nil?
        $activerdflog.debug "RedlandAdapter: cannot add triple with empty element, exiting"
        return false
      end

      unless s.respond_to?(:uri) && p.respond_to?(:uri)
        $activerdflog.debug "RedlandAdapter: cannot add triple where s/p are not resources, exiting"
        return false
      end
      quad = [s,p,o,c].collect{|e| to_redland(e)}

      @model.add(*quad)
      save if ConnectionPool.auto_flush?
      rescue Redland::RedlandError => e
        $activerdflog.warn "RedlandAdapter: adding triple(#{quad}) failed in Redland library: #{e}"
        return false
    end

    # deletes triple(s,p,o) from datastore
    # nil parameters match anything: delete(nil,nil,nil) will delete all triples
    def delete(s,p,o,c=nil)
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      quad = [s,p,o,c].collect{|e| to_redland(e)}
      if quad.all?{|t| t.nil?}
        clear
      elsif quad[0..2].any?{|t| t.nil?}
        @model.find(*quad).each{|stmt| @model.delete_statement(stmt,c)}
      else
        @model.delete(*quad)
      end
      save if ConnectionPool.auto_flush?
      rescue Redland::RedlandError => e
        $activerdflog.warn "RedlandAdapter: deleting triple failed in Redland library: #{e}"
        return false
    end

    # saves updates to the model into the redland file location
    def save
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      Redland::librdf_model_sync(@model.model).nil?
    end
    alias flush save

    # returns all triples in the datastore
    def dump
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      arr = []
      @model.triples{|s,p,o| arr << [s.to_s,p.to_s,o.to_s]}
      arr
    end

    def contexts
      @model.contexts
    end

    # returns size of datasources as number of triples
    # warning: expensive method as it iterates through all statements
    def size
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      # we cannot use @model.size, because redland does not allow counting of
      # file-based models (@model.size raises an error if used on a file)
      # instead, we just dump all triples, and count them
      @model.triples.size
    end

    # clear all real triples of adapter
    def clear
      raise ActiveRdfError, "RedlandAdapter: adapter is closed" unless @enabled
      @model.triples.each{|stmt| @model.delete_statement(stmt)}
    end

    # close adapter and remove it from the ConnectionPool
    def close
      if @enabled
        ConnectionPool.remove_data_source(self)
        flush   # sync model with datastore
        @model = nil   # remove reference to model for removal by GC
        @enabled = false
      end
    end

    private
    ################ helper methods ####################
    def query_result_to_array(query_results, &block)
      results = []
      number_bindings = query_results.binding_names.size

      # redland results are set that needs to be iterated
      while not query_results.finished?
        # we collect the bindings in each row and add them to results
        row = (0..number_bindings-1).collect do |i|
          # node is the query result for one binding
          node = query_results.binding_value(i)

          # we determine the node type
          if node.nil?
            nil
          elsif node.literal?
            value = Redland.librdf_node_get_literal_value(node.node)

            lang_uri_ref = Redland.librdf_node_get_literal_value_language(node.node)
            dt_uri_ref = Redland.librdf_node_get_literal_value_datatype_uri(node.node)
            if lang_uri_ref
              LocalizedString.new(value,Redland::Uri.new(lang_uri_ref).to_s)
            elsif dt_uri_ref
              type = RDFS::Resource.new(Redland::Uri.new(dt_uri_ref).to_s)
              RDFS::Literal.typed(value,type)
            elsif lang_uri_ref and dt_uri_ref
              raise ActiveRdfError, "cannot have both datatype and lang set"
            else
              RDFS::Literal.typed(value,XSD::string)   # string is default type if none specified
            end
          elsif node.blank?
            # blank nodes are not currently supported
            nil
          else
            # other nodes are rdfs:resources
            RDFS::Resource.new(node.uri.to_s)
          end
        end
        if block_given?
          yield row
        else
          results << row
        end
        # iterate through result set
        query_results.next
      end
      results unless block_given?
    end

    def to_redland(obj)
      case obj
      when RDFS::Resource
        Redland::Uri.new(obj.uri)
      when RDFS::Literal
        str = obj.kind_of?(Time) ? obj.xmlschema : obj.to_s
        if not $activerdf_without_datatype
          if obj.kind_of?(LocalizedString)
            Redland::Literal.new(str, obj.lang)
          else
            Redland::Literal.new(str,nil,Redland::Uri.new(obj.datatype.uri))
          end
        else
          Redland::Literal.new(str)
        end
      when Class
        raise ActiveRdfError, "RedlandAdapter: class must inherit from RDFS::Resource" unless obj.ancestors.include?(RDFS::Resource)
        Redland::Uri.new(obj.class_uri.to_s)
      when Symbol, nil
        nil
      else
        Redland::Literal.new(obj.to_s)
      end
    end
  end
end