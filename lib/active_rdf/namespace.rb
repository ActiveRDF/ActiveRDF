# Manages namespace abbreviations and expansions
module ActiveRDF
  class Namespace
    @@namespaces = Hash.new
    @@inverted_namespaces = Hash.new

    # registers a namespace prefix and its associated expansion (full URI)
    # e.g. :rdf and 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    def Namespace.register(prefix, fullURI)
      raise ActiveRdfError, 'prefix nor uri can be empty' if (prefix.to_s.empty? or fullURI.to_s.empty?)
      raise ActiveRdfError, "namespace uri should end with # or /" unless /\/|#/ =~ fullURI.to_s[-1..-1]
      klass_name = prefix.to_s.upcase
      prefix = prefix.to_s.downcase.to_sym
      ActiveRdfLogger::log_info(self) { "Namespace: registering #{fullURI} to #{klass_name}" }
      @@namespaces[prefix] = fullURI.to_s
      @@inverted_namespaces[fullURI.to_s] = prefix

      # enable namespace lookups through FOAF::name
      # if FOAF defined, extend it
      if Object.const_defined?(klass_name)
        ns = Object.const_get(klass_name)
      else
        # otherwise create a new module for it
        ns = Module.new
        Object.const_set(klass_name, ns)
      end
      ns.extend NamespaceProxy
      ns.prefix = prefix
      ns
    end

    # returns currently registered namespace abbreviations (e.g. :foaf, :rdf)
    def Namespace.abbreviations
      @@namespaces.keys
    end

    def Namespace.include?(name)
      @@namespaces.keys.include?(name.to_s.downcase.to_sym)
    end

    # like include?, but returns the key for the namespace
    def Namespace.find(name)
      name = name.to_s.downcase.to_sym
      @@namespaces.keys.find{|k| k == name}
    end

    # returns a resource whose URI is formed by concatenation of prefix and localname
    def Namespace.lookup(prefix, localname)
      RDFS::Resource.new(expand(prefix, localname))
    end

    # returns URI (string) formed by concatenation of prefix and localname
    def Namespace.expand(prefix, localname)
      prefix = prefix.downcase if prefix.is_a?String
      prefix = prefix.to_sym
      @@namespaces[prefix].to_s + localname.to_s if @@namespaces[prefix]
    end

    # returns prefix (if known) for the non-local part of the URI,
    # or nil if prefix not registered
    def Namespace.prefix(obj)
      uri = obj.respond_to?(:uri) ? obj.uri : obj.to_s
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

    # abbreviates resource if namespace is registered, otherwise returns nil
    def Namespace.abbreviate(obj)
      uri = obj.to_s
      # uri.to_s gives us the uri of the resource (if resource given)
      # then we find the last occurrence of # or / (heuristical namespace
      # delimitor)
      delimiter = uri.rindex(/#|\//)

      if delimiter.nil? or delimiter == uri.size-1
        abbr = @@inverted_namespaces[uri]
        abbr.to_s if (abbr)
      else
        abbr = @@inverted_namespaces[uri[0..delimiter]]
        abbr.to_s.upcase + "::" + uri[delimiter+1..-1] if (abbr)
      end
    end
  end

  module NamespaceProxy
    attr_accessor :prefix, :klasses, :resources

    def NamespaceProxy.extend_object(obj)
      # make some builtin methods private because lookup doesn't work otherwise
      # on e.g. RDF::type and FOAF::name
      class << obj
        [:type, :name, :id].each {|m| private(m) if respond_to?(m)}
      end
      super
    end

    # catch FOAF::name.
    def method_missing(method, *args)
      @resources ||={}  # resource cache
      @resources[method] ||= Namespace.lookup(@prefix, method)
    end

    # catch FOAF::Person
    def const_missing(klass)
      ActiveRdfLogger::log_info(self) { "Const missing on Namespace #{klass}" }
      @klasses ||={}  # class cache
      @klasses[klass] ||= ObjectManager.construct_class(Namespace.lookup(@prefix, klass))
    end

  end

  Namespace.register(:rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
  Namespace.register(:rdfs, 'http://www.w3.org/2000/01/rdf-schema#')
  Namespace.register(:owl, 'http://www.w3.org/2002/07/owl#')
  Namespace.register(:dc, 'http://purl.org/dc/elements/1.1/')
  Namespace.register(:dcterms, 'http://purl.org/dc/terms/')
end