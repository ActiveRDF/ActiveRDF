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

require 'activerdf_exceptions'

require 'core/literal'
require 'core/resource'
require 'core/identified_resource'
require 'core/anonymous_resource'

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
			@@_connection = YarsAdapter.new(params)
		when :redland
			$logger.info 'loading Redland adapter'
			require 'adapter/redland/redland_adapter'
			@@_connection = RedlandAdapter.new(params)
		else
			raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, invalid adapter.")
		end
		return @@_connection
		
	end
	
	# You don't have to use this method. This method is used internaly in ActiveRDF.
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]: The uri of the basic resource to instantiate
	#
	# Return:
	# * [<tt>IdentifiedResource</tt>] A Basic IdentifiedResource.
	def self.create_basic_resource(uri)
		if resources.key?(uri)
			return resources[uri]
		else
			resources[uri] = IdentifiedResource.new(uri)
			return resources[uri]
		end
	end
		
	# Create a new identified resource.
	# If the resource exists in the database, it tries to instantiate it with the good
	# type. If no type is found, instantiate it as a IdentifiedResource.
	# Return just a reference to the resource if the resource is included in the resources
	# Hash.
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]:The uri of the resource to instantiate.
	#
	# Return:
	# * [<tt>IdentifiedResource</tt>] The resource instantiated
	def self.create_identified_resource(uri, klass = nil)
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Resource hash not initialised.") if resources.nil?
		raise(NodeFactoryError, 'In #{__FILE__}:#{__LINE__}, Resource URI is invalid. Cannot instanciated the object.') if uri.nil?
		
		if resources.key?(uri)
			resource = resources[uri]
			return resource
		else
			# try to instantiate object as class defined by the localname of its rdf:type, 
			# e.g. a resource with rdf:type foaf:Person will be instantiated using Person.create
			type = Resource.get(NodeFactory.create_basic_resource(uri), NamespaceFactory.get(:rdf_type))
			
			if type.nil?
				# if type unknown and klass given, create klass resource
				if not klass.nil?
					resource = instantiate_resource(uri, klass.to_s)
				# otherwise, create top level resource
				else
					resource = IdentifiedResource.new(uri)
				end
			else
				# create a resource in correct subclass
				# if multiple types known, instantiate as first specific type known
				if type.is_a?(Array)
					type.each do |t|
						if Module.constants.include?(t.local_part)
							class_name = determine_class(t)
							
							if not klass.nil? and not class_name.eql?(klass.to_s)
								raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Try to instantiate a resource with a wrong type.")
							end
							
							resource = instantiate_resource(uri, class_name)
							break
						end
					end
				else
					class_name = determine_class(type)
					
					if not klass.nil? and not class_name.eql?(klass.to_s)
						raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Try to instantiate a resource with a wrong type.")
					end
					
					resource = instantiate_resource(uri, class_name)
				end
			end
			
			# if we didn't find any type to instantiate it to and klass given, create klass resource
			if resource.nil? and not klass.nil?
				resource = instantiate_resource(uri, klass.to_s)
			# otherwise, create top level resource
			elsif resource.nil?
				resource = IdentifiedResource.new(uri)
			end
		end
		resources[uri] = resource
	end
	
	# 
	# * _id_  
	# * _attributes_  
	# * _returns_ AnonymousResource  
	def create_anonymous_resource(id)
			
	end
		
	# Create a new Literal
	#
	# Arguments:
	# * +value+: Literal value
	# * +type+: Literal value type (xsd:integer, etc.)
	#
	# Return:
	# * [<tt>Literal</tt>] A Literal node.
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
	
	# Clear the resources hash
  	def self.clear
  		resources.clear
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
	# * +class_name+ [<tt>String</tt>]: Class of the resource to isntantiate
	def self.instantiate_resource(uri, class_name)
		# Arguments verification
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Uri of the resource to instantiate is nil.") if uri.nil?
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Class name of the resource is nil.") if class_name.nil?
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Invalid Class name.") if class_name.empty?

		(eval class_name).predicates unless class_name == 'IdentifiedResource'
		return (eval class_name).new(uri)
	end

	# Determine the Class of the resource to instantiate.
	#
	# Arguments:
	# * +type+ [<tt>IdentifiedResource</tt>]: Type of the resource
	#
	# Return:
	# * [<tt>String</tt>] Class name of the resource.
	def self.determine_class(type)
		# Arguments verification
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, type is nil.") if type.nil?

		class_name = type.local_part

		# If it is a known class but not a Resource class, we instantiate it into the
		# correct class.
		# Otherwise, we instantiate it into a IdentifiedResource.
		if Module.constants.include?(class_name) and
			class_name != 'Class' and class_name != 'Resource'
			return class_name
		else
			return IdentifiedResource.to_s
		end
	end

end

