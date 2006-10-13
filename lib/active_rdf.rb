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
      Logger.new(Dir.tmpdir.to_s + "/active_rdf.log", 1, 100*1024); 
    end
  end
  
# if user has specified loglevel we use that, otherwise we use default level
# in the environment variable ACTIVE_RDF_LOG_LEVEL we expect numbers, which we have to convert
$log.level = 
  case ENV['ACTIVE_RDF_LOG_LEVEL']
    when "0": Logger::DEBUG
    when "1": Logger::INFO
    when "2": Logger::WARN
    when "3": Logger::ERROR
    when "4": Logger::FATAL
    when "5": Logger::UNKOWN 
    else      Logger::WARN
  end

$log.info "ActiveRDF 0.9.1 started"

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
    #log: including adapter abc
    require adapter
  rescue LoadError
		# skipping not installed adapters
	rescue StandardError
		# skipping buggy adapters (see e.g. bug #64952)
  end
end

# now load all the adapters known to gem_plugin`s automatic loading mechanism
require 'gem_plugin'
GemPlugin::Manager.instance.load "activerdf" => GemPlugin::INCLUDE
# TODO: figure out how to differenciate between gem_plugins only depending on activerdf and those which are also in the catgeory adapter

