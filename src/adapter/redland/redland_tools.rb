# = redland_tools.rb
#
# Tools for Redland Adapter
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
# * TODO: Add management of Blank Node and Container in wrap and unwrap method.
#

require 'adapter/redland/redland_exceptions'

class RedlandAdapter
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private

  # Convert Redland::QueryResult into an array.
  #
  # Arguments:
  # * +query_results+ [<tt>Redland::QueryResult</tt>]: Query result from redland
  #
  # Return:
  # * [<tt>Array</tt>] Array containing query results
	def convert_query_result_to_array(query_results)
		# Init
	 	results = Array.new
	 	binding_names = query_results.binding_names

	 	# Loop
		case binding_names.size
		when 0
			raise(SparqlQueryFailed, "In #{__FILE__}:#{__LINE__}, no binding variable in result.")
		when 1
			while !query_results.finished?
				results << convert_query_value_to_activerdf(binding_names[0], query_results)
				query_results.next()
			end
		else
			while !query_results.finished?
				values = Array.new
				for binding_name in binding_names
					values << convert_query_value_to_activerdf(binding_name, query_results)
				end
				results << values
				query_results.next()
			end
		end
		return results		
	end
	
  # Convert value of Redland::QueryResult to ActiveRDF::Node
  #
  # Arguments:
  # * +binding_name+: binding name for the query result
  #
  # Return:
  # * [<tt>ActiveRDF::Node</tt>]
	def convert_query_value_to_activerdf(binding_name, query_results)
	
		if binding_name.nil? or query_results.nil?
			raise(RedlandAdapterError, "In #{__FILE__}:#{__LINE__}, nil parameters.")
		end
	
		value = query_results.binding_value_by_name(binding_name)
		if value.literal?
			return NodeFactory.create_literal(value.to_s, 'type not implemented in Redland Adapter.')
		elsif value.resource?
			return NodeFactory.create_identified_resource(value.uri.to_s)
		elsif value.blank?
			return NodeFactory.create_anonymous_resource(value.id)
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown node in results.")
		end	
	end

  # Convert Redland::Resource, Redland::Literal, Redland::BNode into
  # ActiveRDF::Node
  #
  # Arguments:
  # * +node+ : A Redland node
  #
  # Return:
	# * A node (Literal, AnonymouResource, BasinIdentifiedResource, IdentifiedResource)
	def unwrap(node)
		case node
    when NilClass
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, node is nil.")		
		when Redland::Literal
			return NodeFactory.create_literal(node.to_s, 'type not implemented in Redland Adapter.')
		when Redland::Uri, Redland::Resource, Redland::Node
			return NodeFactory.create_identified_resource(node.uri.to_s)
		when Redland::BNode
			return NodeFactory.create_anonymous_resource(node.id)
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown resource '#{node.class}' received.")
		end
	end

  # Convert ActiveRDF::Node into Redland::Uri or Redland::Literal
  #
  # Arguments:
  # * +node+ : ActiveRDF::Node to convert into Redland object
  #
  # Return:
	# * Redland::Uri or Redland::Literal to use in Redland Adapter
	def wrap(node)
		case node
    when NilClass
    	return nil
  	when Literal
    	return Redland::Literal.new(node.value)
  	when IdentifiedResource
    	return Redland::Uri.new(node.uri)
    when AnonymousResource
    	return Redland::BNode.new(node.id)
    when Container
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, container not implemented in redland adapter.")
    when Collection
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, collection not implemented in redland adapter.")
    else
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown resource '#{node.class}' received.")
		end
	end
	
end