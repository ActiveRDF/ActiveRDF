require 'active_rdf/model/object_manager'
require 'active_rdf/namespace'
require 'active_rdf/query/query'

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
      ActiveRDF::Namespace.localname(self)
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
      ActiveRDF::ResourceQuery.new(self,options.delete(:context)).execute(options,&blk)
    end

    # Find resources of this type, restricted by optional property args
    # see ActiveRDF::ResourceQuery usage
    def Resource.find_by(context = nil)
      ActiveRDF::ResourceQuery.new(self,context)
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
    # because it cannot be found in ActiveRDF::Namespace.lookup otherwise)
    self.class_uri = ActiveRDF::Namespace.lookup(:rdfs, :Resource)

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
      klass = ActiveRDF::ObjectManager.construct_class(klass)
      super || types.any?{|t| klass == t}
    end

    def instance_of?(klass)
      klass = ActiveRDF::ObjectManager.construct_class(klass)
      super || direct_types.any?{|t| klass == t}
    end

    def new_record?
      !ActiveRDF::Query.new.ask.where(self,:p,:o).execute
    end

    # saves instance into datastore
    def save
      ActiveRDF::ConnectionPool.write_adapter.add(self,RDF::type,self.class)
      self
    end

    def abbreviation
      [ActiveRDF::Namespace.prefix(uri).to_s, localname]
    end

    # get an abbreviation from to_s
    # returns a copy of uri if no abbreviation found
    def abbr
      (abbr = ActiveRDF::Namespace.abbreviate(uri)) ? abbr : uri
    end

    # checks if an abbrivation exists for this resource
    def abbr?
      ActiveRDF::Namespace.prefix(self) ? true : false
    end

    def localname
      ActiveRDF::Namespace.localname(self)
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

    def types
      type.to_a | [RDFS::Resource.class_uri]  # all resources are subtype of RDFS::Resource
    end
    alias :direct_types :types

    # returns array of Classes for all types
    def classes
      types.collect{|type_res| ActiveRDF::ObjectManager.construct_class(type_res)}
    end

    # TODO: remove
    # define a localname for a predicate URI
    #
    # localname should be a Symbol or String, fulluri a Resource or String, e.g.
    # register_predicate(:name, FOAF::lastName)
    def register_predicate(localname, fulluri)
      warn "Registered predicates is deprecated. Please use registered namespaces instead."
      localname = localname.to_s
      fulluri = RDFS::Resource.new(fulluri) if fulluri.is_a? String

      # predicates is a hash from abbreviation string to full uri resource
      (@predicates ||= {})[localname] = fulluri
    end

    # returns array of RDFS::Resources for properties that belong to this resource
    def class_predicates
      ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,:t).where(self,RDF::type,:t).execute |
        ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties
    end
    alias class_level_predicates class_predicates

    # returns array of RDF::Propertys for properties that belong to this resource
    def class_properties
      class_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    # returns array of RDFS::Resources for properties that are directly defined for this resource
    def direct_predicates
      ActiveRDF::Query.new.distinct(:p).where(self,:p,:o).execute
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

    # returns array RDFS::Resources for known properties that do not have a value
    def empty_predicates
      empty_properties.collect{|prop| RDFS::Resource.new(prop)}
    end

    # returns array RDF::Propertys for known properties that do not have a value
    def empty_properties
      properties.reject{|prop| prop.size > 0}
    end

    # for resources of type RDFS::Class, returns array of RDFS::Resources for the known properties of their objects
    def instance_predicates
      ip = ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,self).execute
      if ip.size > 0
        ip |= ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties
      else []
      end
    end

    # for resources of type RDFS::Class, returns array of RDF::Propertys for the known properties of their objects
    def instance_properties
      instance_predicates.collect{|prop| RDF::Property.new(prop,self)}
    end

    def contexts
      ActiveRDF::Query.new.distinct(:c).where(self,nil,nil,:c).execute
    end

    if $activerdf_internal_reasoning
      # Add support for some limited RDFS reasoning

      ### Overidden methods

      # returns array of RDFS::Resources for all types, including supertypes
      def types
        types = self.type.to_a
        types |= types.collect{|type| type.super_types}.flatten
        types |= [RDFS::Resource.class_uri]   # all resources are subtype of RDFS::Resource
        types
      end

      # returns array of RDFS::Resources for the class properties of this resource, including those of its supertypes
      def class_predicates
        types.inject([]){|class_preds,type| class_preds |= type.instance_predicates}
      end

      # for resources of type RDFS::Class, returns array of RDFS::Resources for the known properties of their objects, including those of its supertypes
      def instance_predicates
        preds = ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,self).execute
        preds |= preds.collect{|p| p.super_predicates}.flatten
        preds |= super_types.collect{|type| type.instance_predicates}.flatten
        preds |= ActiveRDF::Query.new.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties
        preds
      end

      ### New methods

      # for resources of type RDFS::Class, returns array of RDFS::Resources for all super types defined by RDF::subClassOf
      def super_types
        sups = ActiveRDF::Query.new.distinct(:super_class).where(self,RDFS::subClassOf,:super_class).execute
        sups |= sups.inject([]){|supsups, sup| supsups |= sup.super_types} 
      end

      # for resources of type RDFS::Class, returns array of classes for all super types defined by RDF::subClassOf
      # otherwise returns empty array
      def super_classes
        super_types.collect{|type_res| ActiveRDF::ObjectManager.construct_class(type_res)}
      end

      # for resources of type RDF::Property, returns array of RDFS::Resources for all super properties defined by RDFS::subPropertyOf
      def super_predicates
        sups = ActiveRDF::Query.new.distinct(:super_property).where(self, RDFS::subPropertyOf, :super_property).execute
        sups |= sups.inject([]){|supsups, sup| supsups |= sup.super_predicates}
      end

      # for resources of type RDF::Property, returns array of RDF::Propertys for all super properties defined by RDFS::subPropertyOf
      def super_properties
        super_predicates.collect{|prop| RDF::Property.new(prop,self)}
      end

      # for resources of type RDF::Property, returns array of RDFS::Resources for all sub properties defined by RDFS::subPropertyOf
      def sub_predicates
        subs = ActiveRDF::Query.new.distinct(:sub_property).where(:sub_property, RDFS::subPropertyOf, self).execute
        subs |= subs.inject([]){|subsubs, sub| subsubs |= sub.sub_predicates}
      end

      # for resources of type RDF::Property, returns array of RDF::Propertys for all sub properties defined by RDFS::subPropertyOf
      def sub_properties
        sub_predicates.collect{|prop| RDF::Property.new(prop,self)}
      end

    # end $activerdf_internal_reasoning
    end

    alias :to_s :uri
    def to_literal_s
      raise ActiveRDF::ActiveRdfError, "emtpy RDFS::Resources not allowed" if self.uri.size == 0
      "<#{uri}>"
    end

    def inspect
      if ActiveRDF::ConnectionPool.adapters.size > 0
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
      base = ActiveRDF::Namespace.expand(ActiveRDF::Namespace.prefix(self),'').chop

      xml = "<?xml version=\"1.0\"?>\n"
      xml += "<rdf:RDF xmlns=\"#{base}\#\"\n"
      ActiveRDF::Namespace.abbreviations.each { |p| uri = ActiveRDF::Namespace.expand(p,''); xml += "  xmlns:#{p.to_s}=\"#{uri}\"\n" if uri != base + '#' }
      xml += "  xml:base=\"#{base}\">\n"

      xml += "<rdf:Description rdf:about=\"\##{localname}\">\n"
      direct_predicates.each do |p|
        objects = ActiveRDF::Query.new.distinct(:o).where(self, p, :o).execute
        objects.each do |obj|
          prefix, localname = ActiveRDF::Namespace.prefix(p), ActiveRDF::Namespace.localname(p)
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
    # Replaces any existing values if method is an assignment: resource.prop = new_value
    def method_missing(method, *args)
      # check for custom written method
      # eyal.age is a custom-written method in class Person
      # evidence: eyal type ?c, ?c.methods includes age
      # action: return results from calling custom method
      classes.each do |klass|
        if klass.instance_methods.include?(method.to_s)
          _dup = klass.new(uri)
          return _dup.send(method,*args)
        end
      end

      # otherwise pass search on to PropertyQuery
      ActiveRDF::PropertyLookup.new(self).method_missing(method, *args)
    end
  end
end