# represents an RDF resource and manages manipulations of that resource, 
# including data lookup (e.g. eyal.age), data updates (e.g. eyal.age=20),
# class-level lookup (Person.find_by_name 'eyal'), and class-membership 
# (eyal.class ...Person)

# TODO: add unit test to validate class construction and queries on them
# TODO: add Person.find_all

require 'objectmanager/object_manager' 
require 'objectmanager/namespace'
require 'queryengine/query'
	   
module RDFS
	class Resource
		# adding accessor to the class uri:
		# the uri of the rdf resource being represented by this class
    class << self
      attr_accessor :class_uri
    end
    
    # setting our own class uri to rdfs:resource
    self.class_uri = Namespace.expand(:rdfs, :Resource)
    
		# you can only create new resources through Resource.lookup
		private_class_method :new

    #####                    ######
    ##### start of instance-level code
    #####                    ######
    
		# uri of the resource (for instances of this class: rdf resources)
		attr_reader :uri

		def initialize uri
			@uri = uri
		end

		#####                   	#####
		##### class level methods	#####
		#####                    	#####
		
		# returns Ruby object represting the RDF resource with the given URI (or nil)
		# (customised initialiser method, Resource.new is forbidden)
		def Resource.lookup(uri)
			ObjectManager.instance[uri] ||= new(uri)
		end

		# returns the predicates that have this resource as their domain (applicable 
		# predicates for this resource)
		def Resource.predicates
			domain = Namespace.lookup(:rdfs, 'domain')			
			Query.new.select(:p).where(:p, domain, lookup(@@class_uri)).execute || []
		end

		# manages invocations such as Person.find_by_name
		def Resource.method_missing(method, *args)
			method_name = method.to_s
			
			# extract predicates on which to match
			# e.g. find_by_name, find_by_name_and_age
			if match = /find_by_(.+)/.match(method_name)
				# find searched attributes, e.g. name, age
				attributes = match[1].split('_and_')

				# get list of possible predicates for this class
				possible_predicates = self.predicates

				# build query looking for all resources with the given parameters
				query = Query.new.select(:s)

				# add where clause for each attribute-value pair,
				# looking into possible_predicates to figure out
				# which full-URI to use for each given parameter (heuristic)
				
				attributes.each_with_index do |atr,i|
					possible_predicates.each do |pred|
						query.where(:s, pred, args[i]) if Namespace.localname(pred) == atr
					end
				end

				# execute query
				return query.execute
			end

			# otherwise, if no match found, raise NoMethodError (in superclass)
			super
		end

		#####                         #####
		##### instance level methods	#####
		#####                         #####
		
		# manages invocations such as eyal.age
		def method_missing(method, *args)
			# TODO:  method_missing (eyal.age)
			# 
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
			# 3. eyal.age is a custom-written method in class Person
			# evidence: eyal type ?c, ?c.methods includes age
			# action: inject age into eyal and invoke
			
			# maybe change order in which to check these, checking (3) is probably 
			# cheaper than (1)-(2) but (1) and (2) are probably more probable (getting 
			# attribute values over executing custom methods)
			
			
			# checking possibility (1) and (2)
			predicates.each do |pred|
				if Namespace.localname(pred) == method.to_s
					# found a property invocation of eyal: option 1) or 2)
					# query execution will return either the value for the predicate (1)
					# or nil (2)
					return Query.new.select(:o).where(self,pred,:o).execute
				end
			end

			# checking possibility (3)
#			self.class.each do |klass| 
#				if klass.instance_methods.include?(method.to_s) 
#				  p "should invoke #{method} on #{klass} now"
#				  return
#				  #extend(klass)
#				end
#			end
			
			# if none of the three possibilities work out,
			# we don't know this method invocation, so we throw NoMethodError (in 
			# superclass)
			super
		end

		# returns classes to which this resource belongs (according to rdf:type)
		def class
			types.collect do |type| 
				ObjectManager.get_class(type)
			end
		end

		# overrides built-in instance_of? to use rdf:type definitions
		def instance_of?(klass)
			self.class.include?(klass)
		end

		# returns all predicates that fall into the domain of the rdf:type of this 
		# resource
		def predicates
			type = Namespace.lookup(:rdf, 'type')
			domain = Namespace.lookup(:rdfs, 'domain')
			Query.new.select(:p).where(self,type,:t).where(:p, domain, :t).execute || []
		end

		# returns all rdf:types of this resource
		def types
			type = Namespace.lookup(:rdf, :type)
			
			# we lookup the type in the database
			# if we dont know it, we return Resource (as toplevel)
			# this should in theory actually never happen (since any node is a rdfs:Resource)
			# but could happen if the subject is unknown to the database
			Query.new.select(:t).where(self,type,:t).execute(:flatten => false) || [Namespace.lookup(:rdfs,"Resource")]
		end	

		# returns uri of resource, can be overridden in subclasses
		def to_s
			'<' + uri + '>'
		end
				
		def label
		  Namespace.localname(self)
		end
	end
end
