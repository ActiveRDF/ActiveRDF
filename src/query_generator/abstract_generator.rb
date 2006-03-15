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
# == To-do
#
# * TODO: Generalize bindings variables in the two generator. Cause some problems
#					in Resource.find method
#

require 'node_factory'
require 'query_generator/query_exceptions'

class AbstractQueryGenerator

	private_class_method :new
  
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

  private
  
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
  
  def self.select(bindings)
  end
  
  def self.where(conditions)
  end
  
  def self.order_by(order_opt)
  end
  
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

  public

	def self.generate(bindings, conditions, order_opt = nil)
	end
  
end