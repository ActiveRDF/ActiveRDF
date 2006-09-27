# sparql adapter
require 'active_rdf'
require 'queryengine/query2sparql'

require 'net/http'
require 'cgi'
require 'active_rdf'

class SparqlAdapter
	ConnectionPool.instance.register_adapter(:sparql, self)

	def reads?
		true
	end
	
	def writes?
		false
	end
	
	# Instantiate the connection with the SPARQL Endpoint.
	def initialize(params = {})
		raise(ActiveRdfError, 'SPARQL adapter initialised with nil parameters') if params.nil?
		
		@host = params[:host] || 'm3pe.org'
		@port = params[:port] || 2020
		@context = params[:context] || 'books'
		@result_format = params[:result_format] || :json
		
		known_formats = [:xml, :json, :sparql_xml]
		raise ActiveRdfError, "Result format unsupported" unless known_formats.include?(@result_format)
		
		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we would need to close it 
		# manually at some point in time, which I do not want to do.
		
		@sparql = Net::HTTP.new(@host,@port)
	end
	
	# query datastore with query string (SPARQL), returns array with query results
	def query(query)
		qs = Query2SPARQL.translate(query)
		clauses = query.select_clauses.size
		
		# initialising HTTP header
		case @result_format
		when :json
			header = { 'accept' => 'application/sparql-results+json' }
		when :xml
			header = { 'accept' => 'application/rdf+xml' }
		when :sparql_xml
		  header = { 'accept' => 'application/sparql-results+xml' }
		end
		response = @sparql.get("/#{@context}?query=#{CGI.escape(qs)}", header)
		# If no content, we return an empty array
		return Array.new if response.is_a?(Net::HTTPNoContent)
		return false unless response.is_a?(Net::HTTPOK)
		response = response.body
		results = case @result_format
		when :json
			parse_sparql_query_result_json response
		when :xml
			parse_sparql_query_result_xml response
		when :sparql_xml
		  parse_sparql_query_result_xml response
		end
		
		if block_given?
			results.each do |clauses|
				yield(*clauses)
			end
		else
			results
		end
	end

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
    return results
  end
  
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
    return results
  end
  
  def create_node(type, value)
    case type
    when 'uri'
      RDFS::Resource.lookup(value)
    when 'bnode'
      raise(ActiveRdfError, "blank node not implemented.")
    when 'literal','typed-literal'
      value.to_s
    end
  end
end
