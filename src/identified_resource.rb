# = identified_resource.rb
#
# Class definition of an identified resource.
# This resource is the superclass of all rdf resource identified and contains
# all instance methods and class methods to manipulate related attributes, search
# other resources related, etc...
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

require 'basic_identified_resource'
require 'module/attributes_container'
require 'module/instanciated_resource_method'

class IdentifiedResource < BasicIdentifiedResource

	include AttributesContainer
	include InstanciatedResourceMethod
	
	# if no subclass is specified, this is an rdfs:resource
	@@_class_uri[self] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource'

	def initialize(uri, attributes = nil)
		super(uri)
		
		@_attributes = Hash.new
		self.class.predicates.each_key do |attr_name|
			@_attributes[attr_name] = nil
		end
		
		update_attributes(attributes) if !attributes.nil?
	end

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public
	
	def to_identified_resource
		raise(NoMethodError, "This object is already an identified resource.")
	end

end

