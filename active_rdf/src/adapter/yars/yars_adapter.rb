# = yars_adapter.rb
#
# ActiveRDF Adapter to Yars storage
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#

require 'net/http'
require 'uri'
require 'cgi'
require 'adapter/abstract_adapter'
require 'adapter/yars/yars_tools.rb'

class YarsAdapter; implements AbstractAdapter
	
	attr_reader :context, :host, :port, :yars, :query_language
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	# Instantiate the connection with the Yars DataBase.
	def initialize(params = {})
		if params.nil?
			raise(YarsError, "In #{__FILE__}:#{__LINE__}, Yars adapter initialisation error. Parameters are nil.")
		end
	 
		@adapter_type = :yars
		@host = params[:host]
		@port = params[:port] || 8080
		@context = params[:context] || ''
		@query_language = 'n3'

		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we would need to close it 
		# manually at some point in time, which I do not want to do.
	
		if proxy=params[:proxy]
			proxy = Net::HTTP.Proxy(proxy) if (proxy.is_a? String and not proxy.empty?)
			raise YarsError, "provided proxy is not a valid Net::HTTP::Proxy" unless (proxy.is_a?(Class) and proxy.ancestors.include?(Net::HTTP))
			@yars = proxy.new(host, port)
		else
			@yars = Net::HTTP.new(host, port)
		end

		$logger.debug("opened YARS connection on http://#{yars.address}:#{yars.port}/#{context}")
	end

	# Adds triple (subject, predicate, object) to the datamodel, returns true/false 
	# indicating success.  Subject and predicate should be Resources, object 
	# should be a Node.
	def add(s, p, o)
		# verify input
		return false if s.nil? or p.nil? or o.nil?
		return false if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
		
		# upload data to yars
		header = { 'Content-Type' => 'application/rdf+n3' }
		data = "#{wrap(s)} #{wrap(p)} #{wrap(o)} ."
		
		$logger.debug "putting data to yars (in context #{'/'+context}): #{data}"
		response = yars.put('/' + context, data, header)
		
		# verify response
		$logger.debug 'PUT - response from yars: ' + response.message
		response.instance_of?(Net::HTTPCreated)
	end

	# queries the RDF database and only counts the results
	# returns result size or false (on error)
	def query_count(qs)
		false if qs.nil?
		$logger.debug "querying count yars in context #@context:\n" + qs
		
		header = { 'Accept' => 'application/rdf+n3' }
		response = yars.get("/#{context}?q=#{CGI.escape(qs)}", header)
		
		# If no content, we return an empty array
		return 0 if response.is_a?(Net::HTTPNoContent)
		return false unless response.is_a?(Net::HTTPOK)
		
		# returns number of results
		return response.body.count("\n")
	end

	# query datastore with query string (n3ql), returns array with query results
	def query(qs)
		return false if qs.nil?
		
		header = { 'Accept' => 'application/rdf+n3' }
		response = yars.get("/#{context}?q=#{CGI.escape(qs)}", header)
		
		# return empty array if no content
		return [] if response.is_a?(Net::HTTPNoContent)

		# return false unless HTTP OK returned
		return false unless response.is_a?(Net::HTTPOK)

		parse_yars_query_result(response.body)
	end

	# deletes triple, nil arguments treated as wildcards. Returns true/false 
	# indicating success.
	def remove(s, p, o)
		return false if !s.nil? and !s.kind_of?(Resource)
		return false if !p.nil? and !p.kind_of?(Resource)
		return false if !o.nil? and !o.kind_of?(Node)

		qe = QueryEngine.new
		
		s = s.nil? ? :s : s
		p = p.nil? ? :p : p
		o = o.nil? ? :o : o
		
		# Add binding triple
		qe.add_binding_triple(s, p, o)
		qe.add_condition(s, p, o)
		
		qs = qe.generate
		delete(qs)
	end

	# save data into RDF store, return true/false indicating success
	def save
		# the YARS adapter already saves all actions into the datastore directly, so 
		# this method does not do anything
		true
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#
	
private

	# Verification of type
	def verify_input_type(s,p,o)
		if (!s.nil? and !s.kind_of?(Resource)) or
		   (!p.nil? and !p.kind_of?(Resource)) or
		   (!o.nil? and !o.kind_of?(Node))
			raise(ActiveRdfError, 'wrong type received for removal')
		end
	end
	
	# Delete results of query string from database
	# qs is an n3 query, e.g. '<> ql:select {?s ?p ?o . }; ql:where {?s ?p ?o . } .'
	def delete(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		$logger.debug "DELETE in context #{@context} - query: #{qs}"
		response = yars.delete("/#{@context}?q=" + CGI.escape(qs))
		$logger.debug 'DELETE - response from yars: ' + URI.decode(response.message)
		return response.instance_of?(Net::HTTPOK)
	end

end

