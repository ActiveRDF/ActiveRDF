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
    if prefix.nil?
      prefix = create_module_name(resource)
    end
    # find (ruby-acceptable) names for the module and class
    # e.g. FOAF and Person
    modulename = prefix_to_module(prefix)
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
  # TODO: replace illegal characters
  raise ActiveRdfError, 'bug 62491' if prefix.to_s.empty?
  prefix.to_s.upcase
end

def self.localname_to_class(localname)
  # TODO: replace illegal characters (numbers,#<(*, etc)
  # replace spaces by _

  #    p localname[0].chr
  localname[0] = localname[0].chr.upcase
  #    p localname[0].chr

  localname.to_s
end

def self.create_module_name(resource)
  # TODO clean up, check, if all illegal characters (e.g. numbers?) are replaced.
  uri = resource.uri
  delimiter = uri.rindex(/#|\//) # duplicated code from namespace.prefix
  # extract non-local part (including delimiter)
  nonlocal = uri[0..delimiter]
  nonlocal.gsub!(/[0-9 \?#:\/\\\.\+]+$/, '')
  prefix = nonlocal.gsub(/[ \?#:\/\\\.\+]+/, '_')
  #      puts "new prefix: #{prefix}"
end
end
