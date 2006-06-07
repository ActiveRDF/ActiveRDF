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

require 'logger'
require 'tmpdir'
require 'activerdf_exceptions'
require 'core/literal'
require 'core/resource'
require 'core/identified_resource'
require 'core/anonymous_resource'
require 'core/standard_classes'

class NodeFactory

	# The cache of ActiveRDF::Node. The cache can be a hash (memory of localhost)
	# or a memcache client object, using a memcache server.
	@@cache = nil
	
	# Saved parameter of the connection. Used to slect a new context.
	@@default_host_parameters = {}
	
	# The hash of all instantiated connection (one connection for each context)
	@@connections = {}
	
	# The current connection instantiated
	@@current_connection = nil
	
	# Root context hash key
	ROOT_CONTEXT = ''
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#
	
public

<<<<<<< TREE
	# default settings for undefined parameters
	def self.default_parameters
		return 	{
				:cache_server => :memory,
				:host => 'localhost',
				:adapter => :yars,
				:port => 8080,
				:context => ROOT_CONTEXT,
				:construct_class_model => true,
				:construct_schema => false,
				:proxy => nil,
				:logger => Dir.tmpdir + '/activerdf.log',
				:logger_level => Logger::FATAL
				}
	end
=======
  # default settings for undefined parameters
  def self.default_parameters
    return { :cache_server => :memory, :host => 'localhost', :adapter => :yars, :port => 8080, :context => ROOT_CONTEXT, :construct_class_model => true, :construct_schema => false, :proxy => nil, :logger => Dir.tmpdir + '/activerdf.log', :logger_level => Logger::FATAL }
  end
    
>>>>>>> MERGE-SOURCE

	# Initialise cache and connection to data source.  If no parameter given, we 
	# return the previous instantiated connection. 
	#
	# Available parameters, possible values and default values
	# * +:adapter+ => :yars, :redland, :sparql, :jena (default :yars)
	# * +:construct_class_model+ => boolean (default true)
	# * +:construct_schema+ => boolean (default false)
	# * +:cache_server+ => 'host-url' or :memory (default :memory)
	# * +:proxy+ => 'proxy-url' or ProxyClass (default nil)
	# * +:logger+ => File (default tmpdir/activerdf.log)
	# * +:logger_level+ => Logger::Level (default Logger::FATAL)
	#
	# Hash of parameters for adapter yars:
	# * +:host+ => Host of the yars server
	# * +:port+ => y default 8080
	# * +:context+ => 'context-url', by default the root context
	# Hash of parameters for adapter redland:
	# * +:location+ => 'file-path' or :memory (default /tmp/test-store)
	def self.connection(params = {})
    
		# if no parameters given, and connection already established earlier,
		# return that connection
		if params.empty? and not @@current_connection.nil?
			return @@current_connection
		end

		# use default parameters for the unspecified parameters
		params = default_parameters.merge(params)
		
		# setup the logger	
		$logger = Logger.new params[:logger]
 		$logger.level = params[:logger_level]		
    
		# Initialize cache system
 		init_cache(params[:cache_server] || params[:host])
		
		# Initialize DB adapter
		connection = init_adapter(params)
		
		# Save the parameter
		@@default_host_parameters = params
		
		return connection
	end
  
	def self.correct_adapter_for_context(context, adapter)
		if @@connections.include?(context)
			case adapter
			when :redland
				@@connections[context].class.name == 'RedlandAdapter'
			when :yars
				@@connections[context].class.name == 'YarsAdapter'
			else
				false
			end
		else
			false
		end
	end

	# Initialize the DB adapter. Instantiate the connection and save it in the
	# connection hash.
	def self.init_adapter(params)
		context = params[:context]
    
		# if we already have a connection for that context and it is the right
		# adapter type, return it
		if correct_adapter_for_context(params[:context], params[:adapter])
			return @@connections[context] unless @@connections[context].nil?
		end

		case params[:adapter]
		when :yars
			$logger.debug 'loading YARS adapter'
			require 'adapter/yars/yars_adapter'
			
			begin 
				connection = YarsAdapter.new(params)
			rescue YarsError => e
				raise(ConnectionError, e.message)
			end
			
		when :redland
			$logger.debug 'loading Redland adapter'
			require 'adapter/redland/redland_adapter'
			
			connection = RedlandAdapter.new(params)
		else
			raise(ConnectionError, 'invalid adapter')
		end

		# saving the connection into connection_pool
		@@connections[context] = connection
		
		# Update the current connection
		@@current_connection = connection
	
		# constructing the class model
		construct_class_model if params[:construct_class_model]

		return connection		
	end
	
	# Initialize the cache system. The cache system can be a ruby hash in the
	# localhost memory or a memcache client using a memcache server.
	#
	# Arguments:
	# * +host+ [<tt>undefined</tt>]: A string representing the host adress, an
	# array containing multiple string representing different host adress or
	# :memory. By default, :memory.
	def self.init_cache(host = nil)
		case host
		when :memory, NilClass
			@@cache = Hash.new

		when String, Array
			require 'rubygems'
			require 'memcache'

			hosts = [host] if host.kind_of?(String)
			begin
				@@cache = MemCache.new
				@@cache.servers = hosts.collect {|_host| MemCache::Server.new(_host) }
			rescue MemCache::MemCacheError => e
				raise ActiveRdfError("Cache server not accessible: #{e.message}")
			end
			$logger.debug "MemCache initialised with servers #{hosts.inspect}."
		else
			raise(ActiveRdfError, "Invalid parameter #{host.inspect}. Cannot initialize ActiveRDF cache.")
		end			
	end
	
	# Selects a context to use by default. Invoke multiple times to
	# continuously change context of following data manipulations.
	# If the parameter is nil, use the root context.
	def self.select_context(context = ROOT_CONTEXT)
		raise(ConnectionError, 'No parameter connection given. Cannot select a context.') if @@default_host_parameters.empty?

		$logger.info "changing to context #{context}"

		@@default_host_parameters[:context] = context

		if @@connections[context].nil?
			@@current_connection = init_adapter(@@default_host_parameters)
		else
			@@current_connection = @@connections[context]
		end
		$logger.debug "available connections: #@@connections"

		return @@current_connection
	end
	
	def self.get_contexts(params)
		case params[:adapter]
		when :yars      
			connection = YarsAdapter.new(params.merge(:context => nil))
			qs = <<EOF
			@prefix yars: <http://sw.deri.org/2004/06/yars#> . 
			@prefix ql: <http://www.w3.org/2004/12/ql#> . 
 
			<>  ql:distinct { (?c).  }; 
					ql:where { { ?s ?p ?o .} yars:context ?c . } . 
