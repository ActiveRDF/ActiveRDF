# = resource_toolbox.rb
#
# Module which extend the Class Resource with useful private class method.
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

module ResourceToolbox

	protected

  # Find all predicates for a resource from the schema definition
  # returns a hash containing from localname to full predicate URI (e.g. 
	# 'firstName' => 'http://foaf.org/firstName')  
	def find_predicates(resource)
		# Load URI constants
		require 'misc/constant_uri'
	
		predicates = Hash.new
		
		preds = Resource.find({ RDFSDomain => resource })

	 	preds.each do |predicate|
			attribute = get_local_part(predicate)
			predicates[attribute] = predicate.uri
			$logger.debug "found predicate #{attribute}"
		end unless preds.nil?

		preds = Resource.find({ RDFSDomain => OwlThing })
	 	preds.each do |predicate|
			attribute = get_local_part(predicate)
			predicates[attribute] = predicate.uri
			$logger.debug "added OWL Thing predicate #{attribute}"
		end unless preds.nil?
		
		# Generate the query string
		qe = QueryEngine.new
		qe.add_binding_triple(resource, RDFSSubClassOf, :o)
		qe.add_condition(resource, RDFSSubClassOf, :o)
		
		# Execute the query
		qe.execute do |s, p, o|
			superclass = o
			superpredicates = find_predicates(superclass)
			predicates.update(superpredicates)			
		end

		return predicates				
	end
	
  # Extract the local part of a URI
  #
  # * +resource+: ActiveRDF::Resource representing the URI
  # * returns string with local part of the URI
	def get_local_part(resource)
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, resource is nil.") if resource.nil?
		raise(ResourceTypeError, "In #{__FILE__}:#{__LINE__}, not a resource.") if !resource.kind_of?(Resource)
		
		uri = resource.uri
		delimiter = uri.rindex(/#|\//)
		
		# if no delimiter available then uri is broken
		str_error = "In #{__FILE__}:#{__LINE__}, uri is broken ('#{uri}')."
		raise(UriBrokenError, str_error) if delimiter.nil?
		
		return uri[delimiter+1..uri.size]			
	end
	
	# Remove all duplicate values and return an array if multiple values, nil if no value
	# or the single value.
	def return_distinct_results(results)
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

