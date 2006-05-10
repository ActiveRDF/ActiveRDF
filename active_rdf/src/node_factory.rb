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
	ROOT_CONTEXT = 'root'
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#
	
public

	# Initialise cache and connection to data source.
	# If no parameter given, we return the previous instantiated connection is
	# returned. A new connection is created for every context.
	# If no context is given, the root context is used by default.
	#
	# Hash of parameters for cache:
	# * +:cache_server+ => HOST or :memory
	# Hash of parameters for adapter yars:
	# * +:adapter+ => :yars
	# * +:host+ => Host of the yars server
	# * +:port+ => Listen port of the yars server, by default 8080
	# Hash of parameters for adapter redland:
	# * +:adapter+ => :redland
	# * +:location+ => path to file or :memory, by default /tmp/test-store
	# For all adapter:
	# * +:context+ => CONTEXT, by default the root context
	def self.connection(params = nil)
		if params.nil?
			raise(ConnectionError, 'no parameters defined') if @@current_connection.nil?
			return @@current_connection
		end
		
		# Initialize cache system
		init_cache(params[:cache_server] || params[:host])
		
		# Initialize DB adapter
		connection = init_adapter(params)
		
		# Save the parameter
		@@default_host_parameters = params
		
		return connection
	end
	
	# Initialize the DB adapter. Instantiate the connection and save it in the
	# connection hash.
	def self.init_adapter(params)
		context = params[:context] || ROOT_CONTEXT
		return @@connections[context] unless @@connections[context].nil?
	
		case params[:adapter]
		when :yars
			$logger.debug 'loading YARS adapter'
			require 'adapter/yars/yars_adapter'
			connection = YarsAdapter.new(params)
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
		construct_class_model

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
	def self.select_context(context = nil)
		raise(ConnectionError, 'No parameter connection given. Cannot select a context.') if @@default_host_parameters.empty?

		$logger.info "changing to context #{context}"

		@@default_host_parameters[:context] = context

		context = ROOT_CONTEXT if context.nil?
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
 
			<>  ql:select { (?c).  }; 
					ql:where { { ?s ?p ?o .} yars:context ?c . } . 
EOF
			return connection.query(qs)
		else
			raise ConnectionError,'querying for contexts not supported yet'
		end
	end
	
#	EYAL CODE
	
