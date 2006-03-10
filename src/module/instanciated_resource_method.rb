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
# == To-do
#
# * To-do 1
#

module InstanciatedResourceMethod

#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	# Saves the current identified  or anonymous resource (self) to RDF storage
	def save()
		NodeFactory.connection.add(self, NamespaceFactory.get(:rdf_type), class_URI)
		
		# save all property values. we use self.predicates hash to know the original 
		# URIs of all predicates (we lost those when converting to attributes)
		self.class.predicates.each do |attr_localname, attr_fullname|
			object = @attributes[attr_localname]
			
			unless object.nil?
				# to save the triple we need the full URI of the predicate
				predicate = attr_fullname
				
				# if an attribute is an array, we save all constituents sequentially, 
				# e.g. person.publications = ['article1', 'article2']
				
				# First, we remove all triples related to (subject, predicate)
				NodeFactory.connection.remove(self, predicate, nil)
				
				# then save the new value
				if object.is_a? Array
					object.each do |realvalue|
						NodeFactory.connection.add(self, predicate, realvalue)
					end
				else
					NodeFactory.connection.add(self, predicate, object)
				end
			end
		end		
	end
	
	# Delete all triples with self as subject.
	# With Redland, return the number of triples removed.
	def delete()
		# Delete all triples related to the subject (self)
		NodeFactory.connection.remove(self, nil, nil)
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Provides instance methods for all attributes e.g. person.age 
	def method_missing(method_id, *args)
		method_name = method_id.to_s

		if !_attributes.nil? and _attributes.include?(method_name)
			read_attribute(method_name)
		elsif md = /(=|\?)$/.match(method_name)
			attribute_name = md.pre_match
			method_type = md.to_s
			case method_type
			when '='
				write_attribute(attribute_name, args.first)
			when '?'
				query_attribute(attribute_name)
			end
		else
			super
		end			
	end

end

