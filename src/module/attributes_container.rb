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
# == To-do
#
# * To-do 1
#

module AttributesContainer

	# @@predicates is a Hash from each class to (a Hash) of its predicates, e.g.
	# [ Person => { homepage => http://foaf/homepage, firstName => 
	# http://foaf/firstName }, Agent => { ... }, ...]
	@@predicates = Hash.new
	
	# attributes hash contains the attribute values for this instance, e.g. 
	# firstName => 'Eyal'
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
		 
		# Verification of attributes existence
		unknown_attributes = _attributes.keys - self.class.predicates.keys
		if !unknown_attributes.empty? and !self.instance_of?(IdentifiedResource)
			raise(ResourceUpdateError, "In #{__FILE__}:#{__LINE__}, unknown attribute received during update: #{unknown_attributes.inspect}.") 
		end
		
		# We update the attributes hash with the new
		@_attributes.update(attributes)
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
			attribute = _attributes[attr_name]
			if attribute.nil?
					false
			elsif attribute.kind_of?(Fixnum) && attribute == 0
					false
			elsif attribute.kind_of?(String) && attribute == "0"
					false
			elsif attribute.kind_of?(String) && attribute.empty?
					false
			elsif attribute == false
					false
			elsif attribute == "f"
					false
			elsif attribute == "false"
					false
			else
					true
			end
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
						class_hash[localname] = NodeFactory.create_basic_identified_resource(full_URI)
						
						$logger.debug "loading attribute #{localname} from schema into class #{self}"
					
					end
					@@predicates[self] = class_hash
				end
				
				return class_hash				
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
		@_attributes[attr_name.to_s] = value
		save
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
		if !_attributes.key?(attr_name) or _attributes[attr_name].nil?
		
			if self.class.predicates[attr_name].nil?
				raise(ActiveRdfError, "In #{__FILE__}:#{__LINE__}, predicates doesn't exist for the attribute : #{attr_name}")
			end
			
			predicate_uri = self.class.predicates[attr_name]
			value = self.class.get(self, predicate_uri)
			
			$logger.debug "loading value of #{attr_name} from datastore: value #{value}"
			
			@_attributes[attr_name] = value
			return value
		else
			return _attributes[attr_name]
		end
	end

end

