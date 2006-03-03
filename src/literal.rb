# = literal.rb
#
# Class definition of Literal object. Wrap value and type of a RDF literal attribute.
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

require 'node'

class Literal; implements Node

	# Value of the literal
	attr_accessor :value
		
	# Type of the literal
	attr_accessor :type
				
	def initialize(value, type)
		self.value = value
		self.type = type
	end
	
end

