# translates abstract query into SPARQL that can be executed on SPARQL-compliant data source
require 'singleton'

class Query2SPARQL
	include Singleton
	def translate(query)
		str = ""
		str << "SELECT DISTINCT #{query.select_clauses.join(' ')} "
		
		# concatenate each where clause using space (e.g. 's p o')
		# and concatenate the clauses using dot, e.g. 's p o . s2 p2 o2 .'		
		str << "WHERE { #{query.where_clauses.collect{|w| w.join(' ')}.join('. ')} .}"
	end
end