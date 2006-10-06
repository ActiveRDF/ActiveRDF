# Loader of ActiveRDF library
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved

# adding active_rdf subdirectory to the ruby loadpath
file =
if File.symlink?(__FILE__)
  File.readlink(__FILE__)
else
  __FILE__
end

$: << File.dirname(File.expand_path(file)) + '/src'
$: << File.dirname(File.expand_path(file))

class ActiveRdfError < StandardError
end


class Module
  def bool_accessor *syms
    attr_accessor *syms
    syms.each { |sym| alias_method "#{sym}?", sym }
    remove_method *syms
  end
end

# load standard classes that need to be loaded at startup
require 'objectmanager/resource'
require 'objectmanager/namespace'
require 'federation/connection_pool'
require 'queryengine/query'

# load all adapters, discard errors because of failed dependencies
Dir["./src/adapter/*.rb"].each do |adapter|
	begin
		require adapter
	rescue LoadError
	end
end
