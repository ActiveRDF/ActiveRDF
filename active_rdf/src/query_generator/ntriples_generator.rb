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

		if bindings.nil? or bindings.empty?
			raise(BindingVariableError, "No binding variables received.")
		end

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
  				if not binding.instance_of?(Symbol)
  					raise(WrongTypeQueryError, "Symbol expected, #{binding.class} received")
  				end
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
	def self.where(conditions)
		# Init where template
		where_template = String.new

		conditions.each do |s, p, o|
			subject = convert_subject(s)
			predicate = convert_predicate(p)
			if o.kind_of?(Array)
				o.each { |resource| 
					object = convert_object(resource)
					where_template << "\t #{subject} #{predicate} #{object} . \n"
				}
			else
				object = convert_object(o)
				where_template << "\t #{subject} #{predicate} #{object} . \n"
			end
		end
		# remove last \n
		return where_template.chomp
	end

	# Add keywords search conditions.
	#
	# Arguments:
	# * +conditions+: Array of [Symbol (variable), String (keyword)].
	#
	# Return:
	# * [<tt>String</tt>] The part of the where clause with the keyword search command
	def self.keyword(conditions)
		if conditions.nil?
			return ''
		end
		if not conditions.kind_of?(Array)
			raise(WrongTypeQueryError, "Invalid keyword search condition array received #{conditions.inspect}.")
		end

		# Init where template
		keyword_template = String.new
		yars_cmd = 'yars:keyword'
					
		for condition in conditions
			o = condition[0]
			object = convert_object(o)
			keyword = condition[1]
			keyword_template << "\t #{object} #{yars_cmd} \"#{keyword}\" . \n"
		end
		return keyword_template
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
	#
	# Return:
	# * [<tt>String</tt>] The query string.
	def self.generate(bindings, conditions, keywords = nil, order_opt = nil)
		$logger.debug "generating query:\n\t#{bindings.inspect}\n\t#{$loggeconditions.inspect}"

		template_query = <<END_OF_QUERY
@prefix yars: <http://sw.deri.org/2004/06/yars#> .
@prefix ql: <http://www.w3.org/2004/12/ql#> . 
<> ql:distinct {
#{select(bindings)}
}; 
ql:where {
#{where(conditions)}
#{keyword(keywords)}
} .
#{order_by(order_opt)}
END_OF_QUERY
		
		return template_query
	end
  
end

