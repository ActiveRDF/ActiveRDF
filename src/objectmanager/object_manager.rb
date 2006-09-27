# ObjectManager maps each RDF resource (identified by URI) to a Ruby object.
# Resources can also be RDFS:Classes, in which case they will be mapped to a Ruby class
# The ObjectManager returns the right Ruby object given a URI identifying a resource.
require 'singleton'
class ObjectManager < Hash
	include Singleton
end
