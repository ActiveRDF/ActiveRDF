# = node.rb
#
# Abstract Class definition of an RDF node.
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

require 'misc/abstract_class'

module Node

	# Abstract method to be implemented in subclasses.
	# Create method call the create method of the NodeFactory related to the type
	# of node.
	abstract :create
	
end

