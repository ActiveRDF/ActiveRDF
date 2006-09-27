# manages namespace abbreviations and expansions

require 'singleton'
class Namespace
  include Singleton
  
  @@namespaces = Hash.new 
	@@inverted_namespaces = Hash.new

	# registers a namespace prefix and its associated expansion (full URI)
	# e.g. :rdf and 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	def register(prefix, fullURI)
		@@namespaces[prefix.to_sym] = fullURI.to_s
		@@inverted_namespaces[fullURI.to_s] = prefix.to_sym
	end
	
	# returns a resource whose URI is formed by concatenation of prefix and localname
  def lookup(prefix, localname)
    RDFS::Resource.lookup(expand(prefix, localname))
	end
	
	# returns URI (string) formed by concatenation of prefix and localname
	def expand(prefix, localname)
		@@namespaces[prefix.to_sym].to_s + localname.to_s
	end

	# returns prefix (if known) for the non-local part of the URI, 
	# or nil if prefix not registered
	def prefix(resource)
		# get string representation of resource uri
		uri = case resource
			when RDFS::Resource: resource.uri
			else resource.to_s
		end

		# uri.to_s gives us the uri of the resource (if resource given)
		# then we find the last occurrence of # or / (heuristical namespace 
		# delimitor)
		delimiter = uri.rindex(/#|\//)

		# if delimiter not found, URI cannot be split into (non)local-part
		return uri if delimiter.nil?

		# extract non-local part (including delimiter)
		nonlocal = uri[0..delimiter]

		@@inverted_namespaces[nonlocal]
	end
	
	# returns local-part of URI
	def localname(resource)
	  # get string representation of resource uri
		uri = case resource
			when RDFS::Resource: resource.uri
			else resource.to_s
		end
	 	
		delimiter = uri.rindex(/#|\//)
		if delimiter.nil?
			uri
		else
			uri[delimiter+1..-1]
		end
	end
end

Namespace.instance.register(:rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
Namespace.instance.register(:rdfs, 'http://www.w3.org/2000/01/rdf-schema#')