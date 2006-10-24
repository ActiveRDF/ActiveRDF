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

require 'logger'

# initialize our logger
$log =
  begin
    # us the rails logger if running under rails
    RAILS_DEFAULT_LOGGER 
  rescue NameError
    unless ENV['ACTIVE_RDF_LOG'].nil?
      # write to environment variable $RDF_LOG if set
      Logger.new(ENV['ACTIVE_RDF_LOG'], 1, 100*1024) 
    else
      require 'tmpdir'
      # else just write to the temp dir
      Logger.new(Dir.tmpdir.to_s + "/activerdf.log", 1, 100*1024); 
    end
  end
    
# if user has specified loglevel we use that, otherwise we use default level
# in the environment variable ACTIVE_RDF_LOG_LEVEL we expect numbers, which we have to convert
if ENV['ACTIVE_RDF_LOG_LEVEL'].nil?
  $log.level = Logger::WARN
else
  $log.level = ENV['ACTIVE_RDF_LOG_LEVEL'].to_i
end

$log.info "ActiveRDF started, logging level: #{$log.level}"

class Module
  def bool_accessor *syms
    attr_accessor(*syms)
    syms.each { |sym| alias_method "#{sym}?", sym }
    remove_method(*syms)
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
		# skipping not installed adapters
	rescue StandardError
		# skipping buggy adapters (see e.g. bug #64952)
  end
end

#determine if we are installed as a gem right now:
if Gem::cache().search("activerdf").empty?
  #we are not running as a gem
  $log.info 'ActiveRDF is NOT installed as a Gem'
  require 'rdflite'
else
  #we are indeed running as a gem
  require 'gem_plugin'
  $log.info 'ActiveRDF is installed as a Gem'
  GemPlugin::Manager.instance.load "activerdf" => GemPlugin::INCLUDE
end 
