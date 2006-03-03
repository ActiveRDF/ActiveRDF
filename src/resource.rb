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
require 'module/resource_toolbox'
require 'query_generator/query_engine'

module Resource; implements Node; extend ResourceToolbox

	# if no subclass is specified, this is an rdfs:resource
	@namespace = 'http://www.w3.org/2000/01/rdf-schema#'

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public

	# 
	# * _returns_ BasicIdentifiedResource  
	def self.classURI()
		return NodeFactory.create_basic_identified_resource(namespace + self.to_s)
	end
	
	# 
	# * _subject_  
	# * _predicate_  
	# * _returns_ Array  
	def self.get(subject, predicate)
		if !subject.kind_of?(Resource) or predicate.kind_of?(Resource)
			raise(ResourceTypeError, "In #{__FILE__}:#{__LINE__}, subject or predicate is not a Resource.")
		end
	
		# Build the query
		qe = QueryEngine.new(self)
		qe.add_binding_variables(:o)
		qe.add_condition(subject, predicate, :o)
		 
		# Execute query
		results = qe.execute
		return nil if results.nil?
		return_unique_results results	
	end
	
	# 
	# * _conditions_  
	# * _options_  
	# * _returns_ Array  
	def self.find(conditions = {}, options = {})
			
	end
	
	# 
	# * _returns_ Array  
	def self.find_all()
			
	end
	
	# Return the namespace related to the class
	def self.namespace
		return @namespace
	end

end

