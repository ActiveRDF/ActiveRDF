# = instanciated_resource_method.rb
#
# Definition of the mixin which contains the instance method to manage resources,
# like save, delete, and the dynamic generation of the attribute accessors.
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

module InstanciatedResourceMethod

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	# Saves the current identified  or anonymous resource (self) to RDF storage
	def save
		# save resource into database
		NodeFactory.connection.add(self, NamespaceFactory.get(:rdf_type), class_URI)

		# update the cache
		NodeFactory.resources[self.uri] = self
		
		# and save the (updated) attributes into database
		save_attributes
	end
	
	# Delete all triples with self as subject.
	# With Redland, return the number of triples removed.
	# Delete all instance references in the predicates hash of AttributeContainer.
	# Delete the reference of the resource in the resources hash of the NodeFactory.
	# Freeze the object to don't allow future change.
	def delete()
		# Delete all triples related to the subject (self)
		NodeFactory.connection.remove(self, nil, nil)
		# Delete all instance references in the predicates hash of AttributeContainer
		self.class.remove_predicates(uri)
		# Delete the attributes hash in AttributeContainer
		@_attributes.clear
		@_attributes = nil
		# Delete the reference in the NodeFactory
		NodeFactory.resources.delete(uri)
		# Freeze the object to don't allow future change
		freeze
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Provides instance methods for all attributes e.g. person.age 
	def method_missing(method_id, *args)
		method_name = method_id.to_s
		
		# If _attributes is nil, we need to load it from the DB
		if _attributes.nil?
			initialize_attributes
		end

		# We try to find the method name in the attributes hash
		if !_attributes.nil? and _attributes.include?(method_name)
			attribute = read_attribute(method_name)
			
			# If attribute is already an resource (or an array of resource), we 
			# return the instance, if it is a literal, we return the value of the literal
			if attribute.nil? or attribute.kind_of?(Resource) or attribute.kind_of?(Array)
				return attribute
			elsif attribute.kind_of?(Literal)
				return attribute.value
			else
				raise(ResourceAttributeError, "In #{__FILE__}:#{__LINE__}, attribute have invalid type : #{attribute.class}.")
			end
		# Or we try to match the method name with one of the method (write or query)
		elsif md = /(=|\?)$/.match(method_name)
			attribute_name = md.pre_match
			method_type = md.to_s
			case method_type
			when '='
				write_attribute(attribute_name, args.first)
			when '?'
				query_attribute(attribute_name)
			end
		# Otherwise, this attribute doesn't exist
		else
			super
		end			
	end

end

