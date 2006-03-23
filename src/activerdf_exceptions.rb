# = activerdf_exceptions.rb
#
# Exceptions happened in ActiveRDF library
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

class ActiveRdfError < StandardError
end

class WrongNumberArgumentError < ActiveRdfError
end

class ResourceTypeError < ActiveRdfError
end

class ResourceDeleteError < ActiveRdfError
end

class ResourceSaveError < ActiveRdfError
end

class ResourceUpdateError < ActiveRdfError
end

class ResourceAttributeError < ActiveRdfError
end

class UriBrokenError < ActiveRdfError
end

class AdapterError < ActiveRdfError
end

class ConnectionError < ActiveRdfError
end

class NodeFactoryError < ActiveRdfError
end

class NamespaceFactoryError < ActiveRdfError
end

