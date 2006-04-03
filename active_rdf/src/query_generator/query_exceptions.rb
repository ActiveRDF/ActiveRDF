# = query_exceptions.rb
#
# Exceptions happened in ActiveRDF library relating to Sparql query during generation
# or execution
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

class QueryError < StandardError
end

class WrongTypeQueryError < QueryError
end

class ConditionQueryError < QueryError
end

class NTriplesQueryError < QueryError
end

class LanguageUnknownQueryError < QueryError
end

class BindingVariableError < NTriplesQueryError
end

class WrapperError < NTriplesQueryError
end
