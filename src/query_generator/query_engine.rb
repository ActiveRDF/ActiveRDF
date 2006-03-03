# = query_engine.rb
#
# Engine to generate query for different adapter (Yars, SPARQL).
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
#

require 'node_factory'

class QueryEngine

	# Arguments
  attr_reader :related_resource
  private :related_resource
  
  # Container Attributes
  attr_reader :bindings, :conditions, :order, :distinct
  private :bindings, :conditions, :order, :distinct
 
  # Initialize the query engine.
  #
  # * *connection* : _AbstractAdapter_ The connection used to execute query.
	# * *related_resource* : _Resource_ Resource related to the query
  def initialize(related_resource = nil)
  	@relate_resource = related_resource
  	
  	@bindings = nil
  	@conditions = nil
  	@order = nil
  	@distinct = nil
  end
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private

  # Clean all containers (bindings, conditions, order)
  def clean
		@bindings = nil
		@conditions = nil
		@order = nil
		@distinct = nil
  end
  
  # Convert predicate if a resource is related to the query, e.g. verify if predicate is
  # included in the resource attributes (for :title, look for a 'title' attribute),
  # and convert it into a Resource.
  #
  # * *predicate* : Symbol representing the predicate.
  #
  # *Return* :
  # * Return a Resource if the predicate is included, a Symbol otherwise.
  def convert_predicate(predicate)
		predicates = @related_resource.predicates	
		
		if predicate.is_a?(Symbol) && predicates.key?(predicate.to_s)
				predicate = Resource.create(predicates[predicate.to_s])
		end
		
		return predicate
  end
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

  public

  # Add bindings variables in the select clause to the query (for Sparql)
  #
  # * *args* : Array of Symbol. Each symbol is a binding variable.
	def add_binding_variables(*args)
		@bindings = args
	end

  # Add a binding triple in the select clause to the query (for Yars). Only one
  # triple is allowed for the moment.
  #
  # * *subject* : Subject of the triple (Symbol or Resource)
  # * *predicate* : Predicate of the triple (Symbol or Resource)
  # * *object* : Object of the triple (Symbol, Resource, String, ...)
	def add_binding_triple(subject, predicate, object)
		@bindings = [subject, predicate, object]
	end

  # Add a condition in the where clause. Convert the predicate if a resource is
  # related to the query.
  #
  # * *subject* : Subject of the triple (Symbol or Resource)
  # * *predicate* : Predicate of the triple (Symbol or Resource)
  # * *object* : Object of the triple (Symbol, Resource, String, ...)
	def add_condition(subject, predicate, object)
		@conditions = Array.new if @conditions.nil?
		if @resource_related.nil?
			@conditions << [subject, predicate, object]
		else
			@conditions << [subject, convert_predicate(predicate), object]
		end
	end

  # Add an order option on a binding variable
  #
  # * *binding_variable* : binding variable (Symbol) to order
  # * *descendant* : Boolean which True if we want a descendant order.
	def order_by(binding_variable, descendant=true)
		@order = Hash.new if @order.nil?
		@order[binding_variable] = descendant
	end

	def activate_keyword_search
		@keyword_search = true
	end
	
	def distinct(*args)
		@distinct = args
	end

  # Generate a Sparql query. Return the query string.
	def generate_sparql
		require 'query_generator/sparql_generator.rb'
		return SparqlQueryGenerator.generate(@bindings, @conditions, @order, @keyword_search)
	end
	
	# Generate a NTriples query. Return the query string.
	def generate_ntriples
		require 'query_generator/ntriples_generator.rb'
		return NTriplesQueryGenerator.generate(@bindings, @conditions, @order, @keyword_search)
	end

	# Choose the query language and generate the query string.
	def generate
		case NodeFactory.connection.query_language
		when 'sparql'
			return generate_sparql
		when 'n3'
			return generate_ntriples
		else
			raise(LanguageUnknownQueryError, "In #{__FILE__}:#{__LINE__}, Unknown query language.")
		end
	end

  # Execute the query on a database, depending of the connection, and after clean
  # all the containers (bindings, conditions, order).
  #
  # *Return* :
  # * _Array_ Array containing the results of the query, nil if no result.
	def execute
		# Choose the query language and generate the query string
		qs = generate
		
		# Clean containers
		clean
		
		# Execute query
		return NodeFactory.connection.query(qs)
	end

	def count
		qs = generate
		clean
		return Resource.connection.count(qs)
	end
	
end
