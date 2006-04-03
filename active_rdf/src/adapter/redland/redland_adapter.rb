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
	
	attr_reader :model, :store, :query_language

	# Instantiate the connection with the Redland DataBase.
	def initialize(params = {})
		if params.nil?
			raise(RedlandError, "In #{__FILE__}:#{__LINE__}, Redland adapter initialisation error. Parameters are nil.")
		end

		if params[:location] and params[:location] != :memory
			location_split = File.split(params[:location])
			@store_path = location_split[0]
			@store_file = location_split[1]
			@hash_type = 'bdb'
		elsif params[:location] == :memory
			@hash_type = 'memory'
			@store_path = ''
			@store_file = '.'
		else
			@store_path = '/tmp'
			@store_file = 'test-store'
			@hash_type = 'bdb'
		end		

		@store = Redland::HashStore.new(@hash_type, @store_file, @store_path, false) if @store.nil?
		@model = Redland::Model.new @store
		@query_language = 'sparql'
	end

	# Add the statement to the model. Convert ActiveRDF::Node into
	# Redland::Literal or Redland::URI with wrap method.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: Subject of triples
	# * +p+ [<tt>Resource</tt>]: Predicate of triples
	# * +o+ [<tt>Node</tt>]: Object of triples. Can be a _Literal_ or a _Resource_
	def add(s, p, o)
		# Verification of nil object
		if s.nil? or p.nil? or o.nil?
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : nil received."
			raise(StatementAdditionRedlandError, str_error)		
		end
		
		# Verification of type
		if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : wrong type received."
			raise(StatementAdditionRedlandError, str_error)		
		end
	
		# Redland::Model::add return 0 if add succesfully the statement
		if @model.add(wrap(s), wrap(p), wrap(o)) != 0
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement (#{s.to_s}, #{p.to_s}, #{o.to_s})."
			raise(StatementAdditionRedlandError, str_error)
		end
		
		# Synchronise the model
		save
	end

	# Delete a triple. Call the delete method of Redland Library.
	# If an argument is nil, it becomes a wildcard.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: The subject of the triple to delete
	# * +p+ [<tt>Resource</tt>]: The predicate of the triple to delete
	# * +o+ [<tt>Node</tt>]: The object of the triple to delete
	#
	# Return:
	# * [<tt>Integer</tt>] Number of statement removed
	def remove(s, p, o)
		# Verification of type
		if (!s.nil? and !s.kind_of?(Resource)) or
			 (!p.nil? and !p.kind_of?(Resource)) or
			 (!o.nil? and !o.kind_of?(Node))
			str_error = "In #{__FILE__}:#{__LINE__}, error during removal of statement : wrong type received."
			raise(StatementRemoveRedlandError, str_error)		
		end

		# Find all statement and remove them
		counter = 0
		@model.find(wrap(s), wrap(p), wrap(o)) { |_s, _p, _o|
			# Redland::Model::delete return 0 if delete succesfully the statement
			if @model.delete(_s, _p, _o) != 0
				str_error = "In #{__FILE__}:#{__LINE__}, error during removal of statement (#{s.to_s}, #{p.to_s}, #{o.to_s})."
				raise(StatementRemoveRedlandError, str_error)
			end
			counter += 1
		}
		
		# Synchronise the model
		save
		
		return counter
	end

	# Synchronise the model to the model implementation.
	def save
		# Redland::librdf_model_sync return nil if sync succesfully the model
		raise(RedlandAdapterError, 'Model save failed.') unless Redland::librdf_model_sync(@model.model).nil?
	end

	# Query the Redland data storage
	#
	# Arguments:
	# * +qs+ [<tt>String</tt>]: The query string in Sparql langage
	#
	# Return:
	# * [<tt>Array</tt>] Array containing the result of the query.
	def query(qs)
		raise(SparqlQueryFailed, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		# Create the Redland::Query
		query = Redland::Query.new(qs, query_language)
		# Execute the query and get the Redland::QueryResult
		query_results = @model.query_execute(query)
		# Verify if the query has failed
		raise(SparqlQueryFailed, "In #{__FILE__}:#{__LINE__}, Query failed:\n#{qs}") if query_results.nil?
		# Convert the result to Hash if it is a binding
		result = convert_query_result_to_array(query_results) if query_results.is_bindings?
		return result
	end
	
end
