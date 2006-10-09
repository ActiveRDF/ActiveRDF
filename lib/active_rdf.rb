# Loader of ActiveRDF library
#
# Author:: Eyal Oren and Renaud Delbru
# Copyright:: (c) 2005-2006 Eyal Oren and Renaud Delbru
# License:: LGPL

# adding active_rdf subdirectory to the ruby loadpath
file =
if File.symlink?(__FILE__)
  File.readlink(__FILE__)
else
  __FILE__
end

$: << File.dirname(File.expand_path(file)) + '/active_rdf/'
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
dir = File.dirname(File.expand_path(file))
Dir[dir + "/active_rdf/adapter/*.rb"].each do |adapter|
  begin
    require adapter
  rescue LoadError
    p "problem loading adapter #{adapter}"
  end
end
