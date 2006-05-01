# = ntriples_generator.rb
#
# Manage the generation of N-Triples query.
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf//>
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
# * TODO: Implement the order_by method
#

require 'query_generator/abstract_generator'

class NTriplesQueryGenerator < AbstractQueryGenerator

	@variables = {}  
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Create the select clause for the n3 query
	#
	# Arguments:
	# * +bindings+ [<tt>Array</tt>]: Array of binding variables in the select clause.
	#				 				 Binding variables is an array containing the triples which must
	#				 				 be returned.
	#
	# Return:
	# [<tt>String</tt>] Select part of the n3 query
	def self.select(bindings)
		select_template = ''

		raise(BindingVariableError, "No binding variables received.") if bindings.nil? or bindings.empty?

		# If the first element of bindings is an Array, it is a binding triple
		# else it is binding variables.
		if bindings.first.instance_of?(Array)
			$logger.debug "Triple binding: #{bindings.first.inspect}" 
			s = convert_subject(bindings.first[0])
			p = convert_predicate(bindings.first[1])
			o = convert_object(bindings.first[2])
			select_template << "#{s} #{p} #{o} ."
		else
			$logger.debug "Variable binding: #{bindings.inspect}" 
			select_template << " ( "
  			bindings.each { |binding|
  				raise(WrongTypeQueryError, "Symbol expected, #{binding.class} received") unless binding.instance_of?(Symbol)
  				select_template << "?#{binding.to_s} "
  			}
			select_template << ") ."
		end
		$logger.debug "Select clause: #{select_template}" 

		return select_template
	end

	# Create the where clause for the query
	#
	# Arguments:
	# * +conditions+ : Array of ActiveRDF::Resource, Symbol and Standard types.
	#					 ActiveRDF::Resource for resource and predicate,
	#					 Symbol for binding variable
	#					 Standard types for Literal.
	#
	# Return:
	# [<tt>String</tt>] Where clause of the Sparql query
	def self.where(conditions, keyword_match)
		# Init where template
		where_template = String.new

		conditions.each do |s, p, o|
			subject = convert_subject(s)
			predicate = convert_predicate(p)
			if o.kind_of?(Array)
				o.each { |resource| 
					object = convert_object(resource)
					where_template << "\t #{subject} #{predicate} #{add_keyword(o) if keyword_match} #{object} . \n"
				}
			else
				object = convert_object(o)
				where_template << "\t #{subject} #{predicate} #{add_keyword(o) if keyword_match} #{object} . \n"
			end
		end
		# remove last \n
		return where_template.chomp
	end

	# Add keyword command for each object.
	#
	# Arguments:
	# * +obj+: Add the keyword command only on Literal object
	#
	# Return:
	# * [<tt>String</tt>] The part of the where clause with the keyword search command
	def self.add_keyword(obj)
		if obj.is_a?(Resource)
			return ""
		else
			# creating unique placeholder variable for the keyword search, using a 
			# random number and checking if we have already generated this exact 
			# placeholder before
			#
			# resulting query will be something like
			# select {?s ?p ?o .}
			# where {?s :title ?keyword12345 . ?keyword12345 yars:keyword "test" .}
			raise(ActiveRdfError, 'too many conditions for keyword search') if @variables.size > 100
			while @variables[variable = '?keyword' + rand(100).to_s]
				;
			end
			@variables[variable] = true
			return " #{variable} . #{variable} <http://sw.deri.org/2004/06/yars#keyword> "
		end
	end

	def self.order_by(order_opt)

	end
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	public

	# Generate the query string. Abstract method. Need to be implemented in each
	# Generator.
	#
	# Arguments:
	# * +bindings+ [<tt>Array</tt>]: An array of Symbol (binding variables)
	# * +conditions+ [<tt>Array</tt>]: An array of array containing each conditions.
	# * +order_opt+ [<tt>Array</tt>]: An array containing binding variables need to be used
	#								  to order the query result.
	# * +keyword_match+ [<tt>Bool</tt>]: Activate or not the keyword searching.
	#
	# Return:
	# * [<tt>String</tt>] The query string.
	def self.generate(bindings, conditions, order_opt = nil, keyword_match = false)

		template_query = <<END_OF_QUERY
@prefix ql: <http://www.w3.org/2004/12/ql#> . 
<> ql:distinct {
#{select(bindings)}
}; 
ql:where {
#{where(conditions, keyword_match)}
} .
#{order_by(order_opt)}
END_OF_QUERY
		
		return template_query
	end
  
end

