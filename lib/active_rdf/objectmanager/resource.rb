require 'active_rdf'
require 'objectmanager/object_manager'
require 'objectmanager/namespace'
require 'queryengine/query'

# TODO: finish removal of ObjectManager.construct_classes: make dynamic finders 
# accessible on instance level, and probably more stuff.

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
      @uri = case uri
            when RDFS::Resource
             uri.uri
            when String
              uri
            else 
              raise ActiveRdfError, "cannot create resource <#{uri}>"
            end
			@predicates = Hash.new
    end

    # setting our own class uri to rdfs:resource
    # (has to be done after defining our RDFS::Resource.new
    # because it cannot be found in Namespace.lookup otherwise)
    self.class_uri = Namespace.lookup(:rdfs, :Resource)

    def self.uri; class_uri.uri; end
    def self.==(other)
      other.respond_to?(:uri) ? other.uri == self.uri : false
    end

    #####                        ######
    ##### start of instance-level code
    #####                        ######

    # a resource is same as another if they both represent the same uri
    def ==(other)
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

    #####                   	#####
    ##### class level methods	#####
    #####                    	#####

    # returns the predicates that have this resource as their domain (applicable
    # predicates for this resource)
    def Resource.predicates
      domain = Namespace.lookup(:rdfs, :domain)
      Query.new.distinct(:p).where(:p, domain, class_uri).execute || []
    end

    # manages invocations such as Person.find_by_name, 
    # Person.find_by_foaf::name, Person.find_by_foaf::name_and_foaf::knows, etc.
    def Resource.method_missing(method, *args)
      if /find_by_(.+)/.match(method.to_s)
        $activerdflog.debug "constructing dynamic finder for #{method}"

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

    #####                         #####
    ##### instance level methods	#####
    #####                         #####
    def find(*args)
      # extract sort options from args
      options = args.last.is_a?(Hash) ? args.pop : {}

      query = Query.new.distinct(:s)
      query.where(:s, Namespace.lookup(:rdf,:type), self)

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
        raise ActiveRdfError, "where clause should be array of [predicate, object]" unless options[:where].size == 2
        predicate = options[:where].first
        object = options[:where].last
        query.where(:s, predicate, object)
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
			#
			# 5. eyal.age is registered abbreviation 
			# evidence: age in @predicates
			# action: return object from triple (eyal, @predicates[age], ?o)
			#
			# 6. eyal.foaf::name, where foaf is a registered abbreviation
			# evidence: foaf in Namespace.
			# action: return namespace proxy that handles 'name' invocation, by 
			# rewriting into predicate lookup (similar to case (5)

      # maybe change order in which to check these, checking (4) is probably
      # cheaper than (1)-(2) but (1) and (2) are probably more probable (getting
      # attribute values over executing custom methods)

      $activerdflog.debug "method_missing: #{method}"

      # are we doing an update or not? 
			# checking if method ends with '='

      if method.to_s[-1..-1] == '='
        methodname = method.to_s[0..-2]
        update = true
      else
        methodname = method.to_s
        update = false
      end

			# check possibility (5)
			if @predicates.include?(methodname)
				return predicate_invocation(@predicates[methodname], args, update)
			end

			# check possibility (6)
			if Namespace.abbreviations.include?(method)
				namespace = Object.new	
				@@uri = method
				@@subject = self

        # catch the invocation on the namespace
        class <<namespace
          def method_missing(localname, *args)
            puts localname.to_s
            # check if updating or reading predicate value
            if localname.to_s[-1..-1] == '='
              # set value
              predicate = Namespace.lookup(@@uri, localname.to_s[0..-2])
              ConnectionPool.write_adapter.delete(@@subject, predicate, :any)
              args.each do |value|
                FederationManager.add(@@subject, predicate, value)
              end
            else
              # read value
              predicate = Namespace.lookup(@@uri, localname)
              Query.new.distinct(:o).where(@@subject, predicate, :o).execute(:flatten => true)
            end
          end
          private(:type)
        end
        return namespace
      end

      candidates = if update
                      (class_level_predicates + direct_predicates).compact.uniq
                    else
                      direct_predicates
                    end

			# checking possibility (1) and (3)
			candidates.each do |pred|
				if Namespace.localname(pred) == methodname
					return predicate_invocation(pred, args, update)
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

		# returns all rdf:type of this instance, e.g. [RDFS::Resource, 
		# FOAF::Person]
		#
		# Note: this method performs a database lookup for { self rdf:type ?o }. For 
		# simple type-checking (to know if you are handling an ActiveRDF object, use 
		# self.class, which does not do a database query, but simply returns 
		# RDFS::Resource.
		def type
			types.collect do |type|
				ObjectManager.construct_class(type)
			end
		end

		def add_predicate localname, fulluri
			localname = localname.to_s
			fulluri = RDFS::Resource.new(fulluri) if fulluri.is_a? String

			# predicates is a hash from abbreviation string to full uri resource
			@predicates[localname] = fulluri
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
			#return (direct + direct.collect {|d| ancestors(d)}).flatten.uniq
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

	#	# label of resource (rdfs:label if available, uri otherwise)
	#  def label
	#    get_property_value(Namespace.lookup(:rdfs,:label)) || uri
	#  end

		private

#		def ancestors(predicate)
#			subproperty = Namespace.lookup(:rdfs,:subPropertyOf)
#			Query.new.distinct(:p).where(predicate, subproperty, :p).execute
#		end

		def predicate_invocation(predicate, args, update)
			if update
				args.each do |value|
					FederationManager.add(self, predicate, value)
				end
				args
			else
				get_property_value(predicate, args)
			end
		end

		def get_property_value(predicate, args=[])
			return_ary = args[0][:array] if args[0].is_a?(Hash)
			flatten_results = !return_ary
			query = Query.new.distinct(:o).where(self, predicate, :o)
			query.execute(:flatten => flatten_results)
		end  

		# returns all rdf:types of this resource but without a conversion to 
		# Ruby classes (it returns an array of RDFS::Resources)
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

# proxy to manage find_by_ invocations
class DynamicFinderProxy
  @ns = nil
  @where = nil
  @value = nil
  attr_reader :value

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
    query = Query.new.distinct(:s)
    @where.each_with_index do |predicate, i|
      query.where(:s, predicate, args[i])
    end

    $activerdflog.debug "executing dynamic finder: #{query.to_sp}"

    # store the query results so that caller (Resource.method_missing) can 
    # retrieve them (we cannot return them here, since we were invoked from 
    # the initialize method so all return values are ignored, instead the proxy 
    # itself is returned)
    @value = query.execute(:flatten => true)
    return value
  end
end
