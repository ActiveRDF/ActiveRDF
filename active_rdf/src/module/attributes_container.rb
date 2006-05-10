# = attribute_container.rb
#
# Contains all predicates of Resource object and attributes and instance method
# of instanciated resources (e.g. Person)
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

module AttributesContainer

	# @@predicates is a Hash from each class to (a Hash) of its predicates, e.g.
	# [ Person => { homepage => http://foaf/homepage, firstName => 
	# http://foaf/firstName }, Agent => { ... }, ...]
	@@predicates = Hash.new
	
	# attributes hash contains the attribute values for this instance and a boolean
	# to know if the attribute value has been changed.
	# e.g. {firstName => ['Eyal', false]} if we haven't changed the name
	# e.g. {firstName => ['Eyal', true]} if we have changed the name
	# e.g. {firstName => nil} if the value is not yet loaded
	attr_reader :_attributes
	private :_attributes

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#
	
	public

	# Gets attribute value
	#
	# Arguments:
	# * +attr_name+ [<tt>String</tt>]: Attribute name
	def [](attr_name)
		read_attribute(attr_name)
	end
	
	# Sets attribute value
	#
	# Arguments:
	# * +attr_name+ [<tt>String</tt>]: Attribute name
	# * +value+: Attribute value
	def []=(attr_name, value)
		write_attribute(attr_name, value)
	end

	# Updates all the attributes from the passed-in Hash and saves the record.
	# Returns whether saving succeeded
	#
	# Arguments:
	# * +attributes+ [<tt>Hash</tt>]: Hash of attributes to update
	def update_attributes(attributes)
		# Parameter verification
		if attributes.nil?
			raise(ResourceUpdateError, "In #{__FILE__}:#{__LINE__}, attributes hash is nil.")
		end

		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end
		
		# Convert attributes value into Literal
		converted_attributes = Hash.new
		attributes.each { |attr_name, value|
			if value.nil?
				converted_attributes[attr_name.to_s] = [nil, true]
			elsif value.kind_of?(Resource) or value.kind_of?(Array)
				converted_attributes[attr_name.to_s] = [value, true]
			else
				converted_attributes[attr_name.to_s] = [Literal.create(value), true]
			end
		}
				 
		# Verification of attributes existence
		unknown_attributes = converted_attributes.keys - self.class.predicates.keys
		if !unknown_attributes.empty?
			raise(ResourceUpdateError, "In #{__FILE__}:#{__LINE__}, unknown attribute received during update: #{unknown_attributes.inspect}.") 
		end
		
		# We update the attributes hash with the new
		@_attributes.update(converted_attributes)
		save		
	end

	# Checks if attribute value exists
	#
	# Arguments:
	# * +attr_name+ [<tt>String</tt>]: Attribute name
	#
	# Return:
	# * [<tt>Bool</tt>] True if attributes value exists
	def query_attribute(attr_name)
		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end
		
		# If we have just loaded the attributes, _attributes[attr_name.to_s] == nil
		attribute = _attributes[attr_name.to_s].nil? ? nil : _attributes[attr_name.to_s][0]
		
		if attribute.nil?
				false
		elsif attribute.kind_of?(Literal) && attribute.value == 0
				false
		elsif attribute.kind_of?(Literal) && attribute.value == "0"
				false
		elsif attribute.kind_of?(Literal) && attribute.value.empty?
				false
		elsif attribute.kind_of?(Literal) && attribute.value == false
				false
		elsif attribute.kind_of?(Literal) && attribute.value == "f"
				false
		elsif attribute.kind_of?(Literal) && attribute.value == "false"
				false
		else
				true
		end
	end

	# Get the list of dynamic attributes
	#
	# Return:
	# * [<tt>Array</tt>] An array containing the dynamic attribute names
	def attributes
		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end

		$logger.debug 'Get list of dynamic attributes : ' + _attributes.keys.inspect

		return _attributes.keys
	end
	
	def predicates
		return @@predicates[self.class]
	end

