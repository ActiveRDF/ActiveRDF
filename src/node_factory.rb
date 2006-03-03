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
		elsif !@@_connection.nil?
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
			@@_connection = RedlandAdapter.instance
		else
			raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, invalid adapter.")
		end
		return @@_connection
		
	end
		
	# 
	# * _uri_  
	# * _returns_ BasicIdentifiedResource  
	def self.create_basic_identified_resource(uri)
		raise(NodeFactoryError, "Resource hash not initialised.") if resources.nil?
		
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
	def create_identified_resource(uri, attributes = nil)
			
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

	def self.resources
		return @@_resources
	end

end

