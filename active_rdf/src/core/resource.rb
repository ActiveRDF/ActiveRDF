# = resource.rb
#
# Abstract model class definition of an RDF resource.
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

require 'node_factory'
require 'query_generator/query_engine'

class Resource; implements Node

	# Resource is an abstract class, we cannot instantiate it.
	private_class_method :new

	# if no subclass is specified, this is an rdfs:resource
	@@_class_uri = Hash.new
	@@_inverse_class_uri = Hash.new
	@@_class_uri[self] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource'
	@@_inverse_class_uri['http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource'] = self


#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public


	# Sets the URI of the class
	def self.set_class_uri uri
		@@_class_uri[self] = uri
		@@_inverse_class_uri[uri] = self
	end

	
	# Return the namespace related to the class (only for Class level)
	def self.class_URI
		return NodeFactory.create_basic_resource(@@_class_uri[self])
	end
	
	# Return the namespace related to the class (for instance level)
	def class_URI
		return NodeFactory.create_basic_resource(@@_class_uri[self.class])		
	end
	
	# You don't have to use this method. This method is used internaly in ActiveRDF.
	# This method generates a query to get the value related to the pair (subject, predicate).
	#
	# Arguments:
	# * +subject+ [<tt>Resource</tt>]: A Resource node as subject
	# * +predicate+: The predicate can be a Resource or a Symbol (attribute name
	#				 related to the class model).
	#
	# Return:
	# * An array of distinct value (Literal or Resource). Nil if no result.
	def self.get(subject, predicate)
		if not subject.kind_of?(Resource) or not predicate.kind_of?(Resource)
			raise(ResourceTypeError, "In #{__FILE__}:#{__LINE__}, subject or predicate is not a Resource.")
		end

		$logger.debug "getting #{predicate.local_part} of #{subject}"
	
		# Build the query
		if self != Resource
			qe = QueryEngine.new(self)
		else
			qe = QueryEngine.new
		end
		qe.add_binding_variables :o
		qe.add_condition(subject, predicate, :o)
		$logger.debug "GET query: #{qe.generate}"
		 
		# Execute query
		results = qe.execute
		$logger.debug "#{subject} has #{predicate.local_part} #{results}"
		# results is not allowed to be nil, we should throw an AdapterError then 

		if (results.nil? or not results.kind_of? Array)
			raise(AdapterError,"Unexpected result in #{__FILE__}:#{__LINE__}") 
		end
		results
	end

	# Find statements of a resource according to the values of their attributes.
	# conditions is a hash from property (symbol or resource) to value (literal or 
	# resource) e.g. { :firstName => 'Eyal', rdfs:domain => Person }
	#
	# Arguments:
	# * +conditions+ [<tt>Hash</tt>]: Hash of conditions : { predicate => value, predicate => [value, ...] }
	# * +options+ [<tt>Hash</tt>]: Hash of options : { :keyword_search => (true | false) }
	#
	# Return:
	# * [<tt>Array</tt>] A (possibly empty) array of distinct results (Node).
	def self.find(conditions = {}, options = {})
		# TODO: If Resource calls this function, we can't give conditions, because we don't
		# know the namespace for predicates
		# TODO: Try to add the management of the joint query, like (:x :knows :y, :y :type :dogs) for example
		
		# Generate the query string
		# We give to QueryEngine self to enable Symbol as predicate name 
		# (e.g. :name -> foaf:name and no the binding variable name)
		if self != Resource
			qe = QueryEngine.new(self)
		else
			qe = QueryEngine.new
		end
		qe.add_binding_variables(:s)
		
		if self != IdentifiedResource and self.ancestors.include?(IdentifiedResource)
			qe.add_condition(:s, NamespaceFactory.get(:rdf_type), class_URI)
		end
		
		if conditions.empty?
			qe.add_condition(:s, :p, :o)
		else
			conditions.each do |pred, obj|
				qe.add_condition(:s, pred, obj)
			end
		end
		
		qe.activate_keyword_search if options[:keyword_search]
		
		results = qe.execute

		# results is not allowed to be nil, we should throw an AdapterError then 
		if (results.nil? or not results.kind_of? Array)
			raise(AdapterError,"Unexpected result in #{__FILE__}:#{__LINE__}") 
		end
		results
	end
	
	# Look in the database if a resource exists. Add automatically a condition on the resource
	# type if it is called from a sub-class of IdentifiedResource.
	#
	# Arguments:
	# * +resource+: The resource to test or the string URI of the resource
	#
	# Return:
	# * [<tt>Bool</tt>] True if present in database, false otherwise.
	def self.exists?(resource)
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, resource is nil.") if resource.nil?
		
		# Build the query
		if self != Resource
			qe = QueryEngine.new(self)
		else
			qe = QueryEngine.new
		end
		qe.add_binding_variables(:p, :o)
		
		if self != IdentifiedResource and self.ancestors.include?(IdentifiedResource)
			qe.add_condition(:s, NamespaceFactory.get(:rdf_type), class_URI)
		end
		
		# Convert URI string into basic resource
		resource = NodeFactory.create_basic_resource(resource) if resource.instance_of?(String)
		
		qe.add_condition(resource, :p, :o)
		 
		# Execute query
		return !qe.execute.empty?
	end
	
	# Extract the local part of a URI
	#
	# * +resource+: ActiveRDF::Resource representing the URI
	# * returns string with local part of the URI
	def local_part
		uri = self.uri
		delimiter = uri.rindex(/#|\//)
		
		# if no delimiter available then uri is broken
		return uri if delimiter.nil?
		
		return uri[delimiter+1..uri.size]
	end

	def <=> b
		if b.kind_of? Resource
			uri <=> b.uri
		else
			to_s <=> b.to_s
		end
	end

	def render_label
		if attributes.include? 'label'
			label = self.label
			label = label.sort.join(', ') if label.kind_of? Array
			return label
		else
			local_part
		end
	end

	alias local_name local_part

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Find all predicates for a resource from the schema definition
	# returns a hash containing from localname to full predicate URI (e.g. 
	# 'firstName' => 'http://foaf.org/firstName')  
	def self.find_predicates(class_uri)
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, class uri is nil.") if class_uri.nil?
		raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, class uri is not a Resource, it's a #{class_uri.class}.") if !class_uri.instance_of?(IdentifiedResource)

		predicates = Hash.new
		
		preds = Resource.find({ NamespaceFactory.get(:rdfs_domain) => class_uri })

	 	preds.each do |predicate|
			attribute = predicate.local_part
			predicates[attribute] = predicate.uri
			$logger.debug "found predicate #{attribute}"
		end unless preds.nil?

		preds = Resource.find({ NamespaceFactory.get(:rdfs_domain) => NamespaceFactory.get(:owl_thing) })
	 	preds.each do |predicate|
			attribute = predicate.local_part
			predicates[attribute] = predicate.uri
			$logger.debug "added OWL Thing predicate #{attribute}"
		end unless preds.nil?
		
		# Generate the query string
		qe = QueryEngine.new
		qe.add_binding_variables(:o)
		qe.add_condition(class_uri, NamespaceFactory.get(:rdfs_subclass), :o)
		
		$logger.debug "Before call Find superpredicate for #{class_uri}"
		
		# Execute the query
		qe.execute.each do |o|
			$logger.debug "Find superpredicate #{o.to_s} for #{class_uri}"
			superclass = o
			superpredicates = find_predicates(superclass)
			$logger.debug "Found superpredicate : " + superpredicates.inspect
			predicates.update(superpredicates)
		end
		$logger.debug "Find predicate result : " + predicates.inspect
		return predicates				
	end
end
