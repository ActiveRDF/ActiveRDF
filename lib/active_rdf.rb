
require 'rubygems'

# ActiveRDF loader

file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))  

$: << this_dir + '/'
$: << this_dir + '/active_rdf/'

require 'active_rdf_helpers'
require 'active_rdf_log'


# load standard classes that need to be loaded at startup
require 'objectmanager/resource_like'
require 'objectmanager/resource'
require 'objectmanager/bnode'
require 'objectmanager/literal'
require 'objectmanager/namespace'
require 'federation/connection_pool'
require 'queryengine/query'
require 'federation/active_rdf_adapter'

ActiveRdfLogger::log_info "ActiveRDF loaded, logging level: #{ActiveRdfLogger::logger.level}"

def load_adapter s
  begin
    require s
  rescue Exception => e
    ActiveRdfLogger::log_info "Could not load adapter #{s}: #{e}"
    #raise exception if the environment variable is specified
    raise ActiveRdfError, "Could not load adapter #{s}: #{e}" unless ENV['ACTIVE_RDF_ADAPTERS'].nil?
  end
end


# determine whether activerdf is installed as a gem:
if Gem::cache.search(/^activerdf$/).empty?
  # we are not running as a gem
  ActiveRdfLogger::log_info 'ActiveRDF is NOT installed as a Gem', self
  if ENV['ACTIVE_RDF_ADAPTERS'].nil?
    if RUBY_PLATFORM =~ /java/
      load_adapter this_dir + '/activerdf/activerdf-jena/lib/activerdf_jena/init'
      load_adapter this_dir + '/activerdf/activerdf-sparql/lib/activerdf_sparql/sparql'
      load_adapter this_dir + '/../activerdf-sesame/lib/activerdf_sesame/sesame'
    else
      load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/rdflite'
      load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/fetching'
      load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/suggesting'
      load_adapter this_dir + '/../activerdf-redland/lib/activerdf_redland/redland'
      load_adapter this_dir + '/../activerdf-sparql/lib/activerdf_sparql/sparql'
      #load_adapter this_dir + '/../activerdf-yars/lib/activerdf_yars/jars2'
    end
  else
    #load specified adapters
    #for example: ENV['ACTIVE_RDF_ADAPTERS'] = "redland,sparql"
    ENV['ACTIVE_RDF_ADAPTERS'].split(",").uniq.each { |adapterItem|  
      case adapterItem.strip.downcase 
      when "rdflite"
        load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/rdflite'
        load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/fetching'
        load_adapter this_dir + '/../activerdf-rdflite/lib/activerdf_rdflite/suggesting'
      when "redland"
        load_adapter this_dir + '/../activerdf-redland/lib/activerdf_redland/redland'
      when "sparql"
        load_adapter this_dir + '/../activerdf-sparql/lib/activerdf_sparql/sparql'
      when "jars"
        load_adapter this_dir + '/../activerdf-yars/lib/activerdf_yars/jars2'
      when "sesame"
        load_adapter this_dir + '/../activerdf-sesame/lib/activerdf_sesame/sesame'
      else
        ActiveRdfLogger::log_error "Unknown adapter #{name}"
        raise ActiveRdfError, "Unknown adapter #{name}"
      end
    }
  end
else
  # we are running as a gem
  require 'gem_plugin'
  ActiveRdfLogger::log_info 'ActiveRDF is installed as a Gem'
  GemPlugin::Manager.instance.load "activerdf" => GemPlugin::INCLUDE
end

