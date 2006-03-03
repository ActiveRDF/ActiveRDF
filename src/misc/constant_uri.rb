# = constant_uri.rb
#
# Load some URI as Ruby Constant.
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

RDFType = NodeFactory.create_basic_identified_resource('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
RDFSDomain = NodeFactory.create_basic_identified_resource('http://www.w3.org/2000/01/rdf-schema#domain')
RDFSSubClassOf = NodeFactory.create_basic_identified_resource('http://www.w3.org/2000/01/rdf-schema#subClassOf')
OwlThing = NodeFactory.create_basic_identified_resource('http://www.w3.org/2002/07/owl#Thing')