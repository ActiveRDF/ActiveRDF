# = sesame_adapter.rb
#
# ActiveRDF Adapter to Sesame 2 storage
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

require 'adapter/abstract_adapter'
require 'adapter/sesame/sesame_tools'
require 'rjb'

class SesameAdapter; implements AbstractAdapter
	
	attr_reader :context, :query_language, :repository

  sesame_jars = Dir["#{File.dirname(__FILE__)}/lib/*.jar"].map { |jar| File.expand_path("#{jar}") }.join(File::PATH_SEPARATOR)
  Rjb::load sesame_jars

  module Sesame
    NativeStore = Rjb::import("org.openrdf.sesame.sailimpl.nativerdf.NativeStore")
    MemoryStore = Rjb::import("org.openrdf.sesame.sailimpl.memory.MemoryStore")
    MemoryStoreRDFSInferencer = Rjb::import("org.openrdf.sesame.sailimpl.memory.MemoryStoreRDFSInferencer")
    Repository = Rjb::import("org.openrdf.sesame.repository.Repository")
    File = Rjb::import("java.io.File")
    Statement = Rjb::import("org.openrdf.model.impl.StatementImpl")
    Uri = Rjb::import("org.openrdf.model.impl.URIImpl")
    Literal = Rjb::import("org.openrdf.model.impl.LiteralImpl")
    BNode = Rjb::import("org.openrdf.model.impl.BNodeImpl")
    ValueFactory = Rjb::import("org.openrdf.model.impl.ValueFactoryImpl")
    QueryLanguage = Rjb::import("org.openrdf.sesame.query.QueryLanguage")
    RDFFormat = Rjb::import("org.openrdf.rio.RDFFormat")
  end
  
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	# Instantiate the connection with the Yars DataBase.
	def initialize(params = {})
		if params.nil?
			raise(SesameError, "In #{__FILE__}:#{__LINE__}, Sesame adapter initialisation error. Parameters are nil.")
		end
		
    data_file = Sesame::File.new(params[:location])
    unless params[:no_inferencing]
      store = Sesame::MemoryStore.new(data_file)
    else
      store = Sesame::MemoryStoreRDFSInferencer.new(Sesame::MemoryStore.new(data_file))
    end
    @repository = Sesame::Repository.new(store)
    @repository.initialize

		@query_language = 'sparql'
    @adapter_type = :sesame

		$logger.debug("opened SESAME database at #{params[:location]}")
	end

	# Add the triple s,p,o in the database.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: Subject of triples
	# * +p+ [<tt>Resource</tt>]: Predicate of triples
	# * +o+ [<tt>Node</tt>]: Object of triples. Can be a _Literal_ or a _Resource_
	def add(s, p, o)
		# Verification of nil object
		return false if s.nil? or p.nil? or o.nil?
				
		# Verification of type
		return false if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)

		@repository.add(wrap(s), wrap(p), wrap(o))
		return true
	end

	# queries the RDF database and only counts the results
	def query_count(qs)
		if results = query(qs)
			results.size
		else
			false
		end
	end

	# query the RDF database
	#
	# qs is an n3 query, e.g. '<> ql:select { ?s ?p ?o . } ; ql:where { ?s ?p ?o . } .'
	def query(qs)
		return false if qs.nil?
		return false if qs.empty?
		
		iterator = @repository.evaluateTupleQuery(Sesame::QueryLanguage.SPARQL, qs)
		return convert_query_result_to_array(iterator)

	rescue => ex
		$logger.error "Error while trying to execute query (#{ex} - #{ex.backtrace.join(',')}): #{qs}"
		return false
	end

	# Delete a triple. Generate a query and call the delete method of Yars.
	# If an argument is nil, it becomes a wildcard.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: The subject of the triple to delete
	# * +p+ [<tt>Resource</tt>]: The predicate of the triple to delete
	# * +o+ [<tt>Node</tt>]: The object of the triple to delete
	def remove(s, p, o)
		# Verification of type
		return false if (!s.nil? and !s.kind_of?(Resource)) or
			 (!p.nil? and !p.kind_of?(Resource)) or
			 (!o.nil? and !o.kind_of?(Node))
    
   		@repository.remove(wrap(s), wrap(p), wrap(o))
   		return true
	end

	# Synchronise the model. For Sesame, it isn't necessary. Just return true.
	def save
		true
	end

end