EOF
			return connection.query(qs)
		else
			raise ConnectionError,'querying for contexts not supported yet'
		end
	end
	
	# You don't have to use this method. This method is used internaly in ActiveRDF.
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]: The uri of the basic resource to instantiate
	#
	# Return:
	# * [<tt>IdentifiedResource</tt>] A Basic IdentifiedResource.
	def self.create_basic_resource(uri)
		# if resources[uri] exists (cache) and is not nil, then we return that
		# otherwise, we create the new resource, store it in the cache and return it
		$logger.debug "CREATE_BASIC_RESOURCE : #{uri}"
		
		#IdentifiedResource.new(uri)
		begin
			if resources[uri].nil?
				$logger.debug "-cache miss for: #{uri}"
				resources[uri] = IdentifiedResource.new(uri)
			else
				$logger.debug "+cache hit for: #{uri}"
				resources[uri]
			end
			
		rescue StandardError => e
			raise ActiveRdfError, "cache problem: #{e.message}"
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

		unless resources[uri].nil?
			$logger.debug "creating resource #{uri}; found in cache"
			begin
				return resources[uri]
			rescue StandardError => e
				puts e.message
			end
		else
			create_resource_and_store_in_cache uri, klass
		end
	end
	
	def self.create_resource_and_store_in_cache(uri, klass)
		$logger.debug "creating resource #{uri}; not found in cache"
		# try to instantiate object as class defined by the localname of its rdf:type, 
		# e.g. a resource with rdf:type foaf:Person will be instantiated using Person.create
		type = Resource.get(NodeFactory.create_basic_resource(uri), NamespaceFactory.get(:rdf,:type))
		
		$logger.debug "create_identified_resource - type = " + type.to_s
		
		if type.nil?
			# if type unknown and klass given, create klass resource
			if not klass.nil?
				resource = instantiate_resource(uri, klass)
			# otherwise, create top level resource
			else
				resource = IdentifiedResource.new(uri)
			end
		else
			# adapter should return an Array
			raise(AdapterError) unless type.is_a? Array
			 
			# create a resource in correct subclass
			# if multiple types known, instantiate as first specific type known
			#
			type.each do |t|
				# rdf:type Literal or BNode are outside our type system
				next unless t.is_a? IdentifiedResource 

				found_klass = t.to_class_name
				if Object.const_defined?(found_klass.to_sym)

					if !klass.nil? 
						if klass != IdentifiedResource 
							if found_klass != klass.to_s
								raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, trying to instantiate a #{klass} as type #{found_klass}.")
							end
						end
					end
					
					resource = instantiate_resource(uri, found_klass.to_class)
					break
				end
			end
		end
	
		# if we didn't find any type to instantiate it to and klass given, create klass resource
		if resource.nil? and not klass.nil?
			resource = instantiate_resource(uri, klass)
		# otherwise, create top level resource
		elsif resource.nil?
			resource = IdentifiedResource.new(uri)
		end

		resources[uri] = resource

		resource
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
		#$logger.debug 'clearing the cache'

		case @@cache.class.name
		when 'Hash'
			@@cache.clear
		when 'MemCache'
			require 'rubygems'
			require 'memcache'
			@@cache.flush_all
		end

		@@default_host_parameters = {}
		@@connections = {}
		@@current_connection = nil
	end
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