#	# Selects a context to use by default. Invoke multiple times to continuously change context of following 
#	# data manipulations.
#	def self.select_context(context = nil)
#		#raise ConnectionError, 'invalid context' if context.nil?
#		raise ConnectionError, 'no host specified' if @@default_host_parameters.empty?
#		$logger.info "changing to context #{context}"
#		adapter_params = @@default_host_parameters.merge({:context => context})
#		@@current_connection = (@@connections[context] ||= init_adapter(adapter_params))
#		$logger.debug "available connections: #@@connections"
#	end
#	
#	def self.get_contexts params
#		case params[:adapter]
#		when :yars
#			connection = YarsAdapter.new(params.merge(:context => ''))
#			qs = <<EOF
#			@prefix yars: <http://sw.deri.org/2004/06/yars#> . 
#			@prefix ql: <http://www.w3.org/2004/12/ql#> . 
# 
#			<>  ql:select { (?c).  }; 
#					ql:where { { ?s ?p ?o .} yars:context ?c . } . 
#EOF
#			connection.query qs
#		else
#			raise ConnectionError,'querying for contexts not supported yet'
#		end
#	end
#
#	# Initialises connection to data source. Connections are used to execute 
#	# queries on a datasource.
#	#
#	# Params is a hash of parameters such as (depending on the adapter to be 
#	# used) :adapter => :yars, :context => 'test'.
#	#
#	# Connections can only be used if a context has been defined. If invoked 
#	# with only host parameters a host will be setup that cannot be used until a 
#	# context has been specified.
#	#
#	# If only a :context parameter is given and a host has previously been 
#	# defined, the context will be used within that host, and the connection to 
#	# that context will be returned
#	def self.connection(params = nil)
#		if params.nil?
#			raise(ConnectionError, 'no parameters defined') if @@current_connection.nil?
#			return @@current_connection
#		end
#
#		host = params[:host]
#		context = params[:context]
#		port = params[:port]
#
#		if context.nil?
#			# we are initialising a host 
#			raise(ConnectionError, 'no host or context defined') if host.nil?
#			@@default_host_parameters = params
#			return true
#		else
#			if host.nil?
#				if @@default_host_parameters.empty?
#					raise(ConnectionError, 'no host known but only context defined')
#				else
#					host = @@default_host_parameters
#				end
#			else
#				# storing the host parameters (except the context) as default (for a possible next time) 
#				@@default_host_parameters = params
#			end
#
#			# init cache if necessary
#			init_cache(params) if @@cache.nil?
#
#			# return the earlier established connection for this context if it exists, 
#			# or establish one otherwise
#			@@current_connection = @@connections[context] || init_adapter(@@default_host_parameters.merge(params))
#			$logger.debug "NodeFactory returning current connection: #{connection}"
#			return @@current_connection
#		end
#	end
#
#	def self.init_adapter params
#		case params[:adapter]
#		when :yars
#			$logger.debug 'loading YARS adapter'
#			require 'adapter/yars/yars_adapter'
#			connection = YarsAdapter.new(params)
#		when :redland
#			$logger.debug 'loading Redland adapter'
#			require 'adapter/redland/redland_adapter'
#			connection = RedlandAdapter.new(params)
#		else
#			raise(ActiveRdfError, 'invalid adapter')
#		end
#
#		# saving the connection into connection_pool
#		@@connections[params[:context]] = connection
#		return connection
#	end
#
#	# initialises memcached server
#	def self.init_cache params
#		cache_server = params[:cache_server] || params[:host]
#		if cache_server.kind_of? String
#			cache_servers = [cache_server]
#		elsif cache_server.kind_of? Array
#			cache_servers = cache_server
#		else
#			raise(ActiveRdfError,'incorrect cache server specified')
#		end
#
#		begin
#			@@cache = MemCache.new
#			@@cache.servers = cache_servers.collect {|host| MemCache::Server.new host }
#		rescue MemCache::MemCacheError => e
#			raise ActiveRdfError("cache server not accessible: #{e.message}")
#		end
#		$logger.info "memcache initialised: #{@@cache.inspect}"
#	end




