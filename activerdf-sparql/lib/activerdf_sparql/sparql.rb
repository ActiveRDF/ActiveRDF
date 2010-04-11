require 'open-uri'
require 'cgi'
require 'rexml/document'
require 'active_rdf/queryengine/query2sparql'
require 'activerdf_sparql/sparql_result_parser'

module ActiveRDF
  # SPARQL adapter
  class SparqlAdapter < ActiveRdfAdapter
    ActiveRdfLogger::log_info(self) { "Loading SPARQL adapter" }
    ConnectionPool.register_adapter(:sparql, self)

    attr_reader :engine
    attr_reader :caching

    @@sparql_cache = {}

    def SparqlAdapter.get_cache
      return @@sparql_cache
    end

    # Instantiate the connection with the SPARQL Endpoint.
    # available parameters:
    # * :url => url: endpoint location e.g. "http://m3pe.org:8080/repositories/test-people"
    # * :results => one of :xml, :json, :sparql_xml
    # * :request_method => :get (default) or :post
    # * :timeout => timeout in seconds to wait for endpoint response
    # * :auth => [user, pass]
    def initialize(params = {})
      super()
      @reads = true
      @writes = false

      @url = params[:url] || ''
      @caching = params[:caching] || false
      @timeout = params[:timeout] || 50
      @auth = params[:auth] || nil

      @result_format = params[:results] || :json
      raise ActiveRdfError, "Result format unsupported" unless [:xml, :json, :sparql_xml].include? @result_format

      @engine = params[:engine] || :virtuoso
      raise ActiveRdfError, "SPARQL engine unsupported" unless [:yars2, :sesame2, :joseki, :virtuoso].include? @engine

      @request_method = params[:request_method] || :get
      raise ActiveRdfError, "Request method unsupported" unless [:get,:post].include? @request_method
      ActiveRdfLogger::log_info(self) { "Sparql adapter initialised #{inspect}" }
    end

    def size
      query(Query.new.select(:s,:p,:o).where(:s,:p,:o)).size
    end

    # query datastore with query string (SPARQL), returns array with query results
    # may be called with a block
    def execute(query, &block)
      qs = Query2SPARQL.translate(query)
      ActiveRdfLogger::log_debug(self) { "Executing sparql query #{query}" }

      if @caching
         result = query_cache(qs)
         if result.nil?
           ActiveRdfLogger.log_debug(self) { "Cache miss for query #{qs}" }
         else
           ActiveRdfLogger.log_debug(self) { "Cache hit for query #{qs}" }
           return result
         end
      end

    result = execute_sparql_query(qs, query.resource_class, header(query), &block)
      add_to_cache(qs, result) if @caching
      result = [] if result == "timeout"
      return result
    end

    # do the real work of executing the sparql query
    def execute_sparql_query(qs, resource_type, header=nil, &block)
      ActiveRdfLogger::log_debug(self) { "Executing query #{qs} on url #@url" }
      header = header(nil) if header.nil?

      # querying sparql endpoint
      require 'timeout'
      response = ''
      begin
        case @request_method
        when :get
          # encoding query string in URL
          url = "#@url?query=#{CGI.escape(qs)}"
          ActiveRdfLogger.log_debug(self) { "GET #{url}" }
          timeout(@timeout) do
            open(url, header) do |f|
              response = f.read
            end
          end
        when :post
          ActiveRdfLogger.log_debug(self) { "POST #@url with #{qs}" }
          response = Net::HTTP.post_form(URI.parse(@url),{'query'=>qs}).body
        end
      rescue Timeout::Error
        raise ActiveRdfError, "timeout on SPARQL endpoint"
      rescue OpenURI::HTTPError => e
        raise ActiveRdfError, "error on SPARQL endpoint, server said: \n%s:\n%s" % [e,e.io.read]
      rescue Errno::ECONNREFUSED
        raise ActiveRdfError, "connection refused on SPARQL endpoint #@url"
       end

      # we parse content depending on the result format
      results = case @result_format
                when :json
      parse_json(response, resource_type)
                when :xml, :sparql_xml
      parse_xml(response, resource_type)
                end

      if block_given?
        results.each do |*clauses|
          yield(*clauses)
        end
      else
        results
      end
    end

    def close
      ConnectionPool.remove_data_source(self)
    end

    private
  # FIXME: Cache not primed for handling res classes!
    def add_to_cache(query_string, result)
      unless result.nil? or result.empty?
        if result == "timeout"
          @@sparql_cache.store(query_string, [])
        else
          ActiveRdfLogger.log_debug(self) { "Adding to sparql cache - query: #{query_string}" }
          @@sparql_cache.store(query_string, result)
        end
      end
    end


    def query_cache(query_string)
      if @@sparql_cache.include?(query_string)
        return @@sparql_cache.fetch(query_string)
      else
        return nil
      end
    end

    # constructs correct HTTP header for selected query-result format
    def header(query)
      header = case @result_format
               when :json
                 { 'accept' => 'application/sparql-results+json' }
               when :xml
                 { 'accept' => 'application/rdf+xml' }
               when :sparql_xml
                 { 'accept' => 'application/sparql-results+xml' }
               end
      if @auth
        header.merge( :http_basic_authentication => @auth )
      else
        header
      end
    end

    # parse json query results into array. resource_type is the type to be used
    # for "resource" objects.
    def parse_json(s, resource_type)
        require 'json'

        parsed_object = JSON.parse(s)
        return [] if parsed_object.nil?

        results = []
        vars = parsed_object['head']['vars']
        objects = parsed_object['results']['bindings']

        objects.each do |obj|
          result = []
          vars.each do |v|
          result << create_node( obj[v]['type'], obj[v]['value'], resource_type)
          end
          results << result
        end

        results
      end

    # parse xml stream result into array
    def parse_xml(s, resource_type)
      parser = SparqlResultParser.new(resource_type)
        REXML::Document.parse_stream(s, parser)
        parser.result
      end

    # create ruby objects for each RDF node. resource_type is the class to be used
    # for "resource" objects.
    def create_node(type, value, resource_type)
      case type
      when 'uri'
      resource_type.new(value)
      when 'bnode'
        BNode.new(value)
      when 'literal','typed-literal'
        value.to_s
      end
    end
  end
end