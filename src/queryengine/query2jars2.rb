# translates abstract query into jars2 query
# ignores ASK queries
class Query2Jars2
	def self.translate(query)
		str = ""
		if query.select?
			# concatenate each where clause using space: s p o
			# and then concatenate the clauses using dot: s p o . s2 p2 o2 .
			str << "#{query.where_clauses.collect{|w| w.join(' ')}.join(".\n")} ."
		end
		str
	end
end
