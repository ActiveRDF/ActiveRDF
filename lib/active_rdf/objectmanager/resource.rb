require 'active_rdf'
require 'objectmanager/object_manager'
require 'objectmanager/namespace'
require 'queryengine/query'
require 'instance_exec'

module RDFS
	# Represents an RDF resource and manages manipulations of that resource,
	# including data lookup (e.g. eyal.age), data updates (e.g. eyal.age=20),
	# class-level lookup (Person.find_by_name 'eyal'), and class-membership
	# (eyal.class ...Person).
  class RDFS::Resource
    
    include ResourceLike
    
    #####                     #####
    ##### class level methods #####
    #####                     #####
    
    class << self
      attr_accessor :class_uri
    end

    def Resource.uri
      if(class_uri == nil)
        puts "WAAAAAAAAAAAAAAAAAAAAAA  I am a #{self.name}"
      end
      class_uri.uri
    end
    def Resource.==(other)
      other.respond_to?(:uri) ? other.uri == self.uri : false
    end
    def Resource.eql?(other)
      self == other
    end
    # TODO: check if these are needed in the class
    # def Resource.eql?(other)
    #   self.hash == other.hash
    # end
    # alias :== :eql?
    # def Resource.===(other)
    #   super(other) || (other.is_a?(RDFS::Resource) and other.type.include?(self))
    # end

    def Resource.localname; Namespace.localname(self); end
    def Resource.to_literal_s; "<#{class_uri.uri}>"; end

    # returns the predicates that have this resource as their domain (applicable
    # predicates for this resource)
    def Resource.predicates
      Query.new.distinct(:p).where(:p, RDFS::domain, class_uri).execute |
        Query.new.distinct(:p).where(class_uri, :p, :o).execute(:flatten=>false) || []
    end

    # manages invocations such as Person.find_by_name, 
    # Person.find_by_foaf::name, Person.find_by_foaf::name_and_foaf::knows, etc.
    def Resource.method_missing(method, *args)
      if /find_by_(.+)/.match(method.to_s)
        ActiveRdfLogger::log_debug(self) { "constructing dynamic finder for #{method}" }

        # construct proxy to handle delayed lookups 
        # (find_by_foaf::name_and_foaf::age)
        proxy = DynamicFinderProxy.new($1, nil, *args)

        # if proxy already found a value (find_by_name) we will not get a more 
        # complex query, so return the value. Otherwise, return the proxy so that 
        # subsequent lookups are handled
        return proxy.value || proxy
      end
    end

    # returns array of all instances of this class (e.g. Person.find_all)
    # (always returns collection)
    def Resource.find_all(*args)
      find(:all, *args)
    end

    def Resource.find(*args)
      class_uri.find(*args)
    end

    # uri of the resource (for instances of this class: rdf resources)
    attr_reader :uri

    # creates new resource representing an RDF resource
    def initialize uri
      @uri = case uri
            # allow Resource.new(other_resource)
            when RDFS::Resource
             uri.uri
            # allow Resource.new('<uri>') by stripping out <>
            when /^<([^>]*)>$/
              $1
            # allow Resource.new('uri')
            when String
              uri
            else 
              raise ActiveRdfError, "cannot create resource <#{uri}>"
            end
    end

    # setting our own class uri to rdfs:resource
    # (has to be done after defining our RDFS::Resource.new
    # because it cannot be found in Namespace.lookup otherwise)
    self.class_uri = Namespace.lookup(:rdfs, :Resource)

    #####                         #####
    ##### instance level methods  #####
    #####                         #####

    # a resource is same as another if they both represent the same uri
    def ==(other);
      other.respond_to?(:uri) ? other.uri == self.uri : false
    end
    alias_method 'eql?','=='

    # overriding hash to use uri.hash
    # needed for array.uniq
    def hash; uri.hash; end

    # overriding sort based on uri
    def <=>(other); uri <=> other.uri; end

    alias :to_s :uri
    def to_literal_s; "<#{uri}>"; end
    def inspect
      type = self.type
      type = (type and type.size > 0) ? type.collect{|t| t.abbr } : self.class 
      if abbr?
        label = abbr
      else
        label = self.label
        label = (label and label.size > 0) ? label.inspect : uri
      end
      "#<#{type} #{label}>"
    end

    def abbreviation; [Namespace.prefix(uri).to_s, localname]; end

    # get an abbreviation from to_s
    # returns a copy of uri if no abbreviation found
    def abbr
      str = to_s
      (abbr = Namespace.abbreviate(str)) ? abbr : str
    end

    # checks if an abbrivation exists for this resource
    def abbr?
      Namespace.prefix(self) ? true : false
    end

    def to_xml
      base = Namespace.expand(Namespace.prefix(self),'').chop

      xml = "<?xml version=\"1.0\"?>\n"
      xml += "<rdf:RDF xmlns=\"#{base}\#\"\n"
      Namespace.abbreviations.each { |p| uri = Namespace.expand(p,''); xml += "  xmlns:#{p.to_s}=\"#{uri}\"\n" if uri != base + '#' }
      xml += "  xml:base=\"#{base}\">\n"

      xml += "<rdf:Description rdf:about=\"\##{localname}\">\n"
      direct_predicates.each do |p|
        objects = Query.new.distinct(:o).where(self, p, :o).execute
        objects.each do |obj|
          prefix, localname = Namespace.prefix(p), Namespace.localname(p)
          pred_xml = if prefix
                       "%s:%s" % [prefix, localname]
                     else
                       p.uri
                     end

          case obj
          when RDFS::Resource
            xml += "  <#{pred_xml} rdf:resource=\"#{obj.uri}\"/>\n"
          when LocalizedString
            xml += "  <#{pred_xml} xml:lang=\"#{obj.lang}\">#{obj}</#{pred_xml}>\n"
          else
            xml += "  <#{pred_xml} rdf:datatype=\"#{obj.xsd_type.uri}\">#{obj}</#{pred_xml}>\n"
          end
        end
      end
      xml += "</rdf:Description>\n"
      xml += "</rdf:RDF>"
    end

    def find(*args)
      # extract sort options from args
      options = args.extract_options!

      query = Query.new.distinct(:s)
      query.where(:s, RDF::type, self)

      if options.include? :order
        sort_predicate = options[:order]
        query.sort(:sort_value)
        query.where(:s, sort_predicate, :sort_value)
      end

      if options.include? :reverse_order
        sort_predicate = options[:reverse_order]
        query.reverse_sort(:sort_value)
        query.where(:s, sort_predicate, :sort_value)
      end

      if options.include? :where
        raise ActiveRdfError, "where clause should be hash of predicate => object" unless options[:where].is_a? Hash
        options[:where].each do |p,o|
          if options.include? :context
            query.where(:s, p, o, options[:context])
          else
            query.where(:s, p, o)
          end
        end
      else
        if options[:context]
          query.where(:s, :p, :o, options[:context])
        end
      end

      query.limit(options[:limit]) if options[:limit]
      query.offset(options[:offset]) if options[:offset]

      if block_given?
        query.execute do |resource|
          yield resource
        end
      else
        query.execute(:flatten => false)
      end
    end

    def localname
      Namespace.localname(self)
    end

    # Searches for property belonging to this resource. Returns RDF::Property. 
    # Replaces any existing values if method is an assignment: resource.prop=(new_value)
    def method_missing(method, *args)
      # possibilities:
      # 1. eyal.age is registered abbreviation 
      # evidence: age in @predicates
      # action: return RDF::Property(age,self) and store value if assignment
      #
      # 2. eyal.age is a custom-written method in class Person
      # evidence: eyal type ?c, ?c.methods includes age
      # action: return results from calling custom method 
      #
      # 3. eyal.foaf::name, where foaf is a registered abbreviation
      # evidence: foaf in Namespace.
      # action: return namespace proxy that handles 'name' invocation, by 
      # rewriting into predicate lookup (similar to case (1)
      #
      # 4. eyal.age is a property of eyal (triple exists <eyal> <age> "30")
      # evidence: eyal age ?a, ?a is not nil (only if value exists)
      # action: return RDF::Property(age,self) and store value if assignment
      #
      # 5. eyal's class is in the domain of age, but does not have value for eyal
      # evidence: eyal age ?a is nil and eyal type ?c, age domain ?c
      # action: return RDF::Property(age,self) and store value if assignment

      ActiveRdfLogger::log_debug(self) { "method_missing: #{method}" }

      # are we doing an update or not? 
			# checking if method ends with '='

      update = method.to_s[-1..-1] == '='
      methodname = update ? method.to_s[0..-2] : method.to_s

      # check possibility (1)
      if @predicates and @predicates.include?(methodname)
        property = RDF::Property.new(@predicates[methodname],self)
        property.replace(args) if update
        return property
      end

      # check possibility (2)
      self.type.each do |klass|
        klass = ObjectManager.construct_class(klass)
        if klass.instance_methods.include?(method.to_s)
          _dup = klass.new(uri)
          return _dup.send(method,*args)
        end
      end

      # check possibility (3)
			if Namespace.abbreviations.include?(methodname.to_sym)
        # catch the invocation on the namespace
        return PropertyNamespaceProxy.new(methodname,self)
      end

      # checking possibility (4) and (5)
      pred = all_predicates.find{|pred| Namespace.localname(pred) == methodname}
      if pred
        property = RDF::Property.new(pred, self)
        property.replace(*args) if update
        return property
      end

      raise ActiveRdfError, "could not set #{methodname} to #{args}: no suitable predicate found. Maybe you are missing some schema information?" if update

			# if none of the three possibilities work out, we don't know this method
			# invocation, but we don't want to throw NoMethodError, instead we return
			# nil, so that eyal.age does not raise error, but returns nil. (in RDFS,
			# we are never sure that eyal cannot have an age, we just dont know the
			# age right now)
			nil
		end

		# saves instance into datastore
		def save
			db = ConnectionPool.write_adapter
			Query.new.distinct(:p,:o).where(self, :p, :o).execute do |p, o|
				db.add(self, p, o)
			end
		end

		# returns an RDF::Property for RDF::type's of this resource, e.g. [RDFS::Resource, FOAF::Person]
		#
		# Note: this method performs a database lookup for { self rdf:type ?o }.
		# For simple type-checking (to know if you are handling an ActiveRDF object,
		# use self.class, which does not do a database query, but simply returns 
		# RDFS::Resource.
    def type
      RDF::Property.new(RDF::type, self)
    end

    # overrides built-in instance_of? to use rdf:type definitions
    def instance_of?(klass)
      self.type.include?(klass.respond_to?(:class_uri) ? klass.class_uri : klass) || self.class.ancestors.include?(klass)
    end

    # define a localname for a predicate URI
    #
    # localname should be a Symbol or String, fulluri a Resource or String, e.g. 
    # register_predicate(:name, FOAF::lastName)
    def register_predicate(localname, fulluri)
			localname = localname.to_s
			fulluri = RDFS::Resource.new(fulluri) if fulluri.is_a? String

			# predicates is a hash from abbreviation string to full uri resource
      (@predicates ||= {})[localname] = fulluri
		end

		# returns all predicates that fall into the domain of the rdf:type of this
		# resource
		def class_predicates
      Query.new.distinct(:p).where(self,RDF::type,:t).where(:p,RDFS::domain,:t).execute(:flatten=>false) | RDFS::Resource.predicates
		end
    alias class_level_predicates class_predicates

		# returns all predicates that are directly defined for this resource
    def direct_predicates
      Query.new.distinct(:p).where(self,:p,:o).execute(:flatten=>false)
		end

    def all_predicates
      direct_predicates | class_predicates
    end
  
		def property_accessors
      all_predicates.collect {|pred| Namespace.localname(pred) }
		end

    # like class_predicates, but returns predicates for this class instead of parent class for resources of type RDFS::Class or OWL::Class
    def instance_predicates
      if type.any?{|t| t == RDFS::Class or t == OWL::Class}
        if instance_of?(RDFS::Resource)
          Query.new.distinct(:s).where(:s,RDFS::domain,self).execute(:flatten=>false) | RDFS::Resource.predicates
        else
          self.class.predicates
        end
      else
        all_predicates
      end
    end

    # returns array containing predicates that do not have a value
    def empty_predicates
      all_predicates.reject{|pred| pred.size > 0}.uniq
    end

    def new_record?
      Query.new.count(:p).where(self,:p,:o).execute == 0
    end
	end
