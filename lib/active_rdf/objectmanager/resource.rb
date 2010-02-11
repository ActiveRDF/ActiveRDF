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
    #####                     #####
    ##### class level methods #####
    #####                     #####

    class << self
      attr_accessor :class_uri
    end

    def Resource.uri
      class_uri.uri
    end

    def Resource.==(other)
      other.respond_to?(:uri) ? other.uri == self.uri : false
    end

    def Resource.eql?(other)
      self == other
    end

    def Resource.localname
      Namespace.localname(self)
    end

    # returns the predicates that have this resource as their domain (applicable
    # predicates for this resource)
    def Resource.predicates
      class_uri.instance_predicates
    end

    def Resource.properties
      predicates.collect{|prop| RDF::Property.new(prop)}
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

    # Find an existing resource with the given uri, otherwise returns nil
    def Resource.find(uri)
      res = Resource.new(uri)
      res unless res.new_record?
    end

    # Pass all other methods to class_uri
    def Resource.method_missing(method,*args)
      class_uri.send(method,*args)
    end

    # uri of the resource (for instances of this class: rdf resources)
    attr_reader :uri

    # creates new resource representing an RDF resource
    def initialize(uri_or_resource)
      @uri = case uri_or_resource
             # allow Resource.new(other_resource)
             when RDFS::Resource
               uri_or_resource.uri
              # allow Resource.new('<uri>') by stripping out <>
             when /^<([^>]*)>$/
               $1
             # allow Resource.new('uri')
             when String
               uri_or_resource
             else
               raise ActiveRdfError, "cannot create resource <#{uri_or_resource}>"
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
    def hash
      uri.hash
    end

    # overriding sort based on uri
    def <=>(other)
      uri <=> other.uri
    end

    def is_a?(klass)
      super || ObjectManager.construct_class(klass) == self
    end

    def instance_of?(klass)
      if super
        true
      else
        klass = ObjectManager.construct_class(klass)
        is_a?(klass) || classes.include?(klass)
      end
    end
    alias :kind_of? :instance_of?

    def new_record?
      Query.new.count(:p).where(self,:p,:o).execute == 0
    end

    # saves instance into datastore
    def save
      ConnectionPool.write_adapter.add(self,RDF::type,self.class)
      self
    end

    def abbreviation
      [Namespace.prefix(uri).to_s, localname]
    end

    # get an abbreviation from to_s
    # returns a copy of uri if no abbreviation found
    def abbr
      (abbr = Namespace.abbreviate(uri)) ? abbr : uri
    end

    # checks if an abbrivation exists for this resource
    def abbr?
      Namespace.prefix(self) ? true : false
    end

    def localname
      Namespace.localname(self)
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

    def type=(type)
      RDF::Property.new(RDF::type, self).replace(type)
    end

    # returns array of Classes for all types
    def classes
      type.collect{|type_res| ObjectManager.construct_class(type_res)}
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

    # returns array of RDFS::Resources for properties that belong to this resource
    def class_predicates
      Query.new.distinct(:p).where(:p,RDFS::domain,:t).where(self,RDF::type,:t).execute
    end
    alias class_level_predicates class_predicates

    # returns array of RDF::Propertys for properties that belong to this resource
    def class_properties
      class_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    # returns array of RDFS::Resources for properties that are directly defined for this resource
    def direct_predicates
      Query.new.distinct(:p).where(self,:p,:o).execute
    end

    # returns array of RDF::Propertys that are directly defined for this resource
    def direct_properties
      direct_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    # returns array of RDFS::Resources for all known properties of this resource
    def predicates
      direct_predicates | class_predicates
    end

    # returns array of RDF::Propertys for all known properties of this resource
    def properties
      predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    # for resources of type RDFS::Class, returns array of RDFS::Resources for the known properties of their objects
    def instance_predicates
      ip = Query.new.distinct(:p).where(:p,RDFS::domain,self).execute
      if ip.size > 0
        ip |= Query.new.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties
      else []
      end
    end

    # for resources of type RDFS::Class, returns array of RDF::Propertys for the known properties of their objects
    def instance_properties
      instance_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    # returns array RDFS::Resources for known properties that do not have a value
    def empty_predicates
      predicates.reject{|pred| pred.size > 0}.uniq
    end

    # returns array RDF::Propertys for known properties that do not have a value
    def empty_properties
      empty_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    if $activerdf_internal_reasoning
      # Redefine and add methods that perform some limited RDF & RDFS reasoning

      # returns array of RDFS::Resources for the class properties of this resource, including those of its supertypes
      def class_predicates
        types.inject([]){|class_preds,type| class_preds |= type.instance_predicates}
      end

      # for resources of type RDFS::Class, returns array of RDFS::Resources for the known properties of their objects, including those of its supertypes
      def instance_predicates
        ip = Query.new.distinct(:s).where(:s,RDFS::domain,self).execute
        ip |= ip.collect{|p| p.super_predicates}.flatten
        ip |= super_types.collect{|type| type.instance_predicates}.flatten
        ip |= Query.new.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties
        ip
      end

      # for resources of type RDFS::Property, returns array of RDFS::Resources for all properties that are super properties defined by RDFS::subPropertyOf
      def super_predicates
        sp = []
        Query.new.distinct(:superproperty).where(self,RDFS::subPropertyOf,:superproperty).execute.each do |superproperty|
          sp |= [superproperty]
          sp |= superproperty.super_predicates
        end
        sp
      end

      # for resources of type RDFS::Class, returns array of RDFS::Resources for all super types defined by RDF::subClassOf
      def super_types
        st = []
          Query.new.distinct(:superklass).where(self,RDFS::subClassOf,:superklass).execute.each do |supertype|
            st |= [supertype]
            st |= supertype.super_types
          end
        st
      end

      # for resources of type RDFS::Class, returns array of classes for all super types defined by RDF::subClassOf
      # otherwise returns empty array
      def super_classes
        super_types.collect{|type_res| ObjectManager.construct_class(type_res)}
      end

      # returns array of RDFS::Resources for all types, including supertypes
      def types
        types = self.type.to_a
        types |= types.collect{|type| type.super_types}.flatten
        types |= [RDFS::Resource.class_uri]   # all resources are subtype of RDFS::Resource
        types
      end

      # returns array of Classes for all types, including supertypes
      def classes
        types.collect{|type_res| ObjectManager.construct_class(type_res)}
      end
    end

    alias :to_s :uri
    def to_literal_s
      raise ActiveRdfError, "emtpy RDFS::Resources not allowed" if self.uri.size == 0
      "<#{uri}>"
    end

    def inspect
      if ConnectionPool.adapters.size > 0
        type =
          if (t = self.type) and t.size > 0
            t = t.collect{|res| res.abbr }
            t.size > 1 ? t.inspect : t.first
          else
            self.class
          end
        label =
          if abbr?
            abbr
          elsif (l = self.label) and l.size > 0
            if l.size == 1 then l.only
            else l.inspect
            end
          else
            uri
          end
      else
        type = self.class
        label = self.uri
      end
      "#<#{type} #{label}>"
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

      # check for registered abbreviation
      if @predicates and @predicates.include?(methodname)
        property = RDF::Property.new(@predicates[methodname],self)
        property.replace(args) if update
        return property
      end

      # check for custom written method
      classes.each do |klass|
        if klass.instance_methods.include?(method.to_s)
          _dup = klass.new(uri)
          return _dup.send(method,*args)
        end
      end

      # check for registered namespace
      if Namespace.abbreviations.include?(methodname.to_sym)
        # catch the invocation on the namespace
        return PropertyNamespaceProxy.new(methodname,self)
      end

      # check for known property
      property = properties.find{|prop| Namespace.localname(prop) == methodname}
      if property
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
