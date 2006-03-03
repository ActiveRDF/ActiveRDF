# = abstract_adapter.rb
#
# Abstract Class Definition for adapters
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

require 'misc/abstract_class'

module AbstractAdapter

	# Type of query language (N3, Sparql)
	attr_reader :query_language
	
	# Abstract method to be implemented in subclasses.
	abstract :query, :add, :remove, :delete

	def query
	end

	def add s,p,o
	end

	def remove s,p,o
	end

	def delete qs
	end
end