##	# Return the current instance of the connection. If no connection exists and 
##	# params given, instantiate a new connection.
##	#
##	# Arguments:
##	# * +params+ [<tt>Hash</tt>]: Connection parameter. Required only the first time, to initialize the connection.
##	#
##	# Return:
##	# * [<tt>AbstractAdapter</tt>] The current connection with the RDF DataBase.
##	def self.connection(params = nil)
##		if @@_connection.nil? and params.nil?
##			raise(ConnectionError, 'no parameters to instantiate connection')
##		elsif !@@_connection.nil? and params.nil?
##			return @@_connection
##		end
##
##		init_cache(params[:cache_server] || params[:host]) if @@cache.nil?
##	
##		case params[:adapter]
##		when :yars
##			$logger.debug 'loading YARS adapter'
##			require 'adapter/yars/yars_adapter'
##			@@_connection = YarsAdapter.new(params)
##		when :redland
##			$logger.debug 'loading Redland adapter'
##			require 'adapter/redland/redland_adapter'
##			@@_connection = RedlandAdapter.new(params)
##		else
##			raise(ActiveRdfError, 'invalid adapter')
##		end
##		return @@_connection
##	end





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
		
		begin
			
			if resources[uri].nil?
				$logger.debug "-cache miss for: #{uri}"
				resources[uri] = IdentifiedResource.new(uri)
			else
				$logger.debug "+cache hit for: #{uri}"
				resources[uri]
			end
			
		rescue MemCache::MemCacheError
			$logger.debug "ArgumentError in CREATE_BASIC_RESOURCE :" + $!
			raise
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
			return resources[uri]
		else
			$logger.debug "creating resource #{uri}; not found in cache"
			# try to instantiate object as class defined by the localname of its rdf:type, 
			# e.g. a resource with rdf:type foaf:Person will be instantiated using Person.create
			type = Resource.get(NodeFactory.create_basic_resource(uri), NamespaceFactory.get(:rdf_type))
			
			$logger.debug "create_identified_resource - type = " + type.to_s
			
			if type.nil?
				# if type unknown and klass given, create klass resource
				if not klass.nil?
					resource = instantiate_resource(uri, klass.to_s)
				# otherwise, create top level resource
				else
					resource = IdentifiedResource.new(uri)
				end
			else
				# adapter should return an Array
				raise(AdapterError) unless type.is_a? Array
				 
				# create a resource in correct subclass
				# if multiple types known, instantiate as first specific type known
				type.each do |t|
					# rdf:type Literal or BNode are outside our type system
					break unless t.is_a? IdentifiedResource 

					if Module.constants.include?(t.local_part)
						class_name = determine_class(t)

						if not klass.nil? and not klass == IdentifiedResource and not class_name.eql?(klass.to_s)
							raise(NodeFactoryError, "In #{__FILE__}:#{__LINE__}, Try to instantiate a #{klass.to_s} as type #{class_name}.")
						end
						
						resource = instantiate_resource(uri, class_name)
						break
					end
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
		$logger.debug 'create_identified_resource return - class = ' + resource.class.to_s

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
		$logger.debug 'clearing the cache'

		require 'rubygems'
		require 'memcache'
		
		case @@cache
		when Hash
			@@cache.clear
		when MemCache
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
		qe.add_binding_variables :o
		qe.add_condition(:s, NamespaceFactory.get(:rdf_type), :o)
		all_types = qe.execute
		$logger.info "found #{all_types.size} types in #{connection.context}"
		
		for type in all_types do
			
			if not type.kind_of?(Resource)
				raise(NodeFactoryError, "Get a Literal #{type} instead of a Resource for resource type.")
			end
			
			case type.local_part
			when 'Class', 'Resource'
				type = create_basic_resource(type.uri + 'Clashed')
			end

			construct_class(type, qe)
		end

		# I don't think we need to store the classes in the cache actually...
		# ActiveRDF NodeFactory will still run as a Singleton
	end

	# constructs a class from an RDF resource (using its local_name as class name)
	def self.construct_class(type, qe)
		# creating the class with the correct className and @@context variable
		context = @@current_connection.context
		setup_context = lambda do
			set_class_uri type.uri
			@@context = @@current_connection.context
		end

		class_name = make_class_name type
		unless self.const_defined? class_name
			eval "#{class_name} = Class.new IdentifiedResource, &setup_context" 
			$logger.info "created class #{class_name}"
		end

		# and loading all attributes into the class
		get_class_attributes_from_data type, qe
	end

	def self.make_class_name type
		type.local_part.delete('_').capitalize
	end

	# fetches the attribute of a type from the database, and adds them to the 
	# class of that type
	def self.get_class_attributes_from_data type, qe
		class_name = make_class_name(type)
		qe.add_binding_variables :p
		qe.add_condition(:s, NamespaceFactory.get(:rdf_type), type)
		qe.add_condition(:s, :p, :o)
		all_attributes = qe.execute
		for attribute in all_attributes
			begin
				self.const_get(class_name).add_predicate(attribute)
				$logger.info "added attribute #{attribute} to class #{class_name}"
			rescue ActiveRdfError
				$logger.warn "found empty attribute in class #{type.uri}"
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

		$logger.debug 'determine_class - uri type = ' + type.uri

		class_name = type.local_part

		$logger.debug 'determine_class - class_name = ' + class_name

		# If it is a known class but not a Resource class, we instantiate it into the
		# correct class.
		# Otherwise, we instantiate it into a IdentifiedResource.
		if Module.constants.include?(class_name) and
			class_name != 'Class' and class_name != 'Resource'
			
			$logger.debug 'determine_class - return = ' + class_name
			
			return class_name
		else
			$logger.debug 'determine_class - return = IdentifiedResource'
		
			return IdentifiedResource.to_s
		end
	end

end

