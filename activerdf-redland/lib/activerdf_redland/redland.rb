# Adapter to Redland database
# uses SPARQL for querying
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL
require 'active_rdf'
require 'federation/connection_pool'
require 'queryengine/query2sparql'
require 'rdf/redland'

class RedlandAdapter
	$log.info "loading Redland adapter"
	ConnectionPool.register_adapter(:redland,self)
	
	# instantiate connection to Redland database
	def initialize(params = {})

		if params[:location] and params[:location] != :memory
			# setup file locations for redland database
			path, file = File.split(params[:location])
			type = 'bdb'
		else
			# fall back to in-memory redland 	
			type = 'memory'; path = '';	file = '.'
		end
		
		$log.info "RedlandAdapter: initializing with type: #{type} file: #{file} path: #{path}"
		
		@store = Redland::HashStore.new(type, file, path, false)
		@model = Redland::Model.new @store
	end	
	
	# yields query results (as many as requested in select clauses) executed on data source
	def query(query)
		qs = Query2SPARQL.translate(query)
    $log.debug "RedlandAdapter: after translating to SPARQL, query is: #{qs}"
		
		time = Time.now
		clauses = query.select_clauses.size
		redland_query = Redland::Query.new(qs, 'sparql')
		query_results = @model.query_execute(redland_query)
		$log.debug "RedlandAdapter: query response from Redland took: #{Time.now - time}s"

		# verify if the query has failed
		if query_results.nil?
		  $log.debug "RedlandAdapter: query has failed with nil result"
		  return false
		end
		if query_results.is_bindings?
		  $log.debug "RedlandAdapter: query has failed without bindings"
		  return false
		end

		# convert the result to array
		#TODO: if block is given we should not parse all results into array first
		results = query_result_to_array(query_results) 
    $log.debug "RedlandAdapter: result of query is #{results.join(', ')}"
		
		if block_given?
			results.each do |clauses|
				yield(*clauses)
			end
		else
			results
		end
	end
	
	# add triple to datamodel
	def add(s, p, o)
		# verify input
		if s.nil? 
      $log.debug "RedlandAdapter: add: subject is nil, exiting"
		  return false
		elsif p.nil? 
      $log.debug "RedlandAdapter: add: predicate is nil, exiting"
		  return false
		elsif o.nil?
      $log.debug "RedlandAdapter: add: object is nil, exiting"		
		  return false		
		end 
		
		if !s.kind_of?(RDFS::Resource) or !p.kind_of?(RDFS::Resource)
      $log.debug "RedlandAdapter: add: subject is no RDFS::Resource, exiting"		
		  return false
	  elsif !p.kind_of?(RDFS::Resource)
      $log.debug "RedlandAdapter: add: predicate is no RDFS::Resource, exiting"			  
	    return false
		end
	
    $log.debug "RedlandAdapter: adding triple #{s} #{p} #{o}"
	
		begin
		  @model.add(wrap(s), wrap(p), wrap(o))		  
		rescue Redland::RedlandError => e
		  $log.warn "RedlandAdapter: adding triple failed in Redland library: #{e}"
		  return false
		end		
	end
	
	def reads?
		true
	end
	
	def writes?
		true
	end
	
	################ helper methods ####################
	#TODO: if block is given we should not parse all results into array first
	def query_result_to_array(query_results)
	 	results = []
	 	number_bindings = query_results.binding_names.size
	 	
	 	# walk through query results, and construct results array
	 	# by looking up each result (if it is a resource) and adding it to the result-array
	 	# for literals we only add the values
	 	
	 	# redland results are set that needs to be iterated
	 	while not query_results.finished?
	 		# we collect the bindings in each row and add them to results
	 		results << (0..number_bindings-1).collect do |i|	 		
	 			# node is the query result for one binding
	 			node = query_results.binding_value(i)

				# we determine the node type
 				if node.literal?
 					# for literal nodes we just return the value
 					node.to_s
 				elsif node.blank?
 				  # blank nodes we ignore
 				  nil
			  else
 				 	# other nodes are rdfs:resources
 					RDFS::Resource.new(node.uri.to_s)
	 			end
	 		end
	 		# iterate through result set
	 		query_results.next
	 	end
	 	results
	end	 	
	
	def wrap node
		case node
		when RDFS::Resource
			Redland::Uri.new(node.uri)
		else
			Redland::Literal.new(node)
		end
	end
end
