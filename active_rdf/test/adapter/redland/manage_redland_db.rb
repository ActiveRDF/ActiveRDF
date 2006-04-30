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

def setup_redland(context = nil)
	dirname = File.dirname(__FILE__)
	
	`cp #{dirname}/../../test_set_person.rdf /tmp/`
	if context.nil?
		`cd /tmp/; rm -rf test-store*`
		`cd /tmp/; rdfproc test-store parse file:test_set_person.rdf`
	else
		`cd /tmp/; rdfproc test-store remove-context #{context} -c`
		`cd /tmp/; rdfproc test-store parse-stream file:test_set_person.rdf rdfxml 'http://m3pe.org/activerdf/test/' #{context} -c`
	end
	
	# Delete all instances in the resources hash of the NodeFactory
	NodeFactory.clear
end

def delete_redland(context = nil)
	if context.nil?
		`cd /tmp/; rm -rf test-store*`
	else
		`cd /tmp/;  rdfproc test-store remove-context #{context} -c`
	end
	
	# Delete all instances in the resources hash of the NodeFactory
	NodeFactory.clear
end
