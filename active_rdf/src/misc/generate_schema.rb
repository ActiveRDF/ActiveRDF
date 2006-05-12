#!/bin/ruby
require 'active_rdf'

NodeFactory.connection :adapter => :yars, :host => 'localhost', :context => 'great-buildings'
require 'core/standard_classes'

# constructs the class model from a RDF dataset
def self.construct_class_model
	qe = QueryEngine.new
	qe.add_binding_variables :o
	qe.add_condition(:s, NamespaceFactory.get(:rdf,:type), :o)
	all_types = qe.execute

	$logger.info "found #{all_types.size} types"
	
	for type in all_types do
		klass = RdfsClass.new(type.uri)
		klass.save

		qe.add_binding_variables :p
		qe.add_condition(:s, NamespaceFactory.get(:rdf,:type), type)
		qe.add_condition(:s, :p, :o)
		all_attributes = qe.execute

		for attribute in all_attributes
			begin
				property = RdfProperty.new(attribute.uri)
				property.domain = klass
				property.save
				$logger.info "added attribute #{attribute.local_name} to class #{klass.uri}"
			rescue ActiveRdfError
				$logger.warn "found empty attribute in class #{type.uri}"
			end
		end
	end
end

construct_class_model
