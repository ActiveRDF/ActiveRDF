# Author:: Benjamin Heitmann
# Copyright:: (c) 2005-2006 
# License:: LGPL

require 'active_rdf'
require 'queryengine/query2sparql'

# generic superclass of all adapters
class ActiveRdfAdapter

	# translate a query to its string representation
	def translate(query)
	 	Query2SPARQL.translate(query)
	end
	
end