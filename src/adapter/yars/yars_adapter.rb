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
# == To-do
#
# * To-do 1

require 'net/http'
require 'uri'
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
	
		@host = params[:host] || 'localhost'
		@port = params[:port] || 8080
		@context = '/' + (params[:context] || '')
		@query_language = 'n3'

		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we need to close it manually at 
		# some point in time (which I don't know how to do).
		@yars = Net::HTTP.new(host, port)

		$logger.info("opened YARS connection on http://#{yars.address}:#{yars.port}")
	end

  # Add the triple s,p,o in the database.
  #
  # Arguments:
  # * +s+ [<tt>Resource</tt>]: Subject of triples
  # * +p+ [<tt>Resource</tt>]: Predicate of triples
  # * +o+ [<tt>Node</tt>]: Object of triples. Can be a _Literal_ or a _Resource_
	def add(s, p, o)
		# Verification of nil object
		if s.nil? or p.nil? or o.nil?
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : nil received."
			raise(StatementAdditionYarsError, str_error)		
		end
				
		# Verification of type
		if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : wrong type received."
			raise(StatementAdditionYarsError, str_error)		
		end
		
		if !put("#{wrap(s)} #{wrap(p)} #{wrap(o)} .")
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement (#{s.to_s}, #{p.to_s}, #{o.to_s})."
			raise(StatementAdditionYarsError, str_error)
		end
	end

	# query the RDF database
	#
	# qs is an n3 query, e.g. '<> ql:select { ?s ?p ?o . } ; ql:where { ?s ?p ?o . } .'
	def query(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		
		$logger.debug "querying yars in context #@context:\n" + qs

		header = { 'Accept' => 'application/rdf+n3' }
		response = yars.get(context + '?q=' + URI.escape(qs), header)
		return nil if response.is_a?(Net::HTTPNoContent)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, bad request: " + qs) if response.is_a?(Net::HTTPBadRequest)
		
		$logger.info 'query response from yars: ' + URI.decode(response.message)
		#$logger.debug 'results from yars: ' + URI.decode(response.body)
		
		parse_yars_query_result(response.body)
	end

	# Delete a triple. Generate a query and call the delete method of Yars.
	# If an argument is nil, it becomes a wildcard.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: The subject of the triple to delete
	# * +p+ [<tt>Resource</tt>]: The predicate of the triple to delete
	# * +o+ [<tt>Node</tt>]: The object of the triple to delete
	def remove(s, p, o)
		# Verification of type
		if (!s.nil? and !s.kind_of?(Resource)) or
			 (!p.nil? and !p.kind_of?(Resource)) or
			 (!o.nil? and !o.kind_of?(Node))
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : wrong type received."
			raise(StatementRemoveYarsError, str_error)		
		end

		qe = QueryEngine.new
		
		s = s.nil? ? :s : s
		p = p.nil? ? :p : p
		o = o.nil? ? :o : o
		
		# Add binding triple
		qe.add_binding_triple(s, p, o)
		qe.add_condition(s, p, o)
		
		if !delete(qe.generate)
			str_error = "In #{__FILE__}:#{__LINE__}, error during removal of statement (#{s.to_s}, #{p.to_s}, #{o.to_s})."
			raise(StatementRemoveYarsError, str_error)
		end
	end

	# Synchronise the model. For Yars, it isn't necessary. Just return true.
	def save
		true
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#
	
	private
	
	# Add data (string of ntriples) to database
	#
	# Arguments:
	# * +data+ [<tt>String</tt>]: NTriples to add
	def put(data)
		header = { 'Content-Type' => 'application/rdf+n3' }
		
		$logger.debug 'Yars intance = ' + yars.to_s
		$logger.debug 'putting data to yars: ' + data
		
		response = yars.put(context, data, header)
		
		$logger.info 'PUT - response from yars: ' + response.message
		#$logger.debug 'query result: ' + response.body
		
		return response.instance_of?(Net::HTTPCreated)
	end

	# Delete results of query string from database
	# qs is an n3 query, e.g. '<> ql:select {?s ?p ?o . }; ql:where {?s ?p ?o . } .'
	def delete(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		$logger.debug 'DELETE - query: ' + qs
		response = yars.delete(@context + '?q=' + URI.encode(qs))
		$logger.debug 'DELETE - response from yars: ' + URI.decode(response.message)
		return response.instance_of?(Net::HTTPOK)
	end

end

