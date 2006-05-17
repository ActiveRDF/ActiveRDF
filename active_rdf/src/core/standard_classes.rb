require 'active_rdf'
class RdfsClass < IdentifiedResource
	set_class_uri 'http://www.w3.org/2000/01/rdf-schema#Class'
end

class RdfProperty < IdentifiedResource
	set_class_uri 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property'
	add_predicate IdentifiedResource.new('http://www.w3.org/2000/01/rdf-schema#domain')
end
