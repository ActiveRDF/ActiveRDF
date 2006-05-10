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
			raise(ActiveRdfError, 'No URI given. Cannot instantiate object without URI.')
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

	def to_s
		return uri
	end

	def ==(b)
		return eql?(b)
	end

	def eql?(b)
		if b.class == self.class
			return b.uri == uri
		else 
			return false
		end
	end

	def hash
		uri.hash
	end

	# Adds the predicate to the class level of the resource
	def self.add_predicate(uri, localname = nil)
		$logger.debug "adding predicate #{uri} to class #{self}"

		# if we received a Resource as URI then that is ok, otherwise if we resource 
		# a String we create an IdentifiedResource ourselves, otherwise we throw an 
		# error
		unless uri.respond_to? :uri
			if uri.kind_of? String
				uri = IdentifiedResource.create uri
			else 
				raise ActiveRdfError, "add_predicate should be given IdentifiedResource or String, received a #{uri.class}"
			end
		end

		# if not given a localname we construct one ourselves
		localname = uri.local_part if localname.nil?

		# getting the predicates hash of this class
		# (hashing localname -> IdentifiedResource-fullURI
		class_hash = @@predicates[self]

		# initialise predicates hash for this class if undefined
		@@predicates[self] = (class_hash = Hash.new) if class_hash.nil?

		$logger.debug "adding predicate #{uri}; class hash has size #{class_hash.size}"

		# if localname collision detected
		if class_hash.include? localname
			$logger.debug "localname collision when adding predicate #{uri}"

			# if this predicate was already defined for the class, we don't do 
			# anything and just return the predicate
			if class_hash[localname] == uri
				return uri
			else
				#otherwise we raise a collision error
			 	raise ActiveRdfError, "local_name collision, given #{uri} but we already have a predicate called #{localname} defined with URI #{class_hash[localname]}"
			end
		end
		
		# add the localname with the given URI to the predicates hash of this class
		class_hash[localname] = uri

		# TODO: add schema information to database: 
		# uri rdf:type property; uri rdfs:domain self
		
		$logger.debug "added predicate; class hash has size #{class_hash.size}"
		return uri
	end
	
end

