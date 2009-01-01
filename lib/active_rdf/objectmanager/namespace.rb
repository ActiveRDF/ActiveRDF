require 'active_rdf'

# Manages namespace abbreviations and expansions

class Namespace
  @@namespaces = Hash.new
  @@inverted_namespaces = Hash.new

  # registers a namespace prefix and its associated expansion (full URI)
  # e.g. :rdf and 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  def Namespace.register(prefix, fullURI)
		raise ActiveRdfError, 'prefix nor uri can be empty' if (prefix.to_s.empty? or fullURI.to_s.empty?)
    raise ActiveRdfError, "namespace uri should end with # or /" unless /\/|#/ =~ fullURI.to_s[-1..-1]
		$activerdflog.info "Namespace: registering #{fullURI} to #{prefix}"
    @@namespaces[prefix.to_sym] = fullURI.to_s
    @@inverted_namespaces[fullURI.to_s] = prefix.to_sym

    # enable namespace lookups through FOAF::name
    # if FOAF defined, add to it
    if Object.const_defined?(prefix.to_s.upcase)
      ns = Object.const_get(prefix.to_s.upcase)
    else
      # otherwise create a new module for it
      ns = Module.new  
      Object.const_set(prefix.to_s.upcase, ns)
    end

    # catch FOAF::name or all other lookups 
    class << ns
      def method_missing(method, *args)
        Namespace.lookup(self.to_s.downcase.to_sym, method)
      end

      def const_missing(klass)
        ObjectManager.construct_class(Namespace.lookup(self.to_s.downcase.to_sym, klass))
      end

      # make some builtin methods private because lookup doesn't work otherwise 
      # on e.g. RDF::type and FOAF::name
      [:type, :name, :id].each {|m| private(m) }
    end

    # return the namespace proxy object
    ns
  end

  # returns a resource whose URI is formed by concatenation of prefix and localname
  def Namespace.lookup(prefix, localname)
    RDFS::Resource.new(expand(prefix, localname))
  end

  # returns URI (string) formed by concatenation of prefix and localname
  def Namespace.expand(prefix, localname)
    prefix = prefix.downcase.to_sym if prefix.is_a?String
    @@namespaces[prefix.to_sym].to_s + localname.to_s if @@namespaces[prefix.to_sym]
  end

  # returns prefix (if known) for the non-local part of the URI,
  # or nil if prefix not registered
  def Namespace.prefix(obj)
    uri = obj.is_a?(RDFS::Resource) ? obj.uri : obj.to_s
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
  def Namespace.localname(obj)
    uri = obj.respond_to?(:uri) ? obj.uri : obj.to_s
    delimiter = uri.rindex(/#|\//)
    if delimiter.nil? or delimiter == uri.size-1
      uri
    else
      uri[delimiter+1..-1]
    end
  end

	# returns currently registered namespace abbreviations (e.g. :foaf, :rdf)
  def Namespace.abbreviations
		@@namespaces.keys
	end
end

Namespace.register(:rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
Namespace.register(:rdfs, 'http://www.w3.org/2000/01/rdf-schema#')
Namespace.register(:owl, 'http://www.w3.org/2002/07/owl#')
Namespace.register(:dc, 'http://purl.org/dc/elements/1.1/')
Namespace.register(:dcterms, 'http://purl.org/dc/terms/')