private

	# constructs the class model from a RDF dataset
	def self.construct_class_model
		qe = QueryEngine.new
		qe.add_binding_variables :s
		qe.add_condition(:s, NamespaceFactory.get(:rdf,:type), NamespaceFactory.get(:rdfs,:Class))
		all_types = qe.execute
		$logger.info "found #{all_types.size} types in #{connection.context}"

		klasses = all_types.collect do |type|
			construct_class(type, qe) if type.kind_of?(Resource)
		end
		##for type in all_types do
		##	unless type.kind_of?(Resource)
		##		raise(NodeFactoryError, "received literal #{type} instead as resource type")
		##	end
		##	klasses << construct_class(type, qe)
		##end

		klasses.uniq.each do |klass|
			# and loading all attributes into the class
			get_class_attributes_from_data klass, qe
		end
	end

	# constructs a class from an RDF resource (using its local_name as class name)
	def self.construct_class(type, qe)
		## TODO: setup context inside class

		class_name  = type.to_class_name
		unless Object.const_defined? class_name.to_sym
			klass = Object.module_eval("#{class_name} = Class.new IdentifiedResource")
			klass.set_class_uri type.uri
			$logger.info "created class #{class_name}"
			klass
		else
			Object.const_get(class_name)
		end
	end

	# fetches the attribute of a type from the database, and adds them to the 
	# class of that type
	def self.get_class_attributes_from_data klass, qe
		qe.add_condition(:s, NamespaceFactory.get(:rdf,:type), NamespaceFactory.get(:rdf,:Property))
		qe.add_condition(:s, NamespaceFactory.get(:rdfs,:domain), klass.class_URI)
		qe.add_binding_variables :s

		all_attributes = qe.execute
		for attribute in all_attributes
			begin
				klass.add_predicate(attribute, attribute.to_method_name)
				$logger.info "added attribute #{attribute} to class #{klass}"
			rescue ActiveRdfError
				$logger.warn "found empty attribute in class #{klass}"
			end
		end
	end

	# Return the resources Hash of the MemCache client instance
	def self.resources
		raise(ActiveRdfError, 'Cache is not initialised yet') if @@cache.nil?
		@@cache
	end

	# Instantiate a resource with this related class
	#
	# Arguments:
	# * +uri+ [<tt>String</tt>]: Uri of the resource to instantiate
	# * +class_name+ [<tt>String</tt>]: Class of the resource to isntantiate
	def self.instantiate_resource(uri, klass)
		# Arguments verification
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Uri of the resource to instantiate is nil.") if uri.nil?
		raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Class name of the resource is nil.") if klass.nil?
		#raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Invalid Class name.") if klass.nil?
		
		unless rdf_classes_without_properties.include?(klass.to_s)
			## TODO: does this if really make sense?
			klass.send(:predicates) if klass.respond_to?(:predicates)
		end
		return klass.send(:new,uri)
	end

	def self.rdf_classes_without_properties
		%w{RdfsClass RdfProperty IdentifiedResource}
	end

	def self.protected_ruby_classes
		%w{Class Resource Property}
	end
end

class IdentifiedResource
	def to_class_name
    # converting under_score_separators into CamelCase
		class_name = local_part.gsub(/(_|-)(.)/) { $2.upcase }
    
    case class_name
		when 'Class'
			'RdfsClass'
		when 'Property'
			'RdfProperty'
		when 'Resource'
			'IdentifiedResource'
		when ''
			raise ActiveRdfError, "empty class name #{self}"
		else
			class_name
		end
	end

	def to_method_name
		local_part.underscore.gsub('-','_')
	end
end


class String
	def to_class
		class_name = self
		raise ActiveRdfError if NodeFactory.protected_ruby_classes.include?(self)
		if Object.const_defined?(class_name)
			Object.const_get(class_name)
		else
			return IdentifiedResource
		end
	end

	def underscore
	  gsub(/::/, '/').
	      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
	      gsub(/([a-z\d])([A-Z])/,'\1_\2').
	      tr("-", "_").
	      downcase
	end
end
