# = resource.rb
#
# Abstract Class definition of a RDF resource.
# Implements all class method shared in the different type of resources.
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#
# == To-do
#
# * To-do 1
#

require 'node_factory'
require 'resource_toolbox'
require 'query_generator/query_engine'

module Resource; implements Node

	# if no subclass is specified, this is an rdfs:resource
	@@_class_uri = Hash.new
	@@_class_uri[self] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource'

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public
	
	# Return the namespace related to the class (only for Resource)
	def self.class_URI
		return NodeFactory.create_basic_identified_resource(@@_class_uri[self])
	end
	
	# Return the namespace related to the class (for other Node)
	def class_URI
		if self.class == Class
			return NodeFactory.create_basic_identified_resource(@@_class_uri[self])
		else
			return NodeFactory.create_basic_identified_resource(@@_class_uri[self.class])
		end		
	end
	
	# 
	# * _subject_  
	# * _predicate_  
	# * _returns_ Array  
	def self.get(subject, predicate)
		if !subject.kind_of?(Resource) or !predicate.kind_of?(Resource)
			raise(ResourceTypeError, "In #{__FILE__}:#{__LINE__}, subject or predicate is not a Resource.")
		end
	
		# Build the query
		qe = QueryEngine.new(self)
		qe.add_binding_variables(:o)
		qe.add_condition(subject, predicate, :o)
		 
		# Execute query
		results = qe.execute
		return nil if results.nil?
		return_distinct_results results
	end
	
	# 
	# * _conditions_  
	# * _options_  
	# * _returns_ Array  
	def self.find(conditions = {}, options = {})
		# TODO: If Resource calls this function, we can't give conditions, because we don't
		# know the namespace for predicates
		# TODO: Try to add the management of the joint query, like (:x :knows :y, :y :type :dogs) for example
		
		# Generate the query string
		# We give to QueryEngine self to enable Symbol as predicate name 
		# (e.g. :name -> foaf:name and no the binding variable name)
		qe = QueryEngine.new(self)
		qe.add_binding_variables(:s)
		qe.add_condition(:s, NamespaceFactory.get(:rdf_type), class_URI) unless self == Resource
		if conditions.empty?
			qe.add_condition(:s, :p, :o)
		else
			conditions.each do |pred, obj|
				qe.add_condition(:s, pred, obj)
			end
		end
		qe.activate_keyword_search if options[:keyword_search]
		
		results = qe.execute
		return nil if results.nil?
		return_distinct_results(results)
	end
	
  # Extract the local part of a URI
  #
  # * +resource+: ActiveRDF::Resource representing the URI
  # * returns string with local part of the URI
	def local_part
		uri = self.uri
		delimiter = uri.rindex(/#|\//)
		
		# if no delimiter available then uri is broken
		str_error = "In #{__FILE__}:#{__LINE__}, uri is broken ('#{uri}')."
		raise(UriBrokenError, str_error) if delimiter.nil?
		
		return uri[delimiter+1..uri.size]
	end

end

