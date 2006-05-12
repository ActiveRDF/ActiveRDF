#!/bin/ruby
require 'active_rdf'

class RdfsClass < IdentifiedResource
	set_class_uri NamespaceFactory.get(:rdfs,:Class)  #'http://www.w3.org/2000/01/rdf-schema#Class'
end

class RdfProperty < IdentifiedResource
	 set_class_uri NamespaceFactory.get(:rdf,:Property) # 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property'
	 add_predicate NamespaceFactory.get(:rdfs,:domain)
end

# constructs the class model from a RDF dataset
def self.construct_class_model
	qe = QueryEngine.new
	qe.add_binding_variables :o
	qe.add_condition(:s, NamespaceFactory.get(:rdf_type), :o)
	all_types = qe.execute

	logger.info "found #{all_types.size} types in #{connection.context}"
	
	for type in all_types do
		klass = RdfsClass.new(type)
		#klass.save

		qe.add_binding_variables :p
		qe.add_condition(:s, NamespaceFactory.get(:rdf,:type), type)
		qe.add_condition(:s, :p, :o)
		all_attributes = qe.execute

		for attribute in all_attributes
			begin
				property = RdfProperty.new(attribute)
				property.domain = klass
				#property.save
				logger.info "added attribute #{attribute} to class #{klass}"
			rescue ActiveRdfError
				logger.warn "found empty attribute in class #{type.uri}"
			end
		end
	end
end

logger = Logger.new(STDOUT)
NodeFactory.connection :adapter => :yars, :host => 'localhost', :context => 'fbi'

construct_class_model
