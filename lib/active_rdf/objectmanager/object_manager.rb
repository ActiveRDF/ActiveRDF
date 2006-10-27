# Constructs Ruby classes for RDFS classes (in the right namespace)
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL
require 'active_rdf'

class ObjectManager
  # constructs empty Ruby classes for all RDF types found in the data
	#
  # allows users to invoke methods on classes (e.g. FOAF::Person) without
  # getting symbol undefined errors (because e.g. foaf:person wasnt encountered
  # before so no class was created for it)
  def self.construct_classes
    # find all rdf:types and construct class for each of them
    #q = Query.new.select(:t).where(:s,Namespace.lookup(:rdf,:type),:t)
		
		# find everything defined as rdfs:class or owl:class
		type = Namespace.lookup(:rdf,:type)
		rdfsklass = Namespace.lookup(:rdfs,:Class)

		# TODO: we should not do this, we should not support OWL
		# instead, owl:Class is defined as subclass-of rdfs:Class, so if the 
		# reasoner has access to owl definition it should work out fine.
		owlklass = Namespace.lookup(:owl,:Class)

		klasses = []
    klasses << Query.new.distinct(:s).where(:s,type,rdfsklass).execute
    klasses << Query.new.distinct(:s).where(:s,type,owlklass).execute

		# flattening to get rid of nested arrays
		# compacting array to get rid of nil (if one of these queries returned nil)
		klasses = klasses.flatten.compact
		$log.info "ObjectManager: construct_classes: classes found: #{klasses}"
		
		# then we construct a Ruby class for each found rdfs:class
		# and return the set of all constructed classes
    klasses.collect { |t| construct_class(t) }
  end

  # constructs Ruby class for the given resource (and puts it into the module as
  # defined by the registered namespace abbreviations)
  def self.construct_class(resource)
    # get prefix abbreviation and localname from type
    # e.g. :foaf and Person
    localname = Namespace.localname(resource)
    prefix = Namespace.prefix(resource)

    # find (ruby-acceptable) names for the module and class
    # e.g. FOAF and Person
    if prefix.nil?
			# if the prefix is unknown, we create our own from the full URI
      modulename = create_module_name(resource)
      $log.info "ObjectManager: construct_class: constructing modulename #{modulename} from URI #{resource}"
		else
			# otherwise we convert the registered prefix into a module name
			modulename = prefix_to_module(prefix)
			$log.info "ObjectManager: construct_class: constructing modulename #{modulename} from registered prefix #{prefix}"
    end
    klassname = localname_to_class(localname)

    # look whether module defined
    # else: create it
    _module = if Object.const_defined?(modulename.to_sym)
        $log.info "ObjectManager: construct_class: module name #{modulename} previously defined"
				Object.const_get(modulename.to_sym)
			else
        $log.info "ObjectManager: construct_class: defining module name #{modulename} now"
				Object.const_set(modulename, Module.new)
			end

		# look whether class defined in that module
		if _module.const_defined?(klassname.to_sym)
      $log.info "ObjectManager: construct_class: given class #{klassname} defined in the module"
			# if so, return the existing class
			_module.const_get(klassname.to_sym)
		else
      $log.info "ObjectManager: construct_class: creating given class #{klassname}"
			# otherwise: create it, inside that module, as subclass of RDFS::Resource
			# (using toplevel Class.new to prevent RDFS::Class.new from being called)
			klass = _module.module_eval("#{klassname} = Object::Class.new(RDFS::Resource)")
			klass.class_uri = RDFS::Resource.new(resource.uri)
			klass
		end
	end

	def self.prefix_to_module(prefix)
		# TODO: remove illegal characters
		prefix.to_s.upcase
	end

	def self.localname_to_class(localname)
		# replace illegal characters inside the uri
		# and capitalize the classname
		replace_illegal_chars(localname).capitalize
	end

	def self.create_module_name(resource)
		# TODO: write unit test to verify replacement of all illegal characters
		
		# extract non-local part (including delimiter)
		uri = resource.uri
		delimiter = uri.rindex(/#|\//)
		nonlocal = uri[0..delimiter]

		# remove illegal characters appearing at the end of the uri (e.g. trailing 
		# slash)
		cleaned_non_local = nonlocal.gsub(/[^a-zA-Z0-9]+$/, '')

		# replace illegal chars within the uri
		replace_illegal_chars(cleaned_non_local).upcase
	end

	def self.replace_illegal_chars(name)
		name.gsub(/[^a-zA-Z0-9]+/, '_')
	end

  #declare the class level methods as private with these directives
  private_class_method :prefix_to_module
  private_class_method :localname_to_class
  private_class_method :create_module_name
  private_class_method :replace_illegal_chars

end
