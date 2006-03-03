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
# == To-do
#
# * To-do 1
#

require 'set'
require 'adapter/yars/yars_exceptions.rb'

class YarsAdapter; implements AbstractAdapter
  
  private

  # Convert n3 resource and literal into ActiveRDF::Resource or String
	def unwrap(resource)
		case resource
		when /"(.*)"/
			return $1
		when /<(.*)>/
			return Resource.new($1)
		else
			raise(WrapNTriplesError, "cannot wrap unknown resource #{resource.class}")
		end
	end

  # Convert ActiveRDF::Resource or String into n3 resource and literal
	def wrap(resource)
		case resource
    when NilClass
    	return nil
  	when String
    	return "\"#{resource}\""
  	when Resource
    	return "<#{resource.uri}>"
    else
			raise(WrapNTriplesError, "cannot unwrap unknown resource #{resource.class}")
		end
	end

	def count_n3 triples
		s = Set.new
		triples.each_line { |line|
			s << line
		}
		return s.size
	end

	ResourcePattern = /<(.+)>/
	BnodePattern = /_:(\S+)/
	Subj = Regexp.union ResourcePattern, BnodePattern
	LiteralPattern = /"(.*)"/
	Obj = Regexp.union Subj, LiteralPattern
	NTriple = /^\s*#{Subj}\s+#{ResourcePattern}\s+#{Obj}\s*\.$/
		# $1 is uri subj
		# $2 is blank subj
		# $3 is pred
		# $4 is uri obj
		# $5 is blank obj
		# $6 is literal obj
	
	def parse_n3 triples
		result = []
		bnodes = {}
		triples.each_line do |triple|
			if triple =~ NTriple
				unless $1.nil?
					# subject is a URI
					subj = Resource.create $1
				else
					# subject is a bnode
					subj = BNode.create $2
					bnodes[$2] = subj
				end

				pred = Resource.create $3

				if !$4.nil?
					# object is a URI
					obj = Resource.create $4
				elsif !$6.nil?
					# object is a literal
					obj = Literal.create $6
				else
					# object is a bnode
					obj = bnodes[$5]
				end
				result << [subj, pred, obj]
			else
				raise(NTriplesParsingYarsError, 'returned triple not readable: ' + triple)
			end
		end
		return result
	end
  
end
