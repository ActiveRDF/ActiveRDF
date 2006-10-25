# SPARQL adapter
#
# Author:: Eyal Oren and Sebastian Gerke
# Copyright:: (c) 2005-2006
# License:: LGPL
require 'active_rdf'
require 'queryengine/query2sparql'
require 'net/http'
require 'cgi'

class SparqlAdapter
	$log.info "loading SPARQL adapter"
	ConnectionPool.register_adapter(:sparql, self)

	def reads?
		true
	end
	
	def writes?
		false
	end
	
	# Instantiate the connection with the SPARQL Endpoint.
	def initialize(params = {})	
		@host = params[:host] || 'm3pe.org'
		@path = params[:path] || 'repositories/'
		@port = params[:port] || 8080
		@context = params[:context] || 'test-people'
		@result_format = params[:result_format] || :sparql_xml
		
		known_formats = [:xml, :json, :sparql_xml]
		raise ActiveRdfError, "Result format unsupported" unless known_formats.include?(@result_format)
		
		$log.info "SparqlAdaper: initializing with host: #{@host} path: #{@path} port: #{@port} context #{@context} result format: #{@result_format}"
		
		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we would need to close it 
		# manually at some point in time, which I do not want to do.
		
		@sparql = Net::HTTP.new(@host,@port)
	end

	# query datastore with query string (SPARQL), returns array with query results
	def query(query)
		time = Time.now
    qs = Query2SPARQL.translate(query)
		final_result = execute_sparql_query(qs, header(query)) #, query.select_clauses.size)
		$log.debug "SparqlAdapter: query response from the SPARQL Endpoint took: #{Time.now - time}s"
		return final_result
	end
	
	def translate(query)
	 	Query2SPARQL.translate(query)
	end
		
	def execute_sparql_query(qs, header) #,nr_of_clauses)
		# TODO: can we really remove this (see line 66)
    #clauses = query.select_clauses.size

    # sending query to sparql endpoint
    response = @sparql.get("/#{@path}#{@context}?query=#{CGI.escape(qs)}", header)

    # if no content returned or if something went wrong
    # we return an empty array
    if response.is_a?(Net::HTTPNoContent)
      $log.debug "SparqlAdapter: executing the SPARQL query returned empty response"
      return [] 
    end
    
    unless response.is_a?(Net::HTTPOK)
      $log.warn "SparqlAdapter: executing the SPARQL query failed: #{response.body}"
      return [] 
    end

    # we parse content depending on the result format
    results = case @result_format
    when :json
      parse_sparql_query_result_json response.body
    when :xml, :sparql_xml
      parse_sparql_query_result_xml_stream response.body
     	# parse_sparql_query_result_xml response.body
     	# can be removed if everything is working fine. (line 129ff can be removed then as well)
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
			header = { 'accept' => 'application/sparql-results+json' }
		when :xml
			header = { 'accept' => 'application/rdf+xml' }
		when :sparql_xml
		  header = { 'accept' => 'application/sparql-results+xml' }
		end
	end

  # parse json query results into array
	def parse_sparql_query_result_json(query_result)
    require 'json'
    
    parsed_object = JSON.parse(query_result)
    return [] if parsed_object.nil?
    
    results = []    
    vars = parsed_object['head']['vars']
    objects = parsed_object['results']['bindings']
    if vars.length > 1
      objects.each do |obj|
        result = []
        vars.each do |v|
          result << create_node( obj[v]['type'], obj[v]['value'])
        end
        results << result
      end
    else
      objects.each do |obj| 
        obj.each_value do |e|
          results << create_node(e['type'], e['value'])
        end
      end
    end
    $log.debug "SparqlAdapter: parsed SPARQL query results as JSON, input: #{query_result.join(', ')} output: #{results.join(', ')}"
    return results
  end
  
  
  def parse_sparql_query_result_xml_stream(qr)
    require 'rexml/document'
    require 'adapter/sparql_result_parser'
    parser = SparqlResultParser.new
    REXML::Document.parse_stream(qr, parser)
    final_results = parser.result
    $log.debug "SparqlAdapter: parsed SPARQL query results as XML Stream"
    return final_results
  end
  
  # parse xml query results into array
  def parse_sparql_query_result_xml(query_result)
    require 'rexml/document'
    results = []
    vars = []
    objects = []
    doc = REXML::Document.new query_result
    doc.elements.each("*/head/variable") {|v| vars << v.attributes["name"]}
    doc.elements.each("*/results/result") {|o| objects << o}
    if vars.length > 1
      objects.each do |result|
        myResult = []
        vars.each do |v|
          result.each_element_with_attribute('name', v) do |binding|
            binding.elements.each do |e|
              myResult << create_node(e.name, e.text)
            end            
          end          
        end
        results << myResult
      end
      
    else
      objects.each do |bs| 
        bs.elements.each("binding") do |b|
          b.elements.each do |e|
						results << create_node(e.name, e.text)
					end
        end
      end
    end
    $log.debug "SparqlAdapter: parsed SPARQL query results as XML, input: #{query_result.join(', ')} output: #{results.join(', ')}"
    return results
  end
  
  # create ruby objects for each RDF node
  def create_node(type, value)
    case type
    when 'uri'
      RDFS::Resource.new(value)
    when 'bnode'
      nil
    when 'literal','typed-literal'
      value.to_s
    end
  end
end
