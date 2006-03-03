# = basic_identified_resource.rb
#
# Class definition of a basic identified resource.
# Use as a wrapper around URI, exclusively for resources which doesn't need complete
# instantiation.
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

require 'resource'

class BasicIdentifiedResource; implements Resource; extend Resource

	# URI of the resource
	attr_reader :uri
				
	def initialize(uri)
		@uri = uri
	end

end

