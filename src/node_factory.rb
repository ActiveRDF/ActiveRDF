# = node_factory.rb
#
# NodeFactory manages the creation and instanciation of each type of node
# (Resource, Literal, AnonymousResource, etc...). It keeps only one instance of each
# Resource.
# It manages also the connection with one adpater.
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

require 'activerdf_exceptions'

require 'literal'
require 'resource'
require 'basic_identified_resource'
require 'identified_resource'

class NodeFactory

	# Instanciation of adapter
	@@_connection = nil
	
	# Hash of instanciated resources
	@@_resources = Hash.new
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

  public

  # Return the current instance of the connection. If no connection exists and 
  # params given, instantiate a new connection.
  #
  # Arguments:
  # * +params+ [<tt>Hash</tt>]: Connection parameter. Required only the first time, to initialize the connection.
  #
  # Return:
  # * [<tt>AbstractAdapter</tt>] The current connection with the RDF DataBase.
	def self.connection(params = nil)
	
		if @@_connection.nil? and params.nil?
			raise(ConnectionError, "In #{__FILE__}:#{__LINE__}, no parameters to instantiate connection.")
		elsif !@@_connection.nil? and params.nil?
			return @@_connection
		end
	
		case params[:adapter]
		when :yars
			$logger.info 'loading YARS adapter'
			# TODO: semperwiki web dies after coming here
			require 'adapter/yars/yars_adapter'
			@@_connection = YarsAdapter.new params
		when :redland
			$logger.info 'loading Redland adapter'
			require 'adapter/redland/redland_adapter'
			@@_connection = RedlandAdapter.new
		else
			raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, invalid adapter.")
		end
		return @@_connection
		
	end
		
	# 
	# * _uri_  
	# * _returns_ BasicIdentifiedResource  
	def self.create_basic_identified_resource(uri)
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Resource hash not initialised.") if resources.nil?
		raise(NodeFactoryError, 'In #{__FILE__}:#{__LINE__}, Resource URI is invalid. Cannot instanciated the object.') if uri.nil?
		
		if resources.key?(uri)
			return resources[uri]
		else
			resources[uri] = BasicIdentifiedResource.new(uri)
			return resources[uri]
		end
	end
		
	# 
	# * _uri_  
	# * _attributes_  
	# * _returns_ IdentifiedResource  
	def self.create_identified_resource(uri, attributes = nil)
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Resource hash not initialised.") if resources.nil?
		raise(NodeFactoryError, 'In #{__FILE__}:#{__LINE__}, Resource URI is invalid. Cannot instanciated the object.') if uri.nil?
		
		if resources.key?(uri)
			resource = resources[uri]
			resource.update_attributes(attributes) unless attributes.nil?
			return resource
		else

			$logger.debug "creating new resource #{uri}"
			
			# try to instantiate object as class defined by the localname of its rdf:type, 
			# e.g. a resource with rdf:type foaf:Person will be instantiated using Person.create
			type = Resource.get(NodeFactory.create_basic_identified_resource(uri), NamespaceFactory.get(:rdf_type))
			
			if type.nil?

				$logger.debug "initialising #{uri}; didn't find rdf:type, falling back to type Resource"

				# if type unknown, create toplevel resource
				resource = IdentifiedResource.new(uri, attributes)
			else

				$logger.debug "found #{uri} has rdf:type #{type}"

				# create a resource in correct subclass
				# if multiple types known, instantiate as first specific type known
				if type.is_a?(Array)
					type.each do |t|
						if Module.constants.include?(t.local_part)
							resource = instantiate_resource(uri, t, attributes)
							break
						end
					end
				else
					resource = instantiate_resource(uri, type, attributes)
				end
			end

			# if we didn't find any type to instantiate it to, we instantiate it as 
			# top-level resource
			resource = IdentifiedResource.new(uri, attributes) if resource.nil?
		end
		resources[uri] = resource
	end
	
	# 
	# * _id_  
	# * _attributes_  
	# * _returns_ AnonymousResource  
	def create_anonymous_resource(id, attributes = nil)
			
	end
		
	# 
	# * _value_  
	# * _type_  
	# * _returns_ Literal  
	def self.create_literal(value, type)
		return Literal.new(value, type)
	end
		
	# 
	# * _returns_ Bag  
	def create_bag()
			
	end
	
	# 
	# * _returns_ Alt  
	def create_alt()
			
	end
	
	# 
	# * _returns_ Seq  
	def create_seq()
			
	end
	
	# 
	# * _returns_ Collection  
	def create_collection()
			
	end
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private

  # Return the resources Hash
	def self.resources
		return @@_resources
	end

  # Instantiate a resource with this related class
  #
  # Arguments:
  # * +uri+ [<tt>String</tt>]: Uri of the resource to instantiate
  # * +type+ [<tt>BasicIdentifiedResource</tt>]: Type of the resource
	def self.instantiate_resource(uri, type, attributes = nil)
		# Arguments verification
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Uri of the resource to instantiate is nil.") if uri.nil?
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Type of the resource to instantiate is nil.") if type.nil?
		unless type.kind_of?(BasicIdentifiedResource)
			raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Type of the resource to instantiate is invalid.")
		end
		
		$logger.debug "initialising #{uri} to type #{type}"

		class_name = type.local_part

		# If it is a known class but not a Resource class, we instantiate it into the
		# correct class.
		# If it is a Resource class, we instantiate it into a IdentifiedResource.
		# Otherwise, we instantiate it into a BasicIdentifiedResource.
		if Module.constants.include?(class_name) and
			 class_name != 'Class' and class_name != 'Resource'
				# loading the predicates from the schema for this class
				(eval class_name).predicates
				return (eval class_name).new(uri, attributes)
		elsif class_name == 'Resource'
			return IdentifiedResource.new(uri, attributes)
		else
			return BasicIdentifiedResource.new(uri)
		end
	end

end

