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
	
  # Instantiate the connection with the SPARQL Endpoint.
  # available parameters:
  # * :url => url: endpoint location e.g. "http://m3pe.org:8080/repositories/test-people"
  # * :results => one of :xml, :json, :sparql_xml
  def initialize(params = {})	
    @reads = true
    @writes = false

    @url = params[:url] || ''
    @result_format = params[:results] || :json
		
    known_formats = [:xml, :json, :sparql_xml]
    raise ActiveRdfError, "Result format unsupported" unless 
    known_formats.include?(@result_format)
		
    $activerdflog.info "Sparql adapter initialised #{inspect}"
  end

  def size
    query(Query.new.select(:s,:p,:o).where(:s,:p,:o)).size
  end

  # query datastore with query string (SPARQL), returns array with query results
  # may be called with a block
  def query(query, &block)
    time = Time.now
    qs = Query2SPARQL.translate(query)
    $activerdflog.debug "executing sparql query #{query}"

    execute_sparql_query(qs, header(query), &block)
  end
		
  # do the real work of executing the sparql query
  def execute_sparql_query(qs, header=nil, &block)
    $activerdflog.debug "executing query #{qs} on url #@url"

    header = header(nil) if header.nil?

    # encoding query string in URL
    url = "#@url?query=#{CGI.escape(qs)}"

    # querying sparql endpoint
    response = ''
    begin 
      open(url, header) do |f|
        response = f.read
      end
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
	
  private
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
      Query.resource_class.new(value)
    when 'bnode'
      nil
    when 'literal','typed-literal'
      value.to_s
    end
  end
end
