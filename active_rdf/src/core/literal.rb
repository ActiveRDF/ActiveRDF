# = literal.rb
#
# Definition of model class for RDF Literal object. Wrap value and type of a RDF
# literal attribute.
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

require 'core/node'

class Literal; implements Node

	# Value of the literal
	attr_accessor :value
		
	# Type of the literal
	attr_accessor :type

	# Initialize method of the class model for RDF literal.
	#
	# Arguments:
	# * +value+: Value of the RDF literal
	# * +type+ [<tt>String</tt>]: Type of the RDF literal
	def initialize(value, type)
		self.value = value
		self.type = type
	end
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#
	
	public
	
	# Create a new Literal.
	# Determine the type of the value.
	#
	# Arguments:
	# * +value+: Value of the Literal
	#
	# Return:
	# * [<tt>Literal</tt>] The new Literal node
	def self.create(value)
		type = determine_type(value)
		return NodeFactory.create_literal(value.to_s, type)
	end

	def to_s
		return value
	end

	def ==(b)
		return eql?(b)
	end

	def eql?(b)
		if b.class == self.class
			return b.value == value
		else
			return false
		end
	end

	def hash
		value.hash
	end

	def <=>(b)
		if b.kind_of? Literal
			value <=> b.value
		else
			to_s <=> b.to_s
		end
	end

	
#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#

 	private
  
	# Determine the value type of the literal.
	#
	# Arguments:
	# * +value+: Value of the Literal
	#
	# Return:
	# * [<tt>String</tt>] Value type
	def self.determine_type(value)
		return 'Literal type is not yet implemented.'
	end
	
end

