# = redland_adapter.rb
# ActiveRDF Adapter to Redland storage
# ----
# Project	: ActiveRDF
#
# See		: http://m3pe.org/activerdf/
#
# Author	: Renaud Delbru, Eyal Oren
#
# Mail		: first dot last at deri dot org
#
# (c) 2005-2006

require 'rdf/redland'
require 'adapter/abstract_adapter'
require 'adapter/redland/redland_tools'
require 'adapter/redland/redland_exceptions'

class RedlandAdapter; implements AbstractAdapter; implements RedlandAdapterToolBox
	
	attr_reader :model

	# Instantiate the connection with the Redland DataBase.
	def initialize
		@store = Redland::HashStore.new('bdb', 'test-store', '/tmp' , false) if @store.nil?
		@model = Redland::Model.new @store
		@query_language = 'sparql'
	end

  # Add the statement to the model. Convert String or ActiveRDF::Resource into
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
	end

	# Delete a triple. Call the delete method of Redland Library.
	# There is a hacks. Try to delete the triple with object as Literal, then
	# try to delete the triple with object as Redland::Uri. It's due to ActiveRDF
	# which manage only String.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: The subject of the triple to delete
	# * +p+ [<tt>Resource</tt>]: The predicate of the triple to delete
	# * +o+ [<tt>Node</tt>]: The object of the triple to delete
	def remove(s, p, o)
		# Verification of nil object
		if s.nil? or p.nil? or o.nil?
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : nil received."
			raise(StatementRemoveRedlandError, str_error)		
		end
		
		# Verification of type
		if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : wrong type received."
			raise(StatementRemoveRedlandError, str_error)		
		end
		
		# Redland::Model::delete return 0 if delete succesfully the statement
		if @model.delete(wrap(s), wrap(p), wrap(o)) != 0
			str_error = "In #{__FILE__}:#{__LINE__}, error during removal of statement (#{s.to_s}, #{p.to_s}, #{o.to_s})."
			raise(StatementRemoveRedlandError, str_error)
		end
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
  # * [<tt>Hash</tt>] Hash containing the result of the query.
	def query(qs)
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
