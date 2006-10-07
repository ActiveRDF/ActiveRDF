# Translates abstract query into jars2 query
# ignores ASK queries
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL
require 'active_rdf'
class Query2Jars2
	def self.translate(query)
		str = ""
		if query.select?
			# concatenate each where clause using space: s p o
			# and then concatenate the clauses using dot: s p o . s2 p2 o2 .
			str << "#{query.where_clauses.collect{|w| w.join(' ')}.join(" .\n")} ."
			# TODO: should we maybe reverse the order on the where_clauses? it depends 
			# on Andreas' answer of the best order to give to jars2. Users would 
			# probably put the most specific stuff first, and join to get the 
			# interesting information. Maybe we should not touch it and let the user 
			# figure it out.
		end
		str
	end
end
