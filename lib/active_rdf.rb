# ActiveRDF loader

# Provide (partial) reasoning for RDF and RDFS only  (Default: false)
$activerdf_internal_reasoning = false  

# If true, disable datatype support (Default: false)
$activerdf_without_datatype = false

require 'active_rdf/helpers'
require 'active_rdf/logger'


# load standard classes that need to be loaded at startup
require 'active_rdf/namespace'
require 'active_rdf/model/resource'
require 'active_rdf/model/resource_query'
require 'active_rdf/model/property'
require 'active_rdf/model/property_lookup'
require 'active_rdf/bnode'
require 'active_rdf/literal'
require 'active_rdf/storage/connection_pool'
require 'active_rdf/query/query'
require 'active_rdf/storage/store'


ActiveRdfLogger::log_info "ActiveRDF loaded, logging level: #{ActiveRdfLogger::logger.level}"

#begin
#  require 'activerdf_rdflite/rdflite'
#rescue Exception => e
#  # require 'debug'
#  # debugger
#  # libs = $:
#  require 'pp'
#  pp $:
#  raise e
#end

#begin
#  ActiveRDF::ConnectionPool.load_adapter(:rdflite)
#rescue Exception => e
#  p e.inspect
#  require 'pp'
#  pp $:
#  raise ActiveRDF::ActiveRdfError
#end

### Uncomment this block if you wish to preload adapters
# if ENV['ACTIVE_RDF_ADAPTERS'].nil?
#   if RUBY_PLATFORM =~ /java/
#     ActiveRDF::ConnectionPool.load_adapter(:jena)
#     ActiveRDF::ConnectionPool.load_adapter(:sparql)
#     ActiveRDF::ConnectionPool.load_adapter(:sesame)
#   else
#     ActiveRDF::ConnectionPool.load_adapter(:rdflite)
#     ActiveRDF::ConnectionPool.load_adapter(:redland)
#     ActiveRDF::ConnectionPool.load_adapter(:sparql)
#   end
# else
#   # load specified adapters
#   # for example: ENV['ACTIVE_RDF_ADAPTERS'] = "redland,sparql"
#   ENV['ACTIVE_RDF_ADAPTERS'].split(",").uniq.each do |adapter|
#     ActiveRDF::ConnectionPool.load_adapter(adapter)
#   end
# end

