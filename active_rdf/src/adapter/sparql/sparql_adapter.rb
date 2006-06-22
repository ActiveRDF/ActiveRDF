# = sparql_adapter.rb
#
# ActiveRDF Adapter to SPARQL endpoint
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Sebastian Gerke < first dot last at deri dot org>
# * Eyal Oren <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Sebastian Gerke and Eyal Oren - All Rights Reserved
#

require 'net/http'
#TODO: do we need this? require 'uri'
require 'cgi'
require 'active_rdf'
require 'adapter/abstract_adapter'
require 'adapter/sparql/sparql_tools'

class SparqlAdapter; implements AbstractAdapter
	attr_reader :context, :host, :port, :sparql, :query_language, :result_format

	# Instantiate the connection with the SPARQL Endpoint.
	def initialize(params = {})
		raise(ActiveRdfError, 'SPARQL adapter initialised with nil parameters') if params.nil?
		
		@host = params[:host]
		@port = params[:port]
		@context = params[:context]
		@result_format = params[:result_format]
		@query_language = 'sparql'
		@adapter_type = :sparql
		
		raise ActiveRdfError, "Result format #@result_format unsupported" unless (@result_format == :xml or @result_format == :json)
		
		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we would need to close it 
		# manually at some point in time, which I do not want to do.
		
		@sparql = Net::HTTP.new(host,port)
		$logger.debug("opened SPARQL connection on http://#{sparql.address}:#{sparql.port}/#{context}")
	end
	
	# adding is not supported by SPARQL	
	def add(s, p, o)
		false
	end
		
	# removing is not supported by SPARQL
	def remove(s, p, o)
		false
	end
	
	# saving is not supported by SPARQL
	def save
		false
	end
	
	# queries the RDF database and only counts the results
	def query_count(qs)
		# TODO: implement smarter count (without parsing) when we figure out how...
		return false if qs.nil?
		query(qs).size
	end
	
	# query datastore with query string (SPARQL), returns array with query results
	def query(qs)
		return false if qs.nil?
		$logger.debug "querying sparql in context #@context:\n" + qs
		
		# initialising HTTP header
		case result_format
		when :json
			header = { 'accept' => 'application/sparql-results+json' }
		when :xml
			header = { 'accept' => 'application/rdf+xml' }
		end
		$logger.debug "HTTP header: #{header}"
		
		response = sparql.get("/#{context}?query=#{CGI.escape(qs)}", header)
		# If no content, we return an empty array
		return Array.new if response.is_a?(Net::HTTPNoContent)
		return false unless response.is_a?(Net::HTTPOK)
		response = response.body
		
		$logger.info "response is: #{response}"
		$logger.debug "parsing Sparql response"
		
		case result_format
		when :json
			result = parse_sparql_query_result_json response
		when :xml
			result = parse_sparql_query_result_xml response
		end
		
		result
	end

end
