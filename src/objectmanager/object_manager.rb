# The object manager is responsible for creating a single Ruby object (or class) for
# each RDF resource (which might be an rdfs class)
#require 'singleton'
require 'active_rdf'
class ObjectManager #< Hash
  #	include Singleton

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
    if prefix.nil?
			# if the prefix is unknown, we create our own from the full URI
      modulename = create_module_name(resource)
		else
			# otherwise we convert the registered prefix into a module name
			modulename = prefix_to_module(prefix)
    end
    klassname = localname_to_class(localname)

    # look whether module defined
    # else: create it
    _module = if Object.const_defined?(modulename.to_sym)
				Object.const_get(modulename.to_sym)
			else
				Object.const_set(modulename, Module.new)
			end

		# look whether class defined in that module
		if _module.const_defined?(klassname.to_sym)
			# if so, return the existing class
			_module.const_get(klassname.to_sym)
		else
			# otherwise: create it, inside that module, as subclass of RDFS::Resource
			# (using toplevel Class.new to prevent RDFS::Class.new from being called)
			klass = _module.module_eval("#{klassname} = Object::Class.new(RDFS::Resource)")
			klass.class_uri = RDFS::Resource.new(resource.uri)
			klass
		end
	end

	private
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

end
