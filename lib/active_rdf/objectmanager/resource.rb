require 'active_rdf'
require 'objectmanager/object_manager'
require 'objectmanager/namespace'
require 'queryengine/query'

module RDFS
	# Represents an RDF resource and manages manipulations of that resource,
	# including data lookup (e.g. eyal.age), data updates (e.g. eyal.age=20),
	# class-level lookup (Person.find_by_name 'eyal'), and class-membership
	# (eyal.class ...Person).

  class RDFS::Resource
    # adding accessor to the class uri:
    # the uri of the rdf resource being represented by this class
    class << self
      attr_accessor :class_uri
    end

    # uri of the resource (for instances of this class: rdf resources)
    attr_reader :uri

    # creates new resource representing an RDF resource
    def initialize uri
      raise ActiveRdfError, "creating resource <#{uri}>" unless uri.is_a?(String)
      @uri = uri
    end

    # setting our own class uri to rdfs:resource
    # (has to be done after defining our RDFS::Resource.new
    # because it cannot be found in Namespace.lookup otherwise)
    self.class_uri = Namespace.lookup(:rdfs, :Resource)

    #####                        ######
    ##### start of instance-level code
    #####                        ######

    # a resource is same as another if they both represent the same uri
    def ==(other)
      if other.respond_to?(:uri)
        other.uri == self.uri
      else
        false
      end
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

    #####                   	#####
    ##### class level methods	#####
    #####                    	#####

    # returns the predicates that have this resource as their domain (applicable
    # predicates for this resource)
    def Resource.predicates
      domain = Namespace.lookup(:rdfs, :domain)
      Query.new.distinct(:p).where(:p, domain, class_uri).execute || []
    end

    # manages invocations such as Person.find_by_name
    def Resource.method_missing(method, *args)
      method_name = method.to_s

      $activerdflog.debug "RDFS::Resource: method_missing on class: called with method name #{method}"

      # extract predicates on which to match
      # e.g. find_by_name, find_by_name_and_age
      if match = /find_by_(.+)/.match(method_name)
        # find searched attributes, e.g. name, age
        attributes = match[1].split('_and_')

        # get list of possible predicates for this class
        possible_predicates = predicates

        # build query looking for all resources with the given parameters
        query = Query.new.distinct(:s)

        # add where clause for each attribute-value pair,
        # looking into possible_predicates to figure out
        # which full-URI to use for each given parameter (heuristic)

        attributes.each_with_index do |atr,i|
          possible_predicates.each do |pred|
            query.where(:s, pred, args[i]) if Namespace.localname(pred) == atr
          end
        end

        # execute query
        $activerdflog.debug "RDFS::Resource: method_missing on class: executing query: #{query}"
        return query.execute(:flatten => true)
      end

      # otherwise, if no match found, raise NoMethodError (in superclass)
      $activerdflog.warn 'RDFS::Resource: method_missing on class: method not matching find_by_*'
      super
    end

    # returns array of all instances of this class (e.g. Person.find_all)
    # (always returns collection)
    def Resource.find_all
      query = Query.new.distinct(:s).where(:s, Namespace.lookup(:rdf,:type), class_uri)
      if block_given?
        query.execute do |resource|
          yield resource
        end
      else
        query.execute(:flatten => false)
      end
    end

    #####                         #####
    ##### instance level methods	#####
    #####                         #####

    # manages invocations such as eyal.age
    def method_missing(method, *args)
      # possibilities:
      # 1. eyal.age is a property of eyal (triple exists <eyal> <age> "30")
      # evidence: eyal age ?a, ?a is not nil (only if value exists)
      # action: return ?a
      #
      # 2. eyal's class is in domain of age, but does not have value for eyal
      # explain: eyal is a person and some other person (not eyal) has an age
      # evidence: eyal type ?c, age domain ?c
      # action: return nil
      #
      # 3. eyal.age = 30 (setting a value for a property)
      # explain: eyal has (or could have) a value for age, and we update that value
      # complication: we need to find the full URI for age (by looking at
      # possible predicates to use
      # evidence: eyal age ?o  (eyal has a value for age now, we're updating it)
      # evidence: eyal type ?c, age domain ?c (eyal could have a value for age, we're setting it)
      # action: add triple (eyal, age, 30), return 30
      #
      # 4. eyal.age is a custom-written method in class Person
      # evidence: eyal type ?c, ?c.methods includes age
      # action: inject age into eyal and invoke

      # maybe change order in which to check these, checking (4) is probably
      # cheaper than (1)-(2) but (1) and (2) are probably more probable (getting
      # attribute values over executing custom methods)

      $activerdflog.debug "RDFS::Resource: method_missing on instance: called with method name #{method}"

      # are we doing an update or not?
      # checking if method ends with '='

      if method.to_s[-1..-1] == '='
        methodname = method.to_s[0..-2]
        update = true
      else
        methodname = method.to_s
        update = false
      end

      candidates = if update
                      (class_level_predicates + direct_predicates).compact.uniq
                    else
                      direct_predicates
                    end
    
    # checking possibility (1) and (3)
    candidates.each do |pred|
      if Namespace.localname(pred) == methodname
        # found a property invocation of eyal: option 1) or 2)
        # query execution will return either the value for the predicate (1)
        # or nil (2)
        if update
          # TODO: delete old value if overwriting
          # FederiationManager.delete(self, pred, nil)

          # handling eyal.friends = [armin, andreas] --> expand array values
          args.each do |value|
            FederationManager.add(self, pred, value)
          end
          return args
        else
          # look into args, if it contains a hash with {:array => true} then
          # we should not flatten the query results
          return get_property_value(pred, args)
        end
      end
    end
    
		raise ActiveRdfError, "could not set #{methodname} to #{args}: no suitable 
		predicate found. Maybe you are missing some schema information?" if update

    # get/set attribute value did not succeed, so checking option (2) and (4)
    
    # checking possibility (2), it is not handled correctly above since we use
    # direct_predicates instead of class_level_predicates. If we didn't find
    # anything with direct_predicates, we need to try the
    # class_level_predicates. Only if we don't find either, we
    # throw "method_missing"
    candidates = class_level_predicates

    # if any of the class_level candidates fits the sought method, then we
    # found situation (2), so we return nil or [] depending on the {:array =>
    # true} value
    if candidates.any?{|c| Namespace.localname(c) == methodname}
      return_ary = args[0][:array] if args[0].is_a? Hash
      if return_ary
        return []
      else
        return nil

      end
    end

    # checking possibility (4)
    # TODO: implement search strategy to select in which class to invoke
    # e.g. if to_s defined in Resource and in Person we should use Person
    $activerdflog.debug "RDFS::Resource: method_missing option 4: custom class method"
    self.type.each do |klass|
      if klass.instance_methods.include?(method.to_s)
        _dup = klass.new(uri)
        return _dup.send(method,*args)
      end
    end

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
		rdftype = Namespace.lookup(:rdf, :type)
		types.each do |t|
			db.add(self, rdftype, t)
		end

		Query.new.distinct(:p,:o).where(self, :p, :o).execute do |p, o|
			db.add(self, p, o)
		end
	end

  def type
    types.collect do |type|
      ObjectManager.construct_class(type)
    end
  end

  # overrides built-in instance_of? to use rdf:type definitions
  def instance_of?(klass)
    self.type.include?(klass)
  end

  # returns all predicates that fall into the domain of the rdf:type of this
  # resource
  def class_level_predicates
    type = Namespace.lookup(:rdf, 'type')
    domain = Namespace.lookup(:rdfs, 'domain')
    Query.new.distinct(:p).where(self,type,:t).where(:p, domain, :t).execute || []
  end

  # returns all predicates that are directly defined for this resource
  def direct_predicates(distinct = true)
    if distinct
      q = Query.new.distinct(:p)
    else
      q = Query.new.select(:p)
    end
    q.where(self,:p, :o).execute
  end

  def property_accessors
    direct_predicates.collect {|pred| Namespace.localname(pred) }
  end

  # alias include? to ==, so that you can do paper.creator.include?(eyal)
  # without worrying whether paper.creator is single- or multi-valued
  alias include? ==

  # returns uri of resource, can be overridden in subclasses
  def to_s
    "<#{uri}>"
  end

	# label of resource (rdfs:label if available, uri otherwise)
  def label
    get_property_value(Namespace.lookup(:rdfs,:label)) || uri
  end

  private
  def get_property_value(predicate, args=[])
    return_ary = args[0][:array] if args[0].is_a?(Hash)
    flatten_results = !return_ary
    query = Query.new.distinct(:o).where(self, predicate, :o)
		query.execute(:flatten => flatten_results)
  end  

  # returns all rdf:types of this resource
  def types
    type = Namespace.lookup(:rdf, :type)

    # we lookup the type in the database
    types = Query.new.distinct(:t).where(self,type,:t).execute

    # we are also always of type rdfs:resource and of our own class (e.g. foaf:Person)
		defaults = []
		defaults << Namespace.lookup(:rdfs,:Resource)
		defaults << self.class.class_uri

    (types + defaults).uniq
  end

end
end
