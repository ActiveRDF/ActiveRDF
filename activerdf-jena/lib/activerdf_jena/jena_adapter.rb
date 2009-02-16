#
# Author:  Karsten Huneycutt
# Copyright 2007 Valkeir Corporation
# License:  LGPL
#

class JenaAdapter < ActiveRdfAdapter

  class JenaAdapterConfigurationError < StandardError
  end

  class DataSourceDBConnection < Jena::DB::DBConnection

    attr_accessor :datasource, :connection

    def initialize(datasource, type)
      if datasource.kind_of? javax.sql.DataSource
        self.datasource = datasource
      else
        self.datasource = javax.naming.InitialContext.new.lookup(datasource)
      end
      self.setDatabaseType(type)
    end

    def getConnection
      if !self.connection || !valid_connection?(self.connection)
        self.connection = self.datasource.getConnection
      end
      self.connection
    end

    def close
      self.datasource = nil
    end

    def valid_connection?(cnxn)
      true
    end

  end

  ConnectionPool.register_adapter(:jena, self)

  bool_accessor :keyword_search, :reasoning
  bool_accessor :lucene_index_behind
  attr_accessor :ontology_type, :model_name, :reasoner, :connection
  attr_accessor :model_maker, :base_model, :model, :lucene_index
  attr_accessor :root_directory

  # :database
  #   either use :url, :type, :username, AND :password (for a
  #   regular connection) OR :datasource AND :type (for a container
  #   connection), default to memory data store
  #   example for a derby connection:
  #     :database => {:url => "jdbc:derby:superfunky;create=true", :type => "Derby", :username => "", :password => ""}
  # :file
  #   database wins over this, this wins over memory store.  parameter is
  #   a string or file indicating the root directory for all files.
  # :model
  #   name of model to use, default is jena's default
  # :ontology
  #   set to language type if this needs to be viewed as an ontology,
  #   default nil, available :owl, :owl_dl, :owl_lite, :rdfs
  #   pellet only supports owl reasoning.
  # :reasoner
  #   set to reasoner to use -- default nil (none).  options:  :pellet,
  #   :transitive, :rdfs, :rdfs_simple, :owl_micro, :owl_mini, :owl,
  #   :generic_rule
  # :lucene
  #   set to true to enable true lucene indexing of this store, default false
  def initialize(params = {})
    dbparams = params[:database]
    self.ontology_type = params[:ontology]
    self.reasoner = params[:reasoner]
    self.keyword_search = params[:lucene]

    # if the model name is not provided and file persistence is used, then jena just
    # creates random files in the tmp dir. not good, as we need to know the model name
    # to have persistence
    if params[:model]
      self.model_name = params[:model]
    else
      self.model_name = "default"
    end

    if params[:file]
      if params[:file].respond_to? :path
        self.root_directory = File.expand_path(params[:file].path)
      else
        self.root_directory = params[:file]
      end
    end

    # do some sanity checking
    if self.keyword_search? && !LuceneARQ.lucene_available?
      raise JenaAdapterConfigurationError, "Lucene requested but is not available"
    end

    if self.reasoner == :pellet && !Pellet.pellet_available?
      raise JenaAdapterConfigurationError, "Pellet requested but not available"
    end

    if self.reasoner && !self.ontology_type
      raise JenaAdapterConfigurationError, "Ontology model needed for reasoner"
    end

    if dbparams
      if dbparams[:datasource]
        self.connection = DataSourceDBConnection.new(dbparams[:datasource],
                                                     dbparams[:type])
      else
        begin
          if !Jena::DB.send("#{dbparams[:type].downcase}_available?")
            raise JenaAdapterConfigurationError, "database type #{dbparams[:type]} not available"
          end
        rescue NameError
          raise JenaAdapterConfigurationError, "database type #{dbparams[:type]} not recognized"
        end

        self.connection = Jena::DB::DBConnection.new(dbparams[:url],
                                                     dbparams[:username],
                                                     dbparams[:password],
                                                     dbparams[:type])
      end

      self.model_maker = Jena::Model::ModelFactory.createModelRDBMaker(connection)

    elsif self.root_directory
      self.model_maker = Jena::Model::ModelFactory.createFileModelMaker(self.root_directory)
    else
      self.model_maker = Jena::Model::ModelFactory.createMemModelMaker
    end


    self.base_model = self.model_maker.openModel(model_name)

    if self.ontology_type
      rf = map_reasoner_factory(self.reasoner)
      onturi = map_ontology_type(self.ontology_type)

      spec =
        Jena::Ontology::OntModelSpec.new(self.model_maker,
                                         Jena::Ontology::OntDocumentManager.new,
                                         rf, onturi)

      self.model = Jena::Model::ModelFactory.
        createOntologyModel(spec, self.base_model)
      self.reasoning = true
    else
      self.model = self.base_model
      self.reasoning = false
    end

    self.reads = true
    self.writes = true

    self
  end


  def size
    self.model.size
  end

  def dump
    it = self.model.listStatements
    res = ""
    while it.hasNext
      res += it.nextStatement.asTriple.toString
      res += " . \n"
    end
    res
  end

  def close
    ConnectionPool.remove_data_source(self)
    self.model.close
    self.connection.close unless self.connection.nil?
  end

  def clear
    self.model.removeAll
    self.model.prepare if self.model.respond_to? :prepare
    self.model.rebind if self.model.respond_to? :rebind
  end


  def delete(subject, predicate, object, context = nil)
    self.lucene_index_behind = true
    mod = get_model_for_context(context)
    s = (is_wildcard?(subject) ? nil : build_subject(subject, mod))
    p = (is_wildcard?(predicate) ? nil : build_predicate(predicate, mod))
    o = (is_wildcard?(object) ? nil : build_object(object, mod))
    mod.removeAll(s, p, o)
    mod.prepare if mod.respond_to? :prepare
    mod.rebind if mod.respond_to? :rebind
  end

  def add(subject, predicate, object, context = nil)
    self.lucene_index_behind = true
    mod = get_model_for_context(context)
    mod.add(build_statement(subject, predicate, object))
    mod.prepare if mod.respond_to? :prepare
    mod.rebind if mod.respond_to? :rebind
  end

  def flush
    # no-op
  end


  # :format
  #   format -- :ntriples, :n3, or :rdfxml, default :rdfxml
  # :into
  #   either the name of a model, :default_model for the main model, or
  #   :submodel to load into an anonymous memory model, default is :submodel
  #   if this is an ontology, :default_model if it's not.
  # :rebind
  #   rebind with the inferencer, default true; no effect if no inferencer
  def load(uri, params = {})
    into = params[:into] ? params[:into] :
      (self.ontology_type ? :submodel : :default_model)
    format = params[:format] ? params[:format] : :rdfxml
    rebind = params[:rebind] ? params[:rebind] : true

    jena_format =
      case format
      when :rdfxml
        "RDF/XML"
      when :ntriples
        "N-TRIPLE"
      when :n3
        "N3"
      end

    case into
    when :default_model
      self.model.read(uri, jena_format)

    when :submodel
      self.model.addSubModel(Jena::Model::ModelFactory.createDefaultModel.read(uri, jena_format))

    else
      self.model.addSubModel(self.model_maker.createModel(into).read(uri, jena_format))
    end

    if rebind && self.reasoner && self.model.respond_to?(:rebind)
      self.model.rebind
    end

    self.lucene_index_behind = true

  end

  # this method gets called by the ActiveRDF query engine
  def execute(query)

    if self.keyword_search? && query.keyword?

      # duplicate the query
      query_with_keywords = query.dup

      # now duplicate the where stuff so we can fiddle with it...
      # this is GROSS -- fix this if Query ever sprouts a proper
      # deep copy or a where_clauses setter
      query_with_keywords.instance_variable_set("@where_clauses", query.where_clauses.dup)

      # now, for each of the keyword clauses, set up the search
      query.keywords.each do |var, keyword|
        # use this if activerdf expects the subject to come back and not the
        # literal and using indexbuilderstring
        #query.where("lucene_literal_#{var}".to_sym, LuceneARQ::KEYWORD_PREDICATE, keyword)
        #query.where(var, "lucene_property_#{var}".to_sym, "lucene_literal_#{var}".to_sym)

        # use this if activerdf expects the literal to come back, not the
        # subject, or if using indexbuildersubject (which makes the subject
        # come back instead of the literal
        query_with_keywords.where(var, RDFS::Resource.new(LuceneARQ::KEYWORD_PREDICATE), keyword)

      end

    else
      query_with_keywords = query
    end

    # jena knows about lucene, so use the query object that has the keyword
    # search requests expanded.
    jena_results = query_jena(query_with_keywords)

    # use the conjunctive query facility in pellet to get additional
    # answers, if we're using pellet and we don't have a pure keyword
    # query
    if self.reasoner == :pellet && query.where_clauses.size > 0
      # pellet doesn't know about lucene, so we use the original query
      # object
      pellet_results = query_pellet(query)
      results = (jena_results + pellet_results).uniq!
    else
      results = jena_results
    end

    if query.ask?
      return [[true]] if results.size > 0
      return [[false]]
    end

    if query.count?
      return results.size
    end

    results

  end

  # ==========================================================================
  # put private methods here to seperate api methods from the
  # inner workings of the adapter
  private

  def map_ontology_type(type)
    case type
    when :rdfs
      'http://www.w3.org/2000/01/rdf-schema#'
    when :owl
      'http://www.w3.org/2002/07/owl#'
    when :owl_dl
      'http://www.w3.org/TR/owl-features/#term_OWLDL'
    when :owl_lite
      'http://www.w3.org/TR/owl-features/#term_OWLLite'
    else
      type
    end
  end


  def map_reasoner_factory(type)
    case type
    when :pellet
      Pellet.reasoner_factory

    when :transitive
      com.hp.hpl.jena.reasoner.transitiveReasoner.TransitiveReasonerFactory.theInstance

    when :rdfs
      com.hp.hpl.jena.reasoner.rulesys.RDFSFBRuleReasonerFactory.theInstance

    when :rdfs_simple
      com.hp.hpl.jena.reasoner.rulesys.RDFSRuleReasonerFactory.theInstance

    when :owl_micro
      com.hp.hpl.jena.reasoner.rulesys.OWLMicroReasonerFactory.theInstance

    when :owl_mini
      com.hp.hpl.jena.reasoner.rulesys.OWLMiniReasonerFactory.theInstance

    when :owl
      com.hp.hpl.jena.reasoner.rulesys.OWLFBRuleReasonerFactory.theInstance

    when :generic_rule
      com.hp.hpl.jena.reasoner.rulesys.GenericRuleReasonerFactory.theInstance

    else
      type
    end
  end

  def appropriate_model(submodel)
    (submodel && (submodel != self.model))? submodel : self.model
  end

  def build_object(object, submodel = nil)
    mod = appropriate_model(submodel)
    if object.respond_to? :uri
      o = mod.getResource(object.uri)
    else
      #xlate to literal
      if !object.kind_of? Literal
        objlit = Literal.new object
      else
        objlit = object
      end

      if objlit.type
        type = Jena::Datatypes::TypeMapper.getInstance.getTypeByName(objlit.type.uri)
        o = mod.createTypedLiteral(objlit.value, type)
      elsif objlit.language
        o = mod.createLiteral(objlit.value, objlit.language)
      else
        o = mod.createTypedLiteral(objlit.value, nil)
      end
    end
    return o
  end

  def build_subject(subject, submodel = nil)
    # ensure it exists in the parent model
    self.model.getResource(subject.uri) if submodel
    appropriate_model(submodel).getResource(subject.uri)
  end

  def build_predicate(predicate, submodel = nil)
    appropriate_model(submodel).getProperty(predicate.uri)
  end

  def build_statement(subject, predicate, object, submodel = nil)
    s = build_subject(subject, submodel)
    p = build_predicate(predicate, submodel)
    o = build_object(object, submodel)
    mod = submodel ? submodel : self.model
    mod.createStatement(s, p, o)
  end


  def is_wildcard?(thing)
    (thing == nil) || thing.kind_of?(Symbol)
  end

  def get_model_for_context(context)
    if (context == nil || context == self.model_name)
      self.model
    else
      subm = self.model_maker.openModel(context)
      self.model.addSubModel(subm)
      subm
    end
  end

  def query_jena(query)
    query_sparql = translate(query)

    qexec = Jena::Query::QueryExecutionFactory.create(query_sparql, self.model)

    # PROBABLY A VERY EXPENSIVE OPERATION (rebuilds lucene index if ANYTHING
    # changed -- this seems to be the only way, since you have to close
    # the index after you build it...
    if query.keyword? && self.keyword_search?
      LuceneARQ::LARQ.setDefaultIndex(qexec.getContext, retrieve_lucene_index)
    end

    begin
      results = perform_query(query, qexec)
    ensure
      qexec.close
    end

    results
  end

  def query_pellet(query)
    query_sparql = translate(query)
    jena_query = Jena::Query::QueryFactory.create(query_sparql)

    # bail if not a select
    return [] if !jena_query.isSelectType

    qexec = Pellet::Query::PelletQueryExecution.new(jena_query, self.model)

    begin
      results = perform_query(query, qexec)
    ensure
      qexec.close
    end

    results
  end

  def perform_query(query, qexec)
    results = qexec.execSelect
    arr_results = []

    while results.hasNext
      row = results.nextSolution
      res_row = []
      query.select_clauses.each do |kw|
        thing = row.get(kw.to_s)
        if thing.kind_of? Jena::Model::Resource
          if thing.isAnon
            res_row << BNode.new(thing.getId.to_s)
          else
            res_row << RDFS::Resource.new(thing.to_s)
          end
        elsif thing.kind_of? Jena::Model::Literal
          if thing.getLanguage == "" and thing.getDatatypeURI.nil?
            # plain literal
            res_row << thing.getString
          elsif thing.getLanguage == ""
            # datatyped literal
            res_row << Literal.new(thing.getValue, RDFS::Resource.new(thing.getDatatypeURI))
          elsif thing.getDatatypeURI.nil?
            # language tagged literal
            res_row << Literal.new(thing.getLexicalForm, "@" + thing.getLanguage)
          else
            raise ActiveRdfError, "Jena Sparql returned a strange literal"
          end
        else
          raise ActiveRdfError, "Returned thing other than resource or literal"
        end
      end
      arr_results << res_row
    end
    arr_results
  end

  def retrieve_lucene_index
    if self.lucene_index_behind?
      builder = LuceneARQ::IndexBuilderSubject.new
      builder.indexStatements(self.model.listStatements)
      builder.closeForWriting
      self.lucene_index = builder.getIndex
      self.lucene_index_behind = false
    end
    self.lucene_index
  end

end
