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
	
	abstract :query, :add, :remove, :save, :query_count

	# adds triple to datamodel, raises ActiveRdfError if adding fails
	def add!(s,p,o)
		add(s,p,o) || raise(ActiveRdfError)
	end

	# remove triple from datamodel, raises ActiveRdfError if deletion fails
	def remove!(s,p,o)
		remove(s,p,o) || raise(ActiveRdfError)
	end

	# save data, raises ActiveRdfError if saving fails
	def save!
		save || raise(ActiveRdfError)
	end

	# query datastore, raises ActiveRdfError if querying fails
	def query! qs
		query(qs) || raise(ActiveRdfError)
	end

	def query_count! qs
		query_count(qs) || raise(ActiveRdfError)
	end
end
