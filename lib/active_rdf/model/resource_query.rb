module ActiveRDF
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
      # if the namespace has been seen, lookup the property
      if !@ns and Namespace.include?(ns_or_property)
        @ns = ns_or_property
        return self
      end

      property_name = ns_or_property.to_s
      property =
        if @ns
          Namespace.lookup(@ns, property_name)
        else
          @type.instance_predicates.find{|prop| Namespace.localname(prop) == property_name}
        end
      raise ActiveRdfError, "no suitable predicate matching '#{property_name}' found. Maybe you are missing some schema information?" unless property
      @ns = nil

      # restrict by values if provided
      options = values.extract_options!
      values.flatten!
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
end