#----------------------------------------------#
#               CLASS METHODS                  #
#----------------------------------------------#

	# Included dynamically Class Method defined here during the inclusion of the module.
	def self.included(klass)
		klass.module_eval do
		
		# DEFINITION OF CLASS METHODS
		
			# Return the hash of predicates for the related class.
			# Fetch predicates if they are not loaded.
			#
			# Return:
			# * [<tt>Hash</tt>] Hash of predicates for the related class.
			def self.predicates()
				class_hash = @@predicates[self]
				
				$logger.debug "in #{self}.predicates; class_hash is #{class_hash}."
				
				if class_hash.nil?
					class_hash = Hash.new
					
					$logger.info "loading attributes from schema, in class #{self}"
					
					Resource.find_predicates(self.class_URI).each do |localname, full_URI|
						# the uri of the corresponding predicate, e.g. http://xmlns.com/foaf/firstName
						class_hash[localname] = NodeFactory.create_basic_resource(full_URI)
						
						$logger.debug "loading attribute #{localname} from schema into class #{self}"
					
					end
					@@predicates[self] = class_hash
				end
				
				return class_hash				
			end
			
			# Called by delete method of InstanciateResourceMethod to delete reference
			# of the resource in the predicates hash.
			#
			# Arguments:
			# * +key+: Key of the predicates. Can be a Class (for class level predicates)
			# or a String (for instance level predicates).
			def self.remove_predicates(key)
				@@predicates.delete(key)
			end
			
		# END OF DEFINITION
			
		end
	end
				
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Write attribute and update the database.
	#
	# Arguments:
	# * +attr_name+ [<tt>String</tt>]: Attribute name
	# * +value+: Attribute value
	def write_attribute(attr_name, value)
		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end
		
		if value.nil?
			@_attributes[attr_name.to_s] = [nil, true]
		elsif value.kind_of?(Resource) or value.kind_of?(Array)
			@_attributes[attr_name.to_s] = [value, true]
		else
			@_attributes[attr_name.to_s] = [Literal.create(value), true]
		end

		# NOTE: we do not save data automatically, uncomment this to automatically save 
		# all changes directly into the database
		#save
	end

	# Return attribute value.
	# Fetch attribute value from database if it is not loaded.
	#
	# Arguments:
	# * +attr_name+ [<tt>String</tt>]: Attribute name
	#
	# Return:
	# * Value of the attribute
	def read_attribute(attr_name)
		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end

		if !_attributes.key?(attr_name.to_s) or _attributes[attr_name.to_s].nil?
		
			if self.class.predicates[attr_name.to_s].nil?
				raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, predicates doesn't exist for the attribute : #{attr_name.to_s}")
			end
			
			predicate_uri = self.class.predicates[attr_name.to_s]
			value = Resource.get(self, predicate_uri)
			

			# extracting the value from the returned Array (resource.get always returns an Array)			
			database_value = 
			case value.size
			when 0:
				nil
			when 1:
				value[0]
			else
				value
			end

			# storing the read value in the cache, stating that it has not been changed (yet)
			@_attributes[attr_name.to_s] = [database_value, false]
			
			#if value.nil? or value.kind_of?(Node) or value.kind_of?(Array)
			#		@_attributes[attr_name.to_s] = [value, false]
			#else
			#	raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, value have invalid type : #{value.class}")
			#end
			return _attributes[attr_name.to_s][0]
		else
			return _attributes[attr_name.to_s][0]
		end
	end
	
	# Initialize the attributes hash for the instance. Load from the DB all the attributes
	# name.
	def initialize_attributes
		@_attributes = Hash.new
		self.class.predicates.each_key do |attr_name|
			@_attributes[attr_name] = nil
		end
	end
	
	# save all property values. we use self.predicates hash to know the original 
	# URIs of all predicates (we lost those when converting to attributes)
	def save_attributes()

		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end
		
		self.class.predicates.each do |attr_localname, attr_fullname|
			object = @_attributes[attr_localname]
			
			# to save the triple we need the full URI of the predicate
			predicate = attr_fullname
			
			# if an attribute is an array, we save all constituents sequentially, 
			# e.g. person.publications = ['article1', 'article2']
			
			# First, we remove all triples related to (subject, predicate) only if
			# the attribute values have changed
			if not object.nil? and object[1]
				NodeFactory.connection.remove(self, predicate, nil)
			end
			
			# then save the new value, if the value have changed and the value is not nil
			if not object.nil? and object[1] and not object[0].nil? and object[0].is_a?(Array)
				object[0].each do |realvalue|
					NodeFactory.connection.add(self, predicate, realvalue)
				end
			elsif not object.nil? and object[1] and not object[0].nil?
				NodeFactory.connection.add(self, predicate, object[0])
			end
		end
	end

end

