# = sesame_tools.rb
#
# Tools for Sesame Adapter
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

class SesameAdapterError < StandardError; end

class SparqlQueryFailed < SesameAdapterError; end

class StatementAdditionSesameError < SesameAdapterError; end

class StatementRemoveSesameError < SesameAdapterError; end

class UnknownResourceError < SesameAdapterError; end

class SesameAdapter
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private

	# Convert Sesame::QueryResult into an array.
	#
	# Arguments:
	# * +query_results+ [<tt>Sesame::QueryResult</tt>]: Query result from sesame
	#
	# Return:
	# * [<tt>Array</tt>] Array containing query results [[binding variables], [binding variables], ...]
	def convert_query_result_to_array(iterator)
		# Init
	 	results = Array.new

		while iterator.hasNext
		  tuple = iterator.next
		  variables = tuple.size
	    if variables <  1
	      raise 'error'
	    elsif variables == 1
	      values = convert_query_value_to_activerdf(tuple.get(0))
		  else
  		  tuple_iterator = tuple.iterator
  		  values = []
  		  while tuple_iterator.hasNext
  		    values << convert_query_value_to_activerdf(tuple_iterator.next)
    	  end
	    end
	    results << values
	  end
    iterator.close
		return results		
	end
	
	# Convert value of Sesame::QueryResult to ActiveRDF::Node
	#
	# Arguments:
	# * +binding_name+: binding name for the query result
	#
	# Return:
	# * [<tt>ActiveRDF::Node</tt>]
	def convert_query_value_to_activerdf(value)
	
		if value.nil?
			raise(SesameAdapterError, "In #{__FILE__}:#{__LINE__}, nil parameters.")
		end
	
		case value._classname
	  when /RLiteral/
			return Literal.create(value.toString)
		when /RURI/
			return IdentifiedResource.create(value.toString)
		when /BNode/
			raise(SesameAdapterError, "Blank Node not implemented.")
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown node [#{value._classname}] in results.")
		end	
	end

	# Convert Sesame::Resource, Sesame::Literal, Sesame::BNode into
	# ActiveRDF::Node
	#
	# Arguments:
	# * +node+ : A Sesame node
	#
	# Return:
	# * A node (Literal, AnonymouResource, BasinIdentifiedResource, IdentifiedResource)
	def unwrap(node)
		case node
    when NilClass
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, node is nil.")		
		when Sesame::Literal
			return NodeFactory.create_literal(node.to_s, 'type not implemented in Sesame Adapter.')
		when Sesame::Uri
			return NodeFactory.create_identified_resource(node.uri.to_s)
		when Sesame::BNode
			return NodeFactory.create_anonymous_resource(node.id)
		else
			raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown resource '#{node.class}' received.")
		end
	end

	# Convert ActiveRDF::Node into Sesame::Uri or Sesame::Literal
	#
	# Arguments:
	# * +node+ : ActiveRDF::Node to convert into Sesame object
	#
	# Return:
	# * Sesame::Uri or Sesame::Literal to use in Sesame Adapter
	def wrap(node)
		case node
    when NilClass
    	return nil
  	when Literal
    	return Sesame::Literal.new(node.value)
  	when IdentifiedResource
    	return Sesame::Uri.new(node.uri)
    when AnonymousResource
    	return Sesame::BNode.new(node.getId)
    when Container
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, container not implemented in Sesame adapter.")
    when Collection
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, collection not implemented in Sesame adapter.")
    else
    	raise(UnknownResourceError, "In #{__FILE__}:#{__LINE__}, unknown resource '#{node.class}' received.")
		end
	end
	
end