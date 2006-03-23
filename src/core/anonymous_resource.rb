# = anonymous_resource.rb
#
# DEfinition of the model class for RDF Anonymous Resource 
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

class AnonymousResource < Resource

	# 
	# * _uri_  
	# * _returns_ IdentifiedResource  
	def to_identified_resource(uri)
			
	end

	# Accessor Methods

	# Get the value of _id
	# 
	attr_reader :_id
			
	# Set the value of _id
	# 
	attr_writer :_id

end

