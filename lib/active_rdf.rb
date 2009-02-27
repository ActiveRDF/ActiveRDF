
require 'rubygems'

# ActiveRDF loader

# Provide (partial) reasoning for RDF and RDFS only
$activerdf_internal_reasoning = true

# TODO: is this functionality needed?
$activerdf_without_datatype = false

# determine the directory in which we are running depending on cruby or jruby
if RUBY_PLATFORM =~ /java/
  # jruby can not follow symlinks, because java does not know the symlink concept
  this_dir = File.dirname(File.expand_path(__FILE__))
else
  file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
  this_dir = File.dirname(File.expand_path(file))
end

# set the load path, which uses the running directory, but has to be different if running on jruby directly from source.
if RUBY_PLATFORM =~ /java/ and Gem::cache.search(/^activerdf$/).empty?
  $: << this_dir + '/activerdf/lib/'
  $: << this_dir + '/activerdf/lib/active_rdf/'
else
  $: << this_dir + '/'
  $: << this_dir + '/active_rdf/'
end

require 'active_rdf_helpers'
require 'active_rdf_log'

$activerdflog.info "ActiveRDF started, logging level: #{$activerdflog.level}"

# load standard classes that need to be loaded at startup
require 'objectmanager/namespace'
require 'objectmanager/resource'
require 'objectmanager/resource_query'
require 'objectmanager/property'
require 'objectmanager/property_lookup'
require 'objectmanager/bnode'
require 'objectmanager/literal'
require 'federation/connection_pool'
require 'queryengine/query'
require 'federation/active_rdf_adapter'

def load_adapter s
  begin
    require s
  rescue Exception => e
    $activerdflog.info "could not load adapter #{s}: #{e}"
  end
end


# determine whether activerdf is installed as a gem:
if Gem::cache.search(/^activerdf$/).empty?
  # we are not running as a gem
  $activerdflog.info 'ActiveRDF is NOT installed as a Gem'
  if RUBY_PLATFORM =~ /java/
    load_adapter this_dir + '/activerdf/activerdf-jena/lib/activerdf_jena/init'
    load_adapter this_dir + '/activerdf/activerdf-sparql/lib/activerdf_sparql/sparql'
    #load_adapter this_dir + '/../activerdf-sesame/lib/activerdf_sesame/sesame'
  else
    load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/rdflite'
    load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/fetching'
    load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/suggesting'
    load_adapter this_dir + '/../activerdf-redland/lib/activerdf_redland/redland'
    load_adapter this_dir + '/../activerdf-sparql/lib/activerdf_sparql/sparql'
    #load_adapter this_dir + '/../activerdf-yars/lib/activerdf_yars/jars2'
  end

else
  # we are running as a gem
  require 'gem_plugin'
  $activerdflog.info 'ActiveRDF is installed as a Gem'
  GemPlugin::Manager.instance.load "activerdf" => GemPlugin::INCLUDE
end

