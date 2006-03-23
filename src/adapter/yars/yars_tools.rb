# = yars_tools.rb
#
# Tools for Yars adapter
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

require 'strscan'
require 'adapter/yars/yars_exceptions.rb'

class YarsAdapter
  
	private

	# Convert n3 resource and literal into ActiveRDF::Resource or String
	def unwrap(resource)
		case resource
		when /"(.*)"/
			return $1
		when /<(.*)>/
			return Resource.new($1)
		else
			raise(WrapNTriplesError, "In #{__FILE__}:#{__LINE__}, cannot wrap unknown resource #{resource.class}")
		end
	end

	# Convert ActiveRDF::Node into n3 resource and literal
	#
	# Arguments:
	# * +node+ : ActiveRDF::Node to convert into yars object
	#
	# Return:
	# * String to use in Yars Adapter
	def wrap(node)
		case node
    when NilClass
    	raise(WrapYarsError, "In #{__FILE__}:#{__LINE__}, node is nil.")
  	when Literal
    	return "\"#{node.value}\""
  	when IdentifiedResource
    	return "<#{node.uri}>"
    when AnonymousResource
    	raise(WrapYarsError, "In #{__FILE__}:#{__LINE__}, Blank Nodes not implemented in yars adapter.")
    when Container
    	raise(WrapYarsError, "In #{__FILE__}:#{__LINE__}, container not implemented in yars adapter.")
    when Collection
    	raise(WrapYarsError, "In #{__FILE__}:#{__LINE__}, collection not implemented in yars adapter.")
    else
			raise(WrapYarsError, "In #{__FILE__}:#{__LINE__}, cannot unwrap unknown resource #{resource.class}.")
		end
	end
	
	# Parse the query result of Yars.
	#
	# Arguments:
	# * +query_result+ [<tt>String</tt>]: Query result of Yars to parse
	#
	# Return:
	# * [<tt>Array</tt>] Array of Array containing each extracted object of each line.
	def parse_yars_query_result(query_result)
		results = Array.new
		query_result.each_line do |line|
			scanner = StringScanner.new(line.strip)
			if scanner.match?(/\(\s*/)
				results << parse_bindings(scanner)
			else
				results << parse_n3_triple(scanner)
			end
		end
		return results
	end

	# Parse an N3 triple and extract each object.
	#
	# Arguments:
	# * +scanner+ [<tt>StringScanner</tt>]: The string scanner containing the triple
	#
	# Return:
	# * [<tt>Array</tt>] The triple instanciated in ActiveRDF object.
	def parse_n3_triple(scanner)
		# Match subject
		subject = match_subject(scanner)		
		scanner.scan(/\s*/)
		# Match predicate
		predicate = match_predicate(scanner)
		scanner.scan(/\s*/)
		# Match object
		object = match_object(scanner)
		scanner.scan(/\s*/)
		
		return [subject, predicate, object]
	end

	# Parse an Yars binding line result and extract each object.
	#
	# Arguments:
	# * +scanner+ [<tt>StringScanner</tt>]: The string scanner containing the binding line.
	#
	# Return:
	# * [<tt>Array</tt>] ActiveRDF object of the binding result.
	def parse_bindings(scanner)
		results = Array.new
	
		$logger.debug "Enter parse binding line: " + scanner.peek(15)
	
		if !scanner.scan(/\(\s*/)
			raise(NTriplesParsingYarsError, "Closing parenthesis missing: #{scanner.inspect}.")
		end		
	
		while !scanner.match?(/\)/) do
			results << match_object(scanner)
			scanner.scan(/\s*/)
		end
	
		if !scanner.scan(/\)\s*\./)
			raise(NTriplesParsingYarsError, "Opening parenthesis missing: #{scanner.inspect}.")
		end
		
		if results.size == 1
			return results.first
		else
			return results
		end
	end
  
	# Match and extract a N3 subject
	#
	# Arguments:
	# * +scanner+ [<tt>StringScanner</tt>]: The string scanner of the n3 triple
	#
	# Return:
	# * [<tt>Resource</tt>] ActiveRDF identified resource or anonymous resource.
	def match_subject(scanner)
		uri_pattern = /<([^>]+)>/
		bnode_pattern = /_:(\S+)/
		
		if scanner.match?(uri_pattern)
			scanner.scan(uri_pattern)
			return NodeFactory.create_identified_resource(scanner[1])
		elsif scanner.match?(bnode_pattern)
			scanner.scan(bnode_pattern)
			raise(NTriplesParsingYarsError, "Blank Node not implemented.")
			# check if id in local hash, otherwise create new blank node
			#return AnonymousResource.create
		else
			raise(NTriplesParsingYarsError, "Invalid subject: #{scanner.inspect}.")
		end  	
	end

	# Match and extract a N3 predicate
	#
	# Arguments:
	# * +scanner+ [<tt>StringScanner</tt>]: The string scanner of the n3 triple
	#
	# Return:
	# * [<tt>Resource</tt>] ActiveRDF identified resource. 
	def match_predicate(scanner)
		uri_pattern = /<([^>]+)>/
  	
		if scanner.match?(uri_pattern)
			scanner.scan(uri_pattern)
			return NodeFactory.create_identified_resource(scanner[1])
		else
			raise(NTriplesParsingYarsError, "Invalid predicate: #{scanner.inspect}.")
		end  	
	end

	# Match and extract a N3 object
	#
	# Arguments:
	# * +scanner+ [<tt>StringScanner</tt>]: The string scanner of the n3 triple
	#
	# Return:
	# * [<tt>Node</tt>] ActiveRDF node. 
	def match_object(scanner)
		uri_pattern = /<([^>]+)>/
		bnode_pattern = /_:(\S+)/
		literal_pattern = /"([^"]*)"/

		if scanner.match?(uri_pattern)
			scanner.scan(uri_pattern)
			return NodeFactory.create_identified_resource(scanner[1])
		elsif scanner.match?(bnode_pattern)
			scanner.scan(bnode_pattern)
			raise(NTriplesParsingYarsError, "Blank Node not implemented.")
			#return NodeFactory.create_anonymous_resource(scanner[1])
		elsif scanner.match?(literal_pattern)
			scanner.scan(literal_pattern)
			return NodeFactory.create_literal(scanner[1], 'literal type not implemented.')
		else
			raise(NTriplesParsingYarsError, "Invalid object: #{scanner.inspect}.")
		end  
	end
  
end
