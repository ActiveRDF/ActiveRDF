# = dynamic_query_method.rb
#
# This module contains the dynamic construction of query methods.
# These methods provide a way to query the DB to find and load resources.
# For example, the resource type Person (which have attributes : name, surname)
# will have the query method find_by_name, find_by_surname, find_by_name_and_surname. 
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

module DynamicQueryMethod

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Overrides method_missing to provide find_by_* for each attribute (e.g. 
	# find_by_name)
	#
	# The find_by_* methods return a Resource or an array of Resources
	def method_missing(method_id, *args)
		method_name = method_id.to_s
		
		if match = /find_by_(keyword_)?([_a-zA-Z]\w*)/.match(method_name)
			# Extract all attribute names
			keyword_search = true unless match[1].nil?

			attribute_names = extract_attribute_names_from_match(match[2])

			# Verify if all attributes exist
			raise(ActiveRdfError, "method #{method_name} not found") unless all_attributes_exists(attribute_names)

			# Call find method with good parameters
			call_find_from_args(attribute_names, keyword_search, *args)
		else
			super
		end				
	end
		
	# Create a condition hash and executes query.
	#
	# Arguments:
	# * +attribute_names+ [<tt>Array</tt>]: array of attribute_names (e.g. [name, homepage])
	# * +keyword_search+ [<tt>Bool</tt>]: Activate the keyword search
	# * +*args+ [<tt>Array</tt>]: array of arguments (e.g. ['eyal', 'http:/....'])
	#
	# Return:
	# * [<tt>Array</tt>] Array of Resource 
	def call_find_from_args(attribute_names, keyword_search, *args)
		arg_number = args.length
		attr_number = attribute_names.length
		str_error = "In #{__FILE__}:#{__LINE__}, #{attr_number} arguments waited, only #{arg_number} arguments given"
		raise(WrongNumberArgumentError, str_error) if (attr_number != arg_number)
		
		conditions = Hash.new
		attribute_names.each_index { |index|
			if args[index].kind_of?(IdentifiedResource) or args[index].kind_of?(Array)
				conditions[attribute_names[index].to_sym] = args[index]
			else
				conditions[attribute_names[index].to_sym] = Literal.create(args[index])
			end
		}
		return self.find(conditions, { :keyword_search => keyword_search })				
	end
	
	# Verify if all attributes extracted from method match exist. 
	def all_attributes_exists(attributes)
		contains = attributes.all? { |atr| self.predicates.key? atr }
		return contains				
	end
	
 	# Extract all attribute names from the method name which match
	def extract_attribute_names_from_match(attributes_names)
		return attributes_names.split('_and_')
	end
	
end

