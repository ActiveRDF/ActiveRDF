# = person.rb
#
# Class definition of Person rdf data type, used in unit test of node factory.
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

require 'active_rdf'
require 'node_factory'

class Person < IdentifiedResource
	 classURI 'http://m3pe.org/activerdf/test/Person'
end

