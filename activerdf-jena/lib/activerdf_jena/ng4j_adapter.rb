# Author:: Benjamin Heitmann
# Copyright:: (c) 2007 DERI
# License:: LGPL

class NG4JAdapter < ActiveRdfAdapter

  ConnectionPool.register_adapter(:ng4j, self)

  class NG4JAdapterConfigurationError < StandardError
  end

  bool_accessor :keyword_search, :reasoning
  bool_accessor :lucene_index_behind
  attr_accessor :ontology_type, :model_name, :reasoner, :connection
  attr_accessor :model_maker, :base_model, :model, :lucene_index
  attr_accessor :root_directory
  attr_accessor :graphset

  # :database
  #   either use :url, :type, :username, AND :password (for a
  #   regular connection) OR :datasource AND :type (for a container
  #   connection), default to memory data store
  #   example for a derby connection:
  #     :database => {:url => "jdbc:hsqldb:file:/some/location/on/your/drive", :type => "hsql", :username => "sa", :password => ""}
  # :model
  #   name of model to use, default is jena's default
  # :lucene
  #   set to true to enable true lucene indexing of this store, default false
  def initialize(params = {})
    dbparams = params[:database]
    self.keyword_search = params[:lucene]

    # if the model name is not provided and file persistence is used, then jena just
    # creates random files in the tmp dir. not good, as we need to know the model name
    # to have persistence
    if params[:model]
      self.model_name = params[:model]
    else
      self.model_name = "http://deri.org/defaultgraph"
    end

    # do some sanity checking
    if self.keyword_search? && !LuceneARQ.lucene_available?
      raise NG4JAdapterConfigurationError, "Lucene requested but is not available"
    end

    # NG4J only supports in-memory store and database storage with HSQL, mysql and postgresql
    if dbparams

      # check if the jdbc driver of the requested database is available
      begin
        if !Jena::DB.send("#{dbparams[:type].downcase}_available?")
          raise NG4JAdapterConfigurationError, "database type #{dbparams[:type]} not available"
        end
      rescue NameError
        raise NG4JAdapterConfigurationError, "database type #{dbparams[:type]} not recognized"
      end

      self.connection = NG4J::DB::DriverManager.getConnection(dbparams[:url],
                                                   dbparams[:username],
                                                   dbparams[:password])

      self.graphset = NG4J::DB::NamedGraphSetDB.new(self.connection)

    else
      self.graphset = NG4J::Impl::NamedGraphSetImpl.new()
    end

    self.model = self.graphset.asJenaModel(self.model_name)

    self.reads = true
    self.writes = true

    self
  end


  def size
    self.graphset.countQuads
  end

  # TODO: add quad support
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
    self.graphset.close
    self.connection.close unless self.connection.nil?
  end

  def clear
    self.model.removeAll
    self.model.prepare if self.model.respond_to? :prepare
    self.model.rebind if self.model.respond_to? :rebind
  end

  def delete(subject, predicate, object, context = nil)
    self.lucene_index_behind = true

    if context.nil?
      context = RDFS::Resource.new(self.model_name)
    end

    c = (is_wildcard?(context) ? Jena::Graph::Node.create("??") : build_context(context))
    s = (is_wildcard?(subject) ? Jena::Graph::Node.create("??") : build_subject(subject))
    p = (is_wildcard?(predicate) ? Jena::Graph::Node.create("??") : build_predicate(predicate))
    o = (is_wildcard?(object) ? Jena::Graph::Node.create("??") : build_object(object))

    self.graphset.removeQuad(NG4J::Internal::Quad.new(c, s, p, o))

    self.model.prepare if self.model.respond_to? :prepare
    self.model.rebind if self.model.respond_to? :rebind
  end

  def add(subject, predicate, object, context = nil)
    self.lucene_index_behind = true

    if context.nil?
      context = RDFS::Resource.new(self.model_name)
    end

    self.graphset.addQuad(NG4J::Internal::Quad.new(build_context(context), build_subject(subject),
      build_predicate(predicate), build_object(object)))

    self.model.prepare if self.model.respond_to? :prepare
    self.model.rebind if self.model.respond_to? :rebind
  end

  def flush
    # no-op
  end


  # :format
  #   format -- :ntriples, :n3, or :rdfxml, default :rdfxml
  # :into
  #   :default_model for the main model, otherwise the contents of the uri get loaded
  #   into a context with the same uri
  # TODO: add quad support
  def load(uri_as_string, params = {})
    format = params[:format] ? params[:format] : :rdfxml

    jena_format =
      case format
      when :rdfxml
        "RDF/XML"
      when :ntriples
        "N-TRIPLE"
      when :n3
        "N3"
      end


    if params[:into] == :default_model
      self.model.read(uri_as_string, jena_format)
    else
      self.graphset.read(uri_as_string, jena_format)
    end

    self.lucene_index_behind = true

  end

  # this method gets called by the ActiveRDF query engine
  # TODO: add quad support
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
    results = query_jena(query_with_keywords)

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

  def build_object(object)
    if object.respond_to? :uri
      o = Jena::Graph::Node.createURI(object.uri)
    else
      #xlate to literal
      if !object.kind_of? Literal
        objlit = Literal.new object
      else
        objlit = object
      end

      if objlit.type
        type = Jena::Datatypes::TypeMapper.getInstance.getTypeByName(objlit.type.uri)
        o = Jena::Graph::Node.createLiteral(objlit.value.to_s, nil, type)
      elsif objlit.language
        o = Jena::Graph::Node.createLiteral(objlit.value.to_s, objlit.language, nil)
      else
        o = Jena::Graph::Node.createLiteral(objlit.value.to_s)
      end
    end
    return o
  end

  def build_subject(subject)
    # TODO: raise error if not URI
    return Jena::Graph::Node.createURI(subject.uri)
  end

  def build_predicate(predicate)
    # TODO: raise error if not URI
    return Jena::Graph::Node.createURI(predicate.uri)
  end

  def build_context(context)
    # TODO: raise error if not URI
    return Jena::Graph::Node.createURI(context.uri)
  end

  # def build_model_object(object)
  #   if object.respond_to? :uri
  #     o = self.model.getResource(object.uri)
  #   else
  #     #xlate to literal
  #     if !object.kind_of? Literal
  #       objlit = Literal.new object
  #     else
  #       objlit = object
  #     end
  #
  #     if objlit.type
  #       type = Jena::Datatypes::TypeMapper.getInstance.getTypeByName(objlit.type.uri)
  #       o = self.model.createTypedLiteral(objlit.value, type)
  #     elsif objlit.language
  #       o = self.model.createLiteral(objlit.value, objlit.language)
  #     else
  #       o = self.model.createTypedLiteral(objlit.value, nil)
  #     end
  #   end
  #   return o
  # end
  #
  # def build_model_subject(subject)
  #   self.model.getResource(subject.uri)
  # end
  #
  # def build_model_predicate(predicate)
  #   self.model.getProperty(predicate.uri)
  # end

  def is_wildcard?(thing)
    (thing == nil) || thing.kind_of?(Symbol)
  end

  def query_jena(query)
    query_sparql = translate(query)

    # jena_query = Jena::Query::QueryFactory.create(query_sparql)
    #
    # puts jena_query
    #

    if query_sparql =~ /GRAPH/
      # query contains GRAPH keyword and has to be executed against an NG4J NamedGraphDataset
      qexec = Jena::Query::QueryExecutionFactory.create(query_sparql,
            NG4J::Sparql::NamedGraphDataset.new(self.graphset, Jena::Graph::Node.createURI(self.model_name)))
    else
      # query without GRAPH keyword gets executed against the union model
      qexec = Jena::Query::QueryExecutionFactory.create(query_sparql, self.model)
    end

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


  def perform_query(query, qexec)
    results = qexec.execSelect
    arr_results = []

    while results.hasNext
      row = results.nextSolution
      res_row = []
      query.select_clauses.each do |kw|
        thing = row.get(kw.to_s)
        if thing.kind_of? Jena::Model::Resource
          next if thing.isAnon
          res_row << RDFS::Resource.new(thing.to_s)
        elsif thing.kind_of? Jena::Model::Literal
          if thing.getLanguage == "" and thing.getDatatypeURI.nil?
            # plain literal
            res_row << Literal.new(thing.getString)
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
