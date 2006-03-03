# = yars_exceptions.rb
#
# Exceptions happened in Yars adpater
#
# == Project
#
# * ActiveRDF
# <http://WebAddress/>
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

class YarsError < StandardError
end

class WrapYarsError < YarsError
end

class StatementAdditionYarsError < YarsError
end

class QueryYarsError < YarsError
end

class NTriplesParsingYarsError < YarsError
end
