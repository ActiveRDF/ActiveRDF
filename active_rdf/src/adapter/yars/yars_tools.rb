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
	Uri_pattern = /<([^>]+)>/
	Bnode_pattern = /_:(\S+)/
	
	#literal can be either "abc" (without any quote inside), or it 
	#can be "abc\"def" (with an escaped quote inside)
	#thus, allowed characters inside the quote is either \" or anything but "
	Literal_characters = /\\"|[^"]/
	Literal_pattern = /"(#{Literal_characters}*)"/

  
	private

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
			$logger.debug "parsing result: #{line}"
			scanner = StringScanner.new(line.strip)
			if scanner.match?(/\(\s*/)
				results << parse_bindings(scanner)
			else
				results << parse_n3_triple(scanner)
			end
		end
		return results
	end

	Space = /\s*/

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
		scanner.scan Space
		# Match predicate
		predicate = match_predicate(scanner)
		scanner.scan Space
		# Match object
		object = match_object(scanner)
		scanner.scan Space
		
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
	
		if !scanner.scan(/\(\s*/)
			raise(NTriplesParsingYarsError, "Closing parenthesis missing: #{scanner.inspect}.")
		end		
	
		while !scanner.match?(/\)/) do
			results << match_object(scanner)
			scanner.scan Space
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
		if scanner.match?(Uri_pattern)
			scanner.pos += scanner.matched.size
			return IdentifiedResource.create(scanner[1])
		elsif scanner.match?(Bnode_pattern)
			scanner.pos += scanner.matched.size
			raise(NTriplesParsingYarsError, "Blank Node not implemented.")
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
		if scanner.match?(Uri_pattern)
			scanner.pos += scanner.matched.size
			return IdentifiedResource.create(scanner[1])
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
		if scanner.match?(Uri_pattern)
			# progressing scanner pointer past matched pattern
			scanner.pos += scanner.matched.size
			return IdentifiedResource.create(scanner[1])
		elsif scanner.match?(Bnode_pattern)
			# BNodes not implemented yet
			raise(NTriplesParsingYarsError, "Blank Node not implemented.")
		elsif scanner.match?(Literal_pattern)
			# progressing scanner pointer past matched pattern
			scanner.pos += scanner.matched.size
			return Literal.create(scanner[1])
		else
			raise(NTriplesParsingYarsError, "Invalid object: \"#{scanner.string}\".")
		end  
	end
  
end
