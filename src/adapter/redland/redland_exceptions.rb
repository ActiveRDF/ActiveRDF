# = redland_exceptions.rb
#
# Exceptions happened in Redland Adpater
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

class RedlandAdapterError < StandardError
end

class SparqlQueryFailed < RedlandAdapterError
end

class StatementAdditionRedlandError < RedlandAdapterError
end

class StatementRemoveRedlandError < RedlandAdapterError
end

class UnknownResourceError < RedlandAdapterError
end