end

class PropertyNamespaceProxy
  def initialize(ns, subject)
    @ns = ns
    @subject = subject
  end
  def method_missing(localname, *values)
    update = localname.to_s[-1..-1] == '='
    localname = update ? localname.to_s[0..-2] : localname.to_s

    property = RDF::Property.new(Namespace.lookup(@ns, localname),@subject)
    property.replace(*values) if update
    property
  end
  private(:type)
end

# proxy to manage find_by_ invocations
class DynamicFinderProxy
  @ns = nil
  @where = nil
  @value = nil
  attr_reader :value
  private(:type)

  # construct proxy from find_by text
  # foaf::name
  def initialize(find_string, where, *args)
    @where = where || []
    parse_attributes(find_string, *args)
  end

  def method_missing(method, *args)
    # we store the ns:name for later (we need to wait until we have the 
    # arguments before actually constructing the where clause): now we just 
    # store that a where clause should appear about foaf:name

    # if this method is called name_and_foaf::age we add ourself to the query
    # otherwise, the query is built: we execute it and return the results
    if method.to_s.include?('_and_')
      parse_attributes(method.to_s, *args)
    else
      @where << Namespace.lookup(@ns, method.to_s)
      query(*args)
    end
  end

  private 
  # split find_string by occurrences of _and_
  def parse_attributes string, *args
    attributes = string.split('_and_')
    attributes.each do |atr|
      # attribute can be:
      # - a namespace prefix (foaf): store prefix in @ns to prepare for method_missing
      # - name (attribute name): store in where to prepare for method_missing
      if Namespace.abbreviations.include?(atr.to_sym)
        @ns = atr.to_s.downcase.to_sym
      else
        # found simple attribute label, e.g. 'name'
        # find out candidate (full) predicate for this localname: investigate 
        # all possible predicates and select first one with matching localname
        candidates = Query.new.distinct(:p).where(:s,:p,:o).execute
        @where << candidates.select {|cand| Namespace.localname(cand) == atr}.first
      end
    end

    # if the last attribute was a prefix, return this dynamic finder (we'll 
    # catch the following method_missing and construct the real query then)
    # if the last attribute was a localname, construct the query now and return 
    # the results
    if Namespace.abbreviations.include?(attributes.last.to_sym)
      return self
    else
      return query(*args)
    end
  end

  # construct and execute finder query
  def query(*args)
    # extract options from args or use an empty hash (no options given)
    options = args.last.is_a?(Hash) ? args.last : {}

    # build query 
    query = Query.new.distinct(:s)
    @where.each_with_index do |predicate, i|
      # specify where clauses, use context if given
      if options[:context]
        query.where(:s, predicate, args[i], options[:context])
      else
        query.where(:s, predicate, args[i])
      end
    end

    # use sort order if given
    if options.include? :order
      sort_predicate = options[:order]
      query.sort(:sort_value)
      # add sort predicate where clause unless we have it already
      query.where(:s, sort_predicate, :sort_value) unless @where.include? sort_predicate
    end

    if options.include? :reverse_order
      sort_predicate = options[:reverse_order]
      query.reverse_sort(:sort_value)
      query.where(:s, sort_predicate, :sort_value) unless @where.include? sort_predicate
    end

    query.limit(options[:limit]) if options[:limit]
    query.offset(options[:offset]) if options[:offset]

    ActiveRdfLogger::log_debug(self) { "executing dynamic finder: #{query.to_sp}" }

    # store the query results so that caller (Resource.method_missing) can 
    # retrieve them (we cannot return them here, since we were invoked from 
    # the initialize method so all return values are ignored, instead the proxy 
    # itself is returned)
    @value = query.execute
    return @value
  end
end
