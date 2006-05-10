# = abstract_generator.rb
#
# Abstract query generator.
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

require 'node_factory'
require 'query_generator/query_exceptions'

class AbstractQueryGenerator

	private_class_method :new
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

	private

	# Convert a Resource subject or a Symbol (binding variable) into a string.
	#
	# Arguments:
	# * +s+: The subject of a statement. Can be a Resource or a Symbol (binding variable)
	#
	# Return:
	# * [<tt>string</tt>] The subject converted into a string.
	def self.convert_subject(s)
		subject = String.new
	  
	  	# Case for the subject of the condition triple
	  	case s
		when Symbol
			subject << '?' << s.to_s
		when Resource
			subject << '<' << s.uri << '>'
		else
			raise(WrongTypeQueryError, "#{s.class} unexpected, wrong type received")
		end

		return subject
	end

	# Convert a Resource predicate or a Symbol (binding variable) into a string.
	#
	# Arguments:
	# * +s+: The predicate of a statement. Can be a Resource or a Symbol (binding variable)
	#
	# Return:
	# * [<tt>string</tt>] The predicate converted into a string.
	def self.convert_predicate(p)
		predicate = String.new
  
 		# Case for the predicate of the condition triple
		case p
		when Symbol
			predicate << '?' << p.to_s
		when Resource
			predicate << '<' << p.uri << '>'
		else
			raise(WrongTypeQueryError, "#{p.class} unexpected, wrong type received")
		end

		return predicate
	end

	# Convert a Node object or a Symbol (binding variable) into a string.
	#
	# Arguments:
	# * +s+: The object of a statement. Can be a Node or a Symbol (binding variable)
	#
	# Return:
	# * [<tt>string</tt>] The object converted into a string.
	def self.convert_object(o)
		object = String.new

		# Case for the object of the condition triple
		case o
		when Symbol
			object << '?' << o.to_s
		when IdentifiedResource
			object << '<' << o.uri << '>'
		when Literal
			case o.value
			when String
				object << '"' << o.value << '"'
			when Fixnum, Bignum, Float, TrueClass, FalseClass
				object = o.value
			end
		when AnonymousResource
			raise(WrongTypeQueryError, "BlankNode not implemented for the moment.")
		else
			raise(WrongTypeQueryError, "#{o.class} unexpected, wrong type received")
		end
	  	
		return object
	end

	# Generate the select clause. Abstract method. Need to be implemented in each
	# Generator.
	#
	# Arguments:
	# * +bindings+ [<tt>Array</tt>]: An array of Symbol (binding variables)
	#
	# Return:
	# * [<tt>String</tt>] The select clause of the query string.
	def self.select(bindings)
	end

	# Generate the where clause. Abstract method. Need to be implemented in each
	# Generator.
	#
	# Arguments:
	# * +conditions+ [<tt>Array</tt>]: An array of array containing each conditions.
	#
	# Return:
	# * [<tt>String</tt>] The where clause of the query string.
	def self.where(conditions)
	end
	
	# Add keywords search conditions.
	#
	# Arguments:
	# * +conditions+: Array of [Symbol (variable), String (keyword)].
	#
	# Return:
	# * [<tt>String</tt>] The part of the where clause with the keyword search command
	def self.keyword(conditions)
	end

	# Generate the order by clause. Abstract method. Need to be implemented in each
	# Generator.
	#
	# Arguments:
	# * +order_opt+ [<tt>Array</tt>]: An array containing binding variables need to be used
	#								  to order the query result.
	#
	# Return:
	# * [<tt>String</tt>] The order by clause of the query string.
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
	def self.generate(bindings, conditions, order_opt = nil)
	end
  
end