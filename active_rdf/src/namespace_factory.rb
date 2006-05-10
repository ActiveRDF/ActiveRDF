# = namespace_factory.rb
#
# Factory for namespace. Keep in a hash each namespace and his prefix.
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
require 'activerdf_exceptions'

class NamespaceFactory

	# Hash of namespace (prefix => namespace)
	@@_namespaces = Hash.new

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public

	# Add a namespace related to a prefix.
	#
	# Arguments:
	# * +prefix+ [<tt>Symbol</tt>]: Prefix of the namespace
	# * +uri+ [<tt>String</tt>]: Namespace URI
	def self.add(prefix, uri)
		if !prefix.is_a?(Symbol)
			raise(NamespaceFactoryError, "In #{__FILE__}:#{__LINE__}, prefix is not a Symbol, received #{prefix.class}.")
		end

		if namespaces.key?(prefix)
			raise(NamespaceFactoryError, "In #{__FILE__}:#{__LINE__}, namespace already included.")
		end

		@@_namespaces[prefix] = uri
	end
	
	# Get a namespace
	#
	# Arguments:
	# * +prefix+ [<tt>Symbol</tt>]: Prefix of the namespace
	#
	# Return:
	# * [<tt>IdentifiedResource</tt>] Resource wrapping the namespace
	def self.get(prefix)
		if !prefix.is_a?(Symbol)
			raise(NamespaceFactoryError, "In #{__FILE__}:#{__LINE__}, prefix is not a Symbol, received #{prefix.class}.")
		end

		if !namespaces.key?(prefix)
			raise(NamespaceFactoryError, "In #{__FILE__}:#{__LINE__}, unknown namespace.")
		end
		
		return NodeFactory.create_basic_resource(namespaces[prefix])
	end

	# Load the commun uri in the factory.
	def self.load_namespaces
		add(:rdf_type, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
		add(:rdfs_domain, 'http://www.w3.org/2000/01/rdf-schema#domain')
		add(:rdfs_range, 'http://www.w3.org/2000/01/rdf-schema#range')
		add(:rdfs_subclass, 'http://www.w3.org/2000/01/rdf-schema#subClassOf')
		add(:owl_thing, 'http://www.w3.org/2002/07/owl#Thing')
		add(:rdfs_label, 'http://www.w3.org/2000/01/rdf-schema#label')
		add(:rdfs_comment, 'http://www.w3.org/2000/01/rdf-schema#comment')
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Accessor to the hash @@_namepaces
	def self.namespaces
		return @@_namespaces
	end

end

