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
  bool_accessor :using_lucene, :lucene_index_behind
  attr_accessor :ontology_type, :model_name, :reasoner, :connection
  attr_accessor :model_maker, :base_model, :model, :lucene_index

  # :database 
  #   either use :url, :type, :username, AND :password (for a
  #   regular connection) OR :datasource AND :type (for a container 
  #   connection), default to memory data store
  # :model
  #   name of model to use, default is jena's default
  # :ontology
  #   set to language type if this needs to be viewed as an ontology, 
  #   default nil, available :owl, :owl_dl, :owl_lite, :rdfs
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
    self.using_lucene = params[:lucene]
    self.model_name = params[:model]

    # do some sanity checking
    if self.using_lucene? && !LuceneARQ.lucene_available?
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
        self.connection = Jena::DB::DBconnection.new(dbparams[:url], 
                                                     dbparams[:username],
                                                     dbparams[:password],
                                                     dbparams[:type])
      end

      self.model_maker = Jena::Model::ModelFactory.createModelRDBMaker(connection)
      if self.model_name
        self.base_model = self.model_maker.openModel(model)
      else
        self.base_model = self.model_maker.createDefaultModel
      end
      
    else
      self.model_maker = Jena::Model::ModelFactory.createMemModelMaker
      self.base_model = Jena::Model::ModelFactory.createDefaultModel
    end
    
    if self.ontology_type
      rf = map_reasoner_factory(self.reasoner)
      onturi = map_ontology_type(self.ontology_type)

      spec = 
        Jena::Ontology::OntModelSpec.new(self.model_maker,
                                         Jena::Ontology::OntDocumentManager.new,
                                         rf, onturi)

      self.model = Jena::Model::ModelFactory.
        createOntologyModel(spec, self.base_model)
    else
      self.model = self.base_model
    end
    
    self.reads = true
    self.writes = true

    self
  end

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

  def clear
    self.model.removeAll
  end

  RUBY_XSD_TYPE_MAP = [
                       Jena::Datatypes::XSDDatatype::XSDanyURI,
                       Jena::Datatypes::XSDDatatype::XSDbase64Binary,
                       Jena::Datatypes::XSDDatatype::XSDboolean,
                       Jena::Datatypes::XSDDatatype::XSDbyte,
                       Jena::Datatypes::XSDDatatype::XSDdate,
                       Jena::Datatypes::XSDDatatype::XSDdateTime,
                       Jena::Datatypes::XSDDatatype::XSDdecimal,
                       Jena::Datatypes::XSDDatatype::XSDdouble,
                       Jena::Datatypes::XSDDatatype::XSDduration,
                       Jena::Datatypes::XSDDatatype::XSDENTITY,
                       Jena::Datatypes::XSDDatatype::XSDfloat,
                       Jena::Datatypes::XSDDatatype::XSDhexBinary,
                       Jena::Datatypes::XSDDatatype::XSDID,
                       Jena::Datatypes::XSDDatatype::XSDIDREF,
                       Jena::Datatypes::XSDDatatype::XSDint,
                       Jena::Datatypes::XSDDatatype::XSDgDay,
                       Jena::Datatypes::XSDDatatype::XSDgMonth,
                       Jena::Datatypes::XSDDatatype::XSDgMonthDay,
                       Jena::Datatypes::XSDDatatype::XSDgYear,
                       Jena::Datatypes::XSDDatatype::XSDgYearMonth,
                       Jena::Datatypes::XSDDatatype::XSDinteger,
                       Jena::Datatypes::XSDDatatype::XSDlanguage,
                       Jena::Datatypes::XSDDatatype::XSDlong,
                       Jena::Datatypes::XSDDatatype::XSDName,
                       Jena::Datatypes::XSDDatatype::XSDNCName,
                       Jena::Datatypes::XSDDatatype::XSDnegativeInteger,
                       Jena::Datatypes::XSDDatatype::XSDNMTOKEN,
                       Jena::Datatypes::XSDDatatype::XSDnonNegativeInteger,
                       Jena::Datatypes::XSDDatatype::XSDnonPositiveInteger,
                       Jena::Datatypes::XSDDatatype::XSDnormalizedString,
                       Jena::Datatypes::XSDDatatype::XSDNOTATION,
                       Jena::Datatypes::XSDDatatype::XSDpositiveInteger,
                       Jena::Datatypes::XSDDatatype::XSDQName,
                       Jena::Datatypes::XSDDatatype::XSDshort,
                       Jena::Datatypes::XSDDatatype::XSDstring,
                       Jena::Datatypes::XSDDatatype::XSDtime,
                       Jena::Datatypes::XSDDatatype::XSDtoken,
                       Jena::Datatypes::XSDDatatype::XSDunsignedByte,
                       Jena::Datatypes::XSDDatatype::XSDunsignedInt,
                       Jena::Datatypes::XSDDatatype::XSDunsignedLong,
                       Jena::Datatypes::XSDDatatype::XSDunsignedShort
                      ]

  # FIXME
  def map_type(obj)
    nil
  end

  def build_statement(subject, predicate, object)
    s = self.model.getResource(subject.uri)
    p = self.model.getProperty(predicate.uri)
    if object.respond_to? :uri
      o = self.model.getResource(object.uri)
    else
      type = map_type(o)
      o = self.model.createTypedLiteral(object, type)
    end
    self.model.createStatement(s, p, o)
  end

  def delete(subject, predicate, object, context = nil)
    self.lucene_index_behind = true
    self.model.remove(build_statement(subject, predicate, object))
    self.model.rebind if self.model.respond_to? :rebind
  end

  def add(subject, predicate, object, context = nil)
    self.lucene_index_behind = true
    self.model.add(build_statement(subject, predicate, object))
    self.model.rebind if self.model.respond_to? :rebind
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
      self.model.add(Jena::Model::ModelFactory.createDefaultModel.read(uri, jena_format))
      
    else
      self.model.add(self.model_maker.createModel(into).read(uri, jena_format))
    end
    
    if rebind && self.reasoner && self.model.respond_to?(:rebind)
      self.model.rebind
    end
    
  end
  
  def query(query, params = {})
    query_sparql = translate(query)

    qexec = Jena::Query::QueryExecutionFactory.create(query_sparql, self.model)

    # PROBABLY A VERY EXPENSIVE OPERATION (rebuilds lucene index if ANYTHING
    # changed...)
    if self.using_lucene? && params[:lucene]
      LuceneARQ::LARQ.setDefaultIndex(qxec.getContext, retrieve_lucene_index)
    end

    begin 
      results = qexec.execSelect
      arr_results = []
      
      # ask queries just get a yes/no
      if query.ask?
        return [[true]] if results.hasNext
        return [[false]]
      end

      while results.hasNext
        row = results.nextSolution
        res_row = []
        query.select_clauses.each do |kw|
          thing = row.get(kw.to_s)
          if thing.kind_of? Jena::Model::Resource
            next if thing.isAnon
            res_row << RDFS::Resource.new(thing.to_s)
          elsif thing.kind_of? Jena::Model::Literal
            res_row << thing.to_s
          else
            raise ActiveRdfError, "Returned thing other than resource or literal"
          end
        end
        arr_results << res_row
      end

      if query.count?
        return arr_results.size
      end

      return arr_results

    ensure
      qexec.close
    end
    
  end

  def retrieve_lucene_index
    if self.lucene_index_behind?
      builder = LuceneARQ::IndexBuilderString.new
      builder.indexStatements(self.model.listStatements)
      builder.closeForWriting
      self.lucene_index = builder.getIndex
    end
    self.lucene_index
  end


end
