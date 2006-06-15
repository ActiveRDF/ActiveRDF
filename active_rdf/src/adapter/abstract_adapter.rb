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

require 'misc/abstract_class'

module AbstractAdapter

	# Type of query language (N3, Sparql)
	attr_reader :query_language
	attr_reader :context
  attr_reader :adapter_type
	
	# Abstract method to be implemented in subclasses.
	#
	# * query(qs)
	# +qs+ [<tt>String</tt>]: query string
	# * add(s,p,o) and remove(s,p,o)
	# +s+ [<tt>Resource</tt>]: triple subject
	# +p+ [<tt>Resource</tt>]: triple predicate
	# +o+ [<tt>Node</tt>]: triple object
	# * save : no argument
	abstract :query, :add, :remove, :save

end
