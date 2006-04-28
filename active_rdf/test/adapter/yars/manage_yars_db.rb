# = manage_yars_db.rb
#
# Method definition for adding and delete data on the Yars DB.
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

def setup_yars(context)
	dirname = File.dirname(__FILE__)
	`java -jar #{dirname}/yars-api-current.jar -d -u http://#{DB_HOST}:8080/#{context} #{dirname}/delete_all.nt`
	`java -jar #{dirname}/yars-api-current.jar -p -u http://#{DB_HOST}:8080/#{context} #{dirname}/../../test_set_person.nt`
	
	# Delete all instances in the resources hash of the NodeFactory
	#NodeFactory.init_cache DB_HOST
	NodeFactory.clear
end

def delete_yars(context)
	dirname = File.dirname(__FILE__)
	`java -jar #{dirname}/yars-api-current.jar -d -u http://#{DB_HOST}:8080/#{context} #{dirname}/delete_all.nt`
	
	# Delete all instances in the resources hash of the NodeFactory
	NodeFactory.clear
end
