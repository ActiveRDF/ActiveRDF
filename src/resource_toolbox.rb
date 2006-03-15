# = resource_toolbox.rb
#
# Extension of Class Resource with useful private class method.
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

require 'node_factory'

class Resource

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

  # Find all predicates for a resource from the schema definition
  # returns a hash containing from localname to full predicate URI (e.g. 
	# 'firstName' => 'http://foaf.org/firstName')  
	def self.find_predicates(class_uri)
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, class uri is nil.") if class_uri.nil?
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, class uri is not a Resource, it's a #{class_uri.class}.") if !class_uri.instance_of?(IdentifiedResource)

		predicates = Hash.new
		
		preds = Resource.find({ NamespaceFactory.get(:rdfs_domain) => class_uri })

	 	preds.each do |predicate|
			attribute = predicate.local_part
			predicates[attribute] = predicate.uri
			$logger.debug "found predicate #{attribute}"
		end unless preds.nil?

		preds = Resource.find({ NamespaceFactory.get(:rdfs_domain) => NamespaceFactory.get(:owl_thing) })
	 	preds.each do |predicate|
			attribute = predicate.local_part
			predicates[attribute] = predicate.uri
			$logger.debug "added OWL Thing predicate #{attribute}"
		end unless preds.nil?
		
		# Generate the query string
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(class_uri, NamespaceFactory.get(:rdfs_subclass), :o)
		
		# Execute the query
		qe.execute do |o|
			superclass = o
			superpredicates = find_predicates(superclass)
			predicates.update(superpredicates)			
		end

		return predicates				
	end

	
	# Remove all duplicate values and return an array if multiple values, nil if no value
	# or the single value.
	def self.return_distinct_results(results)
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, results array is nil.") if results.nil?
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, results is not an array.") if !results.kind_of?(Array)
		
		results.uniq!
		case results.size
  	when 0
    	return nil
  	when 1
    	return results.pop
    else
    	return results
		end
	end
		
end

