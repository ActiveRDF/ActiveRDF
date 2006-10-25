# Loader of ActiveRDF library
#
# Author:: Eyal Oren and Renaud Delbru
# Copyright:: (c) 2005-2006 Eyal Oren and Renaud Delbru
# License:: LGPL

# adding active_rdf subdirectory to the ruby loadpath
file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))
$: << this_dir
$: << this_dir + '/active_rdf/'

require 'active_rdf_helpers'
require 'active_rdf_log'

$log.info "ActiveRDF started, logging level: #{$log.level}"

# load standard classes that need to be loaded at startup
require 'objectmanager/resource'
require 'objectmanager/namespace'
require 'federation/connection_pool'
require 'queryengine/query'


def load_adapter s
  begin
    require s
  rescue StandardError
  end
end


#determine if we are installed as a gem right now:
if Gem::cache().search("activerdf").empty?
  #we are not running as a gem
  $log.info 'ActiveRDF is NOT installed as a Gem'
	load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/rdflite'
	load_adapter this_dir + '/../activerdf-redland/lib/activerdf_redland/redland'
  load_adapter this_dir + '/../activerdf-sparql/lib/activerdf_sparql/sparql'
  load_adapter this_dir + '/../activerdf-yars/lib/activerdf_yars/jars2'
else
  #we are indeed running as a gem
	require 'gem_plugin'
  $log.info 'ActiveRDF is installed as a Gem'
  GemPlugin::Manager.instance.load "activerdf" => GemPlugin::INCLUDE
end 
  
