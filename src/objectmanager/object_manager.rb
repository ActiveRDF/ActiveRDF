# The object manager is responsible for creating a single Ruby object (or class) for 
# each RDF resource (which might be an rdfs class)
require 'singleton'
require 'active_rdf'
class ObjectManager < Hash
	include Singleton

	# constructs empty Ruby classes for all RDF types found in the data
	#
	# allows users to invoke methods on classes (e.g. FOAF::Person) without 
	# getting symbol undefined errors (because e.g. foaf:person wasnt encountered 
	# before so no class was created for it)
	def self.construct_classes
		# find all rdf:types and construct class for each of them
		q = Query.new.distinct(:t).where(:s,Namespace.lookup(:rdf,:type),:t)
		q.execute do |t|
			get_class(t)
		end
	end
  
	# constructs Ruby class for the given resource (and puts it into the module as 
	# defined by the registered namespace abbreviations)
	def self.get_class(resource)	    
		# get prefix abbreviation and localname from type
		# e.g. :foaf and Person
		localname = Namespace.localname(resource)
		prefix = Namespace.prefix(resource)

		# find (ruby-acceptable) names for the module and class 
		# e.g. FOAF and Person
		modulename = prefix_to_module(prefix)
		klassname = localname_to_class(localname)
		
		#p "looking for #{klassname} in #{modulename} "
		
		# look whether module defined
		# else: create it
		_module = if Object.const_defined?(modulename.to_sym)
		 #     p "found module"
								Object.const_get(modulename.to_sym)
							else
			#			p "creating module"
								Object.const_set(modulename, Module.new)
							end

		# look whether class defined in that module
		# if not: define the class insinde that module
		# and return the found/created class
		if _module.const_defined?(klassname.to_sym)
			_module.const_get(klassname.to_sym)
		else
		  p "looking for #{klassname} in #{modulename} "
			klass = _module.module_eval("#{klassname} = Class.new(RDFS::Resource)")
			klass.class_uri = resource.uri
			klass
		end
	end

	private
	def self.prefix_to_module(prefix)
		# TODO: replace illegal characters
		raise ActiveRdfError, 'bug 62491' if prefix.to_s.empty?
		prefix.to_s.upcase
	end
	
	def self.localname_to_class(localname)
		# TODO: replace illegal characters (numbers,#<(*, etc)
		# replace spaces by _
		localname.to_s
	end		
end
