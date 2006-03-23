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

require 'module/attributes_container'
require 'module/instanciated_resource_method'
require 'module/dynamic_query_method'

class IdentifiedResource < Resource

	include AttributesContainer
	include InstanciatedResourceMethod
	extend DynamicQueryMethod
	
	# IdentifiedResource isn't an abstract class like Resource, we can instantiate it.
	public_class_method :new
	
	# if no subclass is specified, this is an rdfs:resource
	@@_class_uri[self] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Resource'

	# URI of the resource
	attr_reader :uri

	# Iitialize method of IdentifiedResource.
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]: The URI of the resource
	def initialize(uri)
		if uri.nil? or uri.empty?
			raise(ActiveRdfError, 'Resource URI is invalid. Cannot instanciated the object.')
		end
		@uri = uri
	end

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#
	
	public

	# Create a new identified resource if it doesn't exists, otherwise laod the resource.
	# This method must be called instead of the original new method, because
	# it calls the creation method of the NodeFactory which allows to keep only
	# one instance of the resource in memory.
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]: Uri of the resource.
	#
	# Return:
	# * [<tt>IdentifiedResource</tt>] The new identified resource
	def self.create(uri)
		return NodeFactory.create_identified_resource(uri, self)
	end

end

