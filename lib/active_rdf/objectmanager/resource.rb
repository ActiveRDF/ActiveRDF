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

    def Resource.uri; class_uri.uri; end
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
    def Resource.to_literal_s
      raise ActiveRdfError, "emtpy RDFS::Resources not allowed" if self.uri.size == 0
      "<#{class_uri.uri}>"
    end

    # returns the predicates that have this resource as their domain (applicable
    # predicates for this resource)
    def Resource.predicates
      Query.new.distinct(:p).where(:p, RDFS::domain, class_uri).execute |
        Query.new.distinct(:p).where(class_uri, :p, :o).execute(:flatten=>false) || []
    end
    
    def Resource.instance_predicates
      class_uri.instance_predicates
    end

    # Find all resources of this type
    def Resource.find_all(options = {}, &blk)
      ResourceQuery.new(self,options.delete(:context)).execute(options,&blk)
    end
    
    # Find resources of this type, restricted by optional property args
    # see ResourceQuery usage
    def Resource.find_by(context = nil)
      ResourceQuery.new(self,context)
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
    def to_literal_s
      raise ActiveRdfError, "emtpy RDFS::Resources not allowed" if self.uri.size == 0
      "<#{uri}>"
    end
    def inspect
      if ConnectionPool.adapters.size > 0
        type = self.type
        if type and type.size > 0
          type = type.collect{|t| t.abbr }
          type = type.size > 1 ? type.inspect : type.first
        else
          type = self.class
        end
        if abbr?
          label = abbr
        else
          label = self.label
          label = 
            if label and label.size > 0
              if label.size == 1 then label.only
              elsif label.size > 1 then label.inspect
              end
            else uri
            end
        end
      else
        type = self.class
        label = self.uri
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
      ConnectionPool.write_adapter.add(self,RDF::type,self.class)
      self
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
      Query.new.distinct(:p).where(self,RDF::type,:t).where(:p,RDFS::domain,:t).execute | RDFS::Resource.predicates
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
        Query.new.distinct(:s).where(:s,RDFS::domain,self).execute | RDFS::Resource.predicates
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

# Catches namespaces for properties
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

# Search for resources of a given type, with given property restrictions.
# Usage:
#   ResourceQuery.new(TEST::Person).execute                                         # find all TEST::Person resources
#   ResourceQuery.new(TEST::Person).age.execute                                     # find TEST::Person resources that have the property age
#   ResourceQuery.new(TEST::Person).age(27).execute                                 # find TEST::Person resources with property matching the supplied value
#   ResourceQuery.new(TEST::Person).age(27,:context => context_resource).execute    # find TEST::Person resources with property matching supplied value and context 
#   ResourceQuery.new(TEST::Person).email('personal@email','work@email').execute    # find TEST::Person resources with property matching the supplied values
#   ResourceQuery.new(TEST::Person).email(['personal@email','work@email']).execute  # find TEST::Person resources with property matching the supplied values
#   ResourceQuery.new(TEST::Person).eye('blue').execute(:all_types => true)         # find TEST::Person resources with property matching the supplied value ignoring lang/datatypes
#   ResourceQuery.new(TEST::Person).eye(LocalizedString('blue','en')).execute       # find TEST::Person resources with property matching the supplied value 
#   ResourceQuery.new(TEST::Person).eye(:regex => /lu/).execute                     # find TEST::Person resources with property matching the specified regex
#   ResourceQuery.new(TEST::Person).eye(:lang => '@en').execute                     # find TEST::Person resources with property having the specified language
#   ResourceQuery.new(TEST::Person).age(:datatype => XSD::Integer).execute          # find TEST::Person resources with property having the specified datatype
#   ResourceQuery.new(RDFS::Resource).test::age(27).execute                         # find RDFS::Resources having the fully qualified property and value
#   ResourceQuery.new(TEST::Person).age(27).eye(LocalizedString('blue','en')).execute  # chain multiple properties together, ANDing restrictions 
class ResourceQuery
  private(:type)

  def initialize(type,context = nil)
    @ns = nil
    @type = type
    @query = Query.new.distinct(:s).where(:s,RDF::type,@type,context)
    @var_idx = -1
  end

  def execute(options = {}, &blk)
    if truefalse(options[:all_types])
      if @query.filter_clauses.values.any?{|operator,operand| operator == :lang or operator == :datatype}
        raise ActiveRdfError, "all_types may not be specified in conjunction with any lang or datatype restrictions"
      end
      @query = @query.dup.all_types
    end
    @query.execute(options, &blk)
  end
  
  def method_missing(ns_or_property, *values)
    options = values.extract_options!
    values.flatten!    
    
    # if the namespace has been seen, lookup the property 
    if @ns
      property = Namespace.lookup(@ns, ns_or_property)
      # fully qualified property found. clear the ns:name for next invocation
      @ns = nil
    elsif Namespace.abbreviations.include?(ns_or_property)
      # we store the ns:name for next method_missing invocation
      @ns = ns_or_property
      return self
    else
      # ns_or_property not a namespace, so must be an unqualified property
      property_str = ns_or_property.to_s
      property = @type.instance_predicates.find{|prop| Namespace.localname(prop) == property_str}
      raise ActiveRdfError, "no suitable predicate matching '#{property_str}' found. Maybe you are missing some schema information?" unless property
    end

    # restrict by values if provided
    if values.size > 0 then values.each do |value|
        @query.where(:s,property,value,options[:context])
      end
    # otherwise restrict by property occurance only
    else
      var = "rq#{@var_idx += 1}".to_sym
      @query.where(:s,property,var,options[:context])

      # add filters
      if options[:lang] && options[:datatype]
        raise ActiveRdfError, "only lang or datatype may be specified, not both"
      elsif options[:lang]
        @query.lang(var,options[:lang])
      elsif options[:datatype]
        @query.datatype(var,options[:datatype])
      end
      if options[:regex]
        @query.regex(var,options[:regex])
      end
    end

    self
  end

  def to_s
    @query.to_s
  end
end
