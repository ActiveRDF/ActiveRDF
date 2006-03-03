# = query_exceptions.rb
# Exceptions happened in ActiveRDF library relating to Sparql query during generation
# or execution
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
