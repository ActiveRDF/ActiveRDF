# = exceptions.rb
# Exceptions happened in ActiveRDF library
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

