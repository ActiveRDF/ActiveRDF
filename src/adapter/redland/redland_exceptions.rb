# = redland_exceptions.rb
# Exceptions happened in Redland Adpater
# ----
# Project	: ActiveRDF
#
# See		: http://m3pe.org/activerdf/
#
# Author	: Renaud Delbru, Eyal Oren
#
# Mail		: first dot last at deri dot org
#
# (c) 2005-2006

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

