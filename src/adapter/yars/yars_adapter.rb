# project : ActiveRDF, http://m3pe.org/activerdf/
#
# authors : Renaud Delbru, Eyal Oren
#
# contact	: first dot last at deri dot org
#
# (c) 2005-2006


require 'net/http'
require 'uri'
require 'adapter/abstract_adapter'
require 'adapter/yars/yars_tools.rb'

class YarsAdapter; implements AbstractAdapter
	# TODO make constants private
	#Prefix = '@prefix ql: <http://www.w3.org/2004/12/ql#> . '
	#private :Prefix

	def initialize params={}
		@host = params[:host] || 'localhost'
		@port = params[:port] || 8080
		@context = '/' + (params[:context] || '')
		@query_language = 'n3'

		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we need to close it manually at 
		# some point in time (which I don't know how to do).
		@yars = Net::HTTP.new(@host, @port)

		$logger.info("opened YARS connection on http://#{@yars.address}:#{@yars.port}")
	end

	# add the triple s,p,o in the database
	def add s, p, o
		if s.nil? or p.nil? or o.nil?
			raise(StatementAdditionYarsError, "trying to add nil triple: #{s}, #{p}, #{o}")
		end
		put "#{wrap(s)} #{wrap(p)} #{wrap(o)} ."
	end

	# add data (string of ntriples) to database
	def put data
		header = { 'Content-Type' => 'application/rdf+n3' }
		#$logger.debug 'putting data to yars: ' + data
		response = @yars.put @context, data, header
		$logger.info 'response from yars: ' + response.message
		#$logger.debug 'query result: ' + response.body
		response.instance_of?(Net::HTTPCreated)
	end

	# query the RDF database
	#
	# qs is an n3 query, e.g. '<> ql:select { ?s ?p ?o . } ; ql:where { ?s ?p ?o . } .'
	def query(qs, distinct_var = nil)
		$logger.debug "querying yars in context #@context:\n" + qs

		header = { 'Accept' => 'application/rdf+n3' }
		
		response = @yars.get @context + '?q=' + URI.escape(qs), header
		
		return nil if response.is_a? Net::HTTPNoContent
		raise(QueryYarsError,'bad request: ' + qs) if response.is_a? Net::HTTPBadRequest
		$logger.info 'query response from yars: ' + URI.decode(response.message)
		#$logger.debug 'results from yars: ' + URI.decode(response.body)
		parse_n3 response.body		
	end
	
	def count(qs, distinct_var = nil)
		header = { 'Accept' => 'application/rdf+n3' }
		response = @yars.get @context + '?q=' + URI.escape(qs), header
		return nil if response.is_a? Net::HTTPNoContent
		raise(QueryYarsError,'bad request: ' + qs) if response.is_a? Net::HTTPBadRequest
		count_n3 response.body
	end	

	# delete results of query string from database
	# qs is an n3 query, e.g. '<> ql:select {?s ?p ?o . }; ql:where {?s ?p ?o . } .'
	def delete qs
		#$logger.debug 'deleting from yars: ' + qs
		response = @yars.delete @context + '?q=' + URI.encode(qs)
		$logger.debug 'response from yars: ' + URI.decode(response.message)
		return response.instance_of?(Net::HTTPOK)
	end

	def save
		true
	end

#	# TODO remove
#	def find s,p,o
#		s = s.nil? ? '?s' : N3.wrap(s)
#		p = p.nil? ? '?p' : N3.wrap(p)
#		o = o.nil? ? '?o' : N3.wrap(o)
#		$logger.debug("trying to find: #{s.to_s} #{p.to_s} #{o.to_s}")
#		qs = Prefix + "<> ql:select { #{s} #{p} #{o} . } ; ql:where { #{s} #{p} #{o} . } ."
#		query qs
#	end
#
#	# TODO change to delete(qs) maybe? Let ActiveRDF build the query string
#	def remove s,p,o
#		s = s.nil? ? '?s' : N3.wrap(s)
#		p = p.nil? ? '?p' : N3.wrap(p)
#		o = o.nil? ? '?o' : N3.wrap(o)
#		qs = Prefix + "<> ql:select { #{s} #{p} #{o} . } ; ql:where { #{s} #{p} #{o} . } ."
#		delete(qs)
#	end
end

