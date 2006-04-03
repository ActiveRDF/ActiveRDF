# = manage_redland_db.rb
#
# Method definition for adding and delete data on the Redland DB.
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

def setup_redland
	dirname = File.dirname(__FILE__)
	
	`cp #{dirname}/../../test_set_person.rdf /tmp/`
	`cd /tmp/; rm -rf test-store*`
	`cd /tmp/; rdfproc test-store parse file:test_set_person.rdf`
	
	# Delete all instances in the resources hash of the NodeFactory
	NodeFactory.clear
end

def delete_redland
	`cd /tmp/; rm -rf test-store*`
	
	# Delete all instances in the resources hash of the NodeFactory
	NodeFactory.clear
end
