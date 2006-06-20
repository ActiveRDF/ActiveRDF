# = redland_adapter.rb
#
# ActiveRDF Adapter to Redland storage
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

require 'rdf/redland'
require 'adapter/abstract_adapter'
require 'adapter/redland/redland_tools'
require 'adapter/redland/redland_exceptions'

class RedlandAdapter; implements AbstractAdapter
	
	attr_reader :model, :store, :query_language, :context

	# Instantiate the connection with a Redland database.
	def initialize(params)
		if params.empty?
			raise(RedlandAdapterError, "Redland adapter initialised without parameters")
		end

		path, file, type = nil
		if params[:location] and params[:location] != :memory
			path, file = File.split(params[:location])
			type = 'bdb'
		elsif params[:location] == :memory
			type = 'memory'
			path = ''
			file = '.'
		else
			raise RedlandAdapterError, "no location specified for Redland adapter"
		end
		
    @adapter_type = :redland
		@context = params[:context]
		@store = Redland::HashStore.new(type, file, path, false) #if @store.nil?
		@model = Redland::Model.new @store
		@query_language = 'sparql'
	end

	# Adds triple (subject, predicate, object) to the datamodel, returns true/false 
	# indicating success.  Subject and predicate should be Resources, object 
	# should be a Node.
	def add(s, p, o)
		# verify input
		return false if s.nil? or p.nil? or o.nil?
		return false if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
	
		begin
		  # TODO: disabled context temporarily, does not work properly in Redland
		  @model.add(wrap(s), wrap(p), wrap(o))
		  
		rescue Redland::RedlandError => e
		  return false
		end
		
		# synchronise the model
		save
	end

	# deletes triple, nil arguments treated as wildcards. Returns true/false 
	# indicating success.
	def remove(s, p, o)
		# verify input: if s/p/o is not nil it should be resource or node
		return false if !s.nil? and !s.kind_of?(Resource)
		return false if !p.nil? and !p.kind_of?(Resource)
		return false if !o.nil? and !o.kind_of?(Node)
	   
    # TODO: disabled context temporarily, does not work properly in Redland
		@model.find(wrap(s), wrap(p), wrap(o)) { |_s, _p, _o|
			# deletion failed unless @model.delete returns 0
			return false unless @model.delete(_s, _p, _o) == 0
		}
		
		# synchronise the model
		save
	end

	# save data into RDF store, return true/false indicating success
	def save
		# Redland::librdf_model_sync return nil if sync succesfully the model
    Redland::librdf_model_sync(@model.model).nil? 
	end

	# query datastore with query string (sparql), returns array with query results
	def query(qs)
		return false if qs.nil?

		# create the Redland::Query
		query = Redland::Query.new(qs, query_language)
		# Execute the query and get the Redland::QueryResult
		query_results = @model.query_execute(query)

		# verify if the query has failed
		return false if query_results.nil?
		return false unless query_results.is_bindings?

		# convert the result to array
		convert_query_result_to_array(query_results) 
	end
	
	# queries the RDF database and only counts the results
	# returns result size or false (on error)
	def query_count(qs)
		if results = query(qs)
			results.size
		else
			false
		end
	end
end
