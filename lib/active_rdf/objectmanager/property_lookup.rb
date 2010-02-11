module ActiveRDF
  class PropertyLookup

    # not directly chainable like ResourceQuery
    def initialize(subject)
      @ns = nil
      @subject = subject
    end

    # Searches for property belonging to @subject. Returns RDF::Property.
    # Replaces any existing values if method is an assignment: resource.prop=(new_value)
    def method_missing(ns_or_property, *args)
      # check registered namespace
      # foaf::name, where foaf is a registered abbreviation
      # evidence: foaf in Namespace
      # action: return self with @ns set
      if !@ns and Namespace.include?(ns_or_property)
        @ns = ns_or_property
        return self
      end

      property_name = ns_or_property.to_s
      # are we doing an update or not?
      # checking if method ends with '='
      update = property_name[-1..-1] == '='
      property_name = update ? property_name[0..-2] : property_name

      property =
        if @ns
          # seen registered namespace, lookup property
          RDF::Property.new(Namespace.lookup(@ns, property_name), @subject)
        elsif (registered_predicates = @subject.instance_eval{@predicates}) and registered_predicates.include?(property_name)
          # check for registered abbreviation
          # eyal.age is registered abbreviation
          # evidence: age in @predicates
          # action: return RDF::Property(age,self) and store value if assignment
          warn "Registered predicates is deprecated. Please use registered namespaces instead."
          RDF::Property.new(@predicates[property_name],@subject)
        else
          # search for known property
          @subject.properties.find{|prop| Namespace.localname(prop) == property_name}
        end

      if property
        property.replace(*args) if update
        return property
      end

      raise ActiveRdfError, "could not set #{methodname} to #{args}: no suitable predicate found. Maybe you are missing some schema information?" if update

      # If property can't be found, return nil instead of throwing NoMethodError.
      # In RDFS, we can't be sure that eyal cannot have an age, we just dont know the
      # age right now)
      nil
    end
  end
end
