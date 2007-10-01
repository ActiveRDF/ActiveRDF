require 'active_rdf'
require 'queryengine/query2sparql'
require 'open-uri'
require 'cgi'
require 'rexml/document'
require "#{File.dirname(__FILE__)}/sparql_result_parser"

# SPARQL adapter
class SparqlAdapter < ActiveRdfAdapter
	$activerdflog.info "loading SPARQL adapter"
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
	def initialize(params = {})	
		@reads = true
		@writes = false

		@url = params[:url] || ''
    @caching = params[:caching] || false
    @timeout = params[:timeout] || 50

		@result_format = params[:results] || :json
		raise ActiveRdfError, "Result format unsupported" unless [:xml, :json, :sparql_xml].include? @result_format

    @engine = params[:engine]
		raise ActiveRdfError, "SPARQL engine unsupported" unless [:yars2, :sesame2, :joseki, :virtuoso].include? @engine

    @request_method = params[:request_method] || :get
    raise ActiveRdfError, "Request method unsupported" unless [:get,:post].include? @request_method
	end

	def size
		query(Query.new.select(:s,:p,:o).where(:s,:p,:o)).size
	end

	# query datastore with query string (SPARQL), returns array with query results
	# may be called with a block
	def query(query, &block)
    qs = Query2SPARQL.translate(query)

    if @caching
       result = query_cache(qs)
       if result.nil?
         $activerdflog.debug "cache miss for query #{qs}"
       else
         $activerdflog.debug "cache hit for query #{qs}"
         return result
       end
    end

    result = execute_sparql_query(qs, header(query), &block)
    add_to_cache(qs, result) if @caching
		result = [] if result == "timeout"
		return result
	end
		
	# do the real work of executing the sparql query
	def execute_sparql_query(qs, header=nil, &block)
    header = header(nil) if header.nil?

    # querying sparql endpoint
    require 'timeout'
		response = ''
		begin 
      case @request_method
      when :get
        # encoding query string in URL
        url = "#@url?query=#{CGI.escape(qs)}"
        $activerdflog.debug "GET #{url}"
        timeout(@timeout) do
          open(url, header) do |f|
            response = f.read
          end
        end
      when :post
        $activerdflog.debug "POST #@url with #{qs}"
        response = Net::HTTP.post_form(URI.parse(@url),{'query'=>qs}).body
      end
  	rescue Timeout::Error
			raise ActiveRdfError, "timeout on SPARQL endpoint"
  	  return "timeout"
		rescue OpenURI::HTTPError => e
			raise ActiveRdfError, "could not query SPARQL endpoint, server said: #{e}"
			return []
		rescue Errno::ECONNREFUSED
			raise ActiveRdfError, "connection refused on SPARQL endpoint #@url"
			return []
	 	end

    # we parse content depending on the result format
    results = case @result_format
						 	when :json 
								parse_json(response)
						 	when :xml, :sparql_xml
							 	parse_xml(response)
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
  def add_to_cache(query_string, result)
    unless result.nil? or result.empty?
      if result == "timeout"
        @@sparql_cache.store(query_string, [])
      else 
        $activerdflog.debug "adding to sparql cache - query: #{query_string}"
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
		case @result_format
		when :json
			{ 'accept' => 'application/sparql-results+json' }
		when :xml
			{ 'accept' => 'application/rdf+xml' }
		when :sparql_xml
		  { 'accept' => 'application/sparql-results+xml' }
		end
	end

  # parse json query results into array
	def parse_json(s)
	  # this will try to first load json with the native c extensions, 
	  # and if this fails json_pure will be loaded
    require 'json'
    
    parsed_object = JSON.parse(s)
    return [] if parsed_object.nil?
    
    results = []    
    vars = parsed_object['head']['vars']
    objects = parsed_object['results']['bindings']

		objects.each do |obj|
			result = []
			vars.each do |v|
				result << create_node( obj[v]['type'], obj[v]['value'])
			end
			results << result
		end

    results
  end
  
  # parse xml stream result into array
  def parse_xml(s)
    parser = SparqlResultParser.new
    REXML::Document.parse_stream(s, parser)
    parser.result
  end
  
  # create ruby objects for each RDF node
  def create_node(type, value)
    case type
    when 'uri'
      RDFS::Resource.new(value)
    when 'bnode'
      BNode.new(value)
    when 'literal','typed-literal'
      value.to_s
    end
  end
  
  
  
end
