# = jena_adapter.rb
#
# ActiveRDF Adapter to Jena storage
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Damian Steer <d.steer@bris.ac.uk>
#
# == Copyright
#
# Don't care
#

require 'java'
require 'adapter/abstract_adapter'

include_class "com.hp.hpl.jena.rdf.model.ModelFactory"
include_class "com.hp.hpl.jena.rdf.model.AnonId"
include_class "java.lang.System"
include_class "com.hp.hpl.jena.query.QueryFactory"
include_class "com.hp.hpl.jena.query.QueryExecutionFactory"
include_class "com.hp.hpl.jena.util.FileManager"
include_class "ModelFix"

class JenaAdapter; implements AbstractAdapter
	
	attr_reader :model, :query_language

	# Instantiate the connection with the Redland DataBase.
	def initialize(params = {})
	  if params[:location]
	    @model = FileManager.get.loadModel(params[:location])
    else
		  @model = ModelFactory.createDefaultModel
	  end
		@query_language = 'sparql'
		
		# we have an issue with java integration and listStatements
		model_class = Java::JavaClass.for_name("com.hp.hpl.jena.rdf.model.Model")
		@listStatements = model_class.java_method("listStatements", "com.hp.hpl.jena.rdf.model.Resource", "com.hp.hpl.jena.rdf.model.Property", "com.hp.hpl.jena.rdf.model.RDFNode")
	end

	# Add the statement to the model. Convert ActiveRDF::Node into
	# Redland::Literal or Redland::URI with wrap method.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: Subject of triples
	# * +p+ [<tt>Resource</tt>]: Predicate of triples
	# * +o+ [<tt>Node</tt>]: Object of triples. Can be a _Literal_ or a _Resource_
	def add(s, p, o)
		#p "Add... <#{wrap(s)}> <#{wrapP(p)}> <#{wrap(o)}>"
		@model.add(wrap(s),wrapP(p),wrap(o))
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
		#p "Remove...<#{wrap(s)}> <#{wrapP(p)}> <#{wrap(o)}>"
		#si = @model.listStatements(wrap(s),wrapP(p),wrap(o))
		
		# This is the low level version of the line above (which goes wrong when o is null)
		# Much proxy and un-proxying
		
		si = @listStatements.invoke(Java.ruby_to_java(@model), 
		  Java.ruby_to_java(wrap(s)),
		  Java.ruby_to_java(wrapP(p)),
		  Java.ruby_to_java(wrap(o)))
		si = Java.java_to_ruby(si)
		while si.hasNext do si.removeNext end
	end

	# Synchronise the model to the model implementation.
	def save
		@model.write(System.out, "N3")
	end
	
	# Take an activerdf node, return a jena RDFNode
	def wrap(node)
		case node
		when NilClass
			return nil
		when Literal
			return @model.createLiteral(node.value) # I drop datatype. Bad!
		when AnonymousResource 
			return @model.createResource(AnonId.create(node.id))
		when IdentifiedResource
			return @model.createResource(node.uri)
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown resource '#{node.class}' received.")
		end
	end
	
	# Returns property node. Assumes it's an IdentifiedResource
	def wrapP(node)
		if node
			@model.createProperty(node.uri)
		else
			nil
		end
	end

	# Query the Jena data storage
	#
	# Arguments:
	# * +qs+ [<tt>String</tt>]: The query string in Sparql langage
	#
	# Return:
	# * [<tt>Array</tt>] Array containing the result of the query.
	def query(qs)
		#p "Query: <#{qs}>"
		query = QueryFactory.create(qs.to_s)
		query_results = QueryExecutionFactory.create(query, @model).execSelect
		binding_names = query_results.getResultVars
		# Init
	 	results = Array.new

	 	# Loop
		case binding_names.size
		when 0
			raise(SparqlQueryFailed, "In #{__FILE__}:#{__LINE__}, no binding variable in result.")
		when 1
			while query_results.hasNext
				results << convert_query_value_to_activerdf(binding_names.get(0), query_results.nextSolution)
			end
		else
			while query_results.hasNext
				values = Array.new
				for binding_name in binding_names
					values << convert_query_value_to_activerdf(binding_name, query_results.nextSolution)
				end
				results << values
			end
		end
		return results
	end

	def convert_query_value_to_activerdf(binding_name, query_results)
		if binding_name.nil? or query_results.nil?
			raise(Exception, "In #{__FILE__}:#{__LINE__}, nil parameters.")
		end
	
		value = query_results.get(binding_name)
		if value.isLiteral
			return NodeFactory.create_literal(value.getLexicalForm, value.getDatatypeURI)
		elsif value.isURIResource
			return NodeFactory.create_identified_resource(value.getURI)
		elsif value.isAnon
			return NodeFactory.create_anonymous_resource(value.getId.toString)
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown node in results.")
		end	
	end
	
end
