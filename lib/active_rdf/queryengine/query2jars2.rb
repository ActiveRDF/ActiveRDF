require 'active_rdf'

# Translates abstract query into jars2 query.
# (ignores ASK queries)
class Query2Jars2
	def self.translate(query)
		str = ""
		if query.select?
			# concatenate each where clause using space: s p o
			# and then concatenate the clauses using dot: s p o . s2 p2 o2 .
			str << "#{query.where_clauses.collect{|w| w.collect{|w| '?'+w.to_s}.join(' ')}.join(" .\n")} ."
			# TODO: should we maybe reverse the order on the where_clauses? it depends 
			# on Andreas' answer of the best order to give to jars2. Users would 
			# probably put the most specific stuff first, and join to get the 
			# interesting information. Maybe we should not touch it and let the user 
			# figure it out.
		end
		
		$activerdflog.debug "Query2Jars2: translated #{query} to #{str}"
		return str
	end
end
