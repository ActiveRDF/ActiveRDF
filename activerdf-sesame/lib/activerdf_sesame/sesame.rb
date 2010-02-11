# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

require 'active_rdf'

module ActiveRDF
  # TODO: about this adapter
  class SesameAdapter < ActiveRdfAdapter
    ActiveRdfLogger::log_info "Loading Sesame adapter", self

    # ----- java imports and extentsions
    require 'java'

    begin
      # Import the jars
      Dir[File.join(File.dirname(__FILE__), '..', '..', 'ext', '*.jar')].each { |jar| require jar}

      StringWriter = java.io.StringWriter
      JFile = java.io.File
      URLClassLoader = java.net.URLClassLoader
      JURL = java.net.URL
      JClass = java.lang.Class
      JObject = java.lang.Object
      JIOException = java.io.IOException

      # sesame specific classes:
      WrapperForSesame2 = org.activerdf.wrapper.sesame2.WrapperForSesame2
      QueryLanguage = org.openrdf.query.QueryLanguage
      NTriplesWriter = org.openrdf.rio.ntriples.NTriplesWriter
      RDFFormat = org.openrdf.rio.RDFFormat
    rescue Exception => e
      puts e.backtrace
      raise
    end

    ConnectionPool.register_adapter(:sesame,self)

    # Create a sesame adapter. The parameter array must contain a :backend that will identify
    # the backend that Sesame will use for the storage. All backends (except the HTTP repositories)
    # take the parameter :inferencing, which will turn on the internal inferencing engine in Sesame 
    # (default is off).
    #
    # For compatibility, this will use the native driver if no type is given. 
    #
    # = :memory
    # The in-memory store. No parameters. 
    #
    # = :native
    # The "Native" store that saves data to a file. This backend finally employs locking on the database,
    # which means that the database can only be used from one script or program at a time.
    # [*location*] - Path to the data file for Sesame
    # [*indexes*] - Optional index for Sesame, example "spoc,posc,cosp"
    # 
    # = :rdbms
    # The RDBMS backend store. You need to give the JDBC driver class, and obviously the JDBC driver
    # for your database needs to be installed.
    # [*driver*] - JDBC driver to use
    # [*url*] - URL for JDBC connection
    # [*user*] - Username for database connection (optional)
    # [*pass*] - Password for database connection (optional)
    #
    # = :http
    # 
    # Connect to a repository on a sesame server through http.
    # [*url*] - The repository url
    # [*user*] - User name for HTTP authentication
    # [*pass*] - Password for HTTP auth
    def initialize(params = {})
      super()
      ActiveRdfLogger::log_info "Initializing Sesame Adapter with params #{params.to_s}", self

      @reads = true
      @writes = true

      # Use native type by default
      backend = params[:backend] || 'native'

      @myWrapperInstance = WrapperForSesame2.new
      @db = case(backend)
      when 'native'
        init_native_store(params)
      when 'memory'
        init_memory_store(params)
      when 'rdbms'
        init_rdbms_store(params)
      when 'http'
        init_http_store(params)
      else
        raise(ArgumentError, "Unknown backend type for Sesame: #{backend}")
      end

      @backend = backend
      @inferencing = (params[:inferencing] && (backend != 'http'))

      @valueFactory = if(backend == 'http')
        @db.getRepository.getValueFactory
      else
        @db.getRepository.getSail.getValueFactory
      end

    end

    attr_reader :backend

    def inferencing?
      @inferencing
    end

    # returns the number of triples in the datastore (incl. possible duplicates)
    # * context => context (optional)
    def size(context = nil)
      @db.size(wrap_contexts(context))
    end

    # deletes all triples from datastore
    # * context => context (optional)
    def clear(context = nil)
      @db.clear(wrap_contexts(context))
    end

    # deletes triple(s,p,o,c) from datastore
    # symbol parameters match anything: delete(:s,:p,:o) will delete all triples
    # you can specify a context to limit deletion to that context:
    # delete(:s,:p,:o, 'http://context') will delete all triples with that context
    # * s => subject
    # * p => predicate
    # * o => object
    # * c => context (optional)
    # Nil parameters are treated as :s, :p, :o respectively.
    def delete(s, p, o, c=nil)
      # convert variables
      params = activerdf_to_sesame(s, p, o, c, true)

      begin
        @db.remove(params[0], params[1], params[2], wrap_contexts(c))
        true
      rescue Exception => e
        raise ActiveRdfError, "Sesame delete triple failed: #{e.message}"
      end
      @db
    end

    # adds triple(s,p,o,c) to datastore
    # s,p must be resources, o can be primitive data or resource
    # * s => subject
    # * p => predicate
    # * o => object
    # * c => context (optional)
    def add(s,p,o,c=nil)
      # TODO: handle context, especially if it is null
      # TODO: do we need to handle errors from the java side ?

      check_input = [s,p,o]
      raise ActiveRdfError, "cannot add triple with nil or blank node subject, predicate, or object" if check_input.any? {|r| r.nil? || r.is_a?(Symbol) }

      params = activerdf_to_sesame(s, p, o, c)
      @db.add(params[0], params[1], params[2], wrap_contexts(c))
      true
    rescue Exception => e
      raise ActiveRdfError, "Sesame add triple failed: #{e.message}"
    end

    # flushing is done automatically, because we run sesame2 in autocommit mode
    def flush
      true
    end

    # saving is done automatically, because we run sesame2 in autocommit mode
    def save
      true
    end

    # close the underlying sesame triple store.
    # if not called there may be open iterators.
    def close
      @db.close
      ConnectionPool.remove_data_source(self)
    end

    # returns all triples in the datastore
    def dump
      # the sesame connection has an export method, which writes all explicit statements to
      # a to a RDFHandler, which we supply, by constructing a NTriplesWriter, which writes to StringWriter,
      # and we kindly ask that StringWriter to make a string for us. Note, you have to use stringy.to_s,
      # somehow stringy.toString does not work. yes yes, those wacky jruby guys ;)
      _string = StringWriter.new
      sesameWriter = NTriplesWriter.new(_string)
      @db.export(sesameWriter)
      return _string.to_s
    end

    # loads triples from file in ntriples format
    # * file => file to load
    # * syntax => syntax of file to load. The syntax can be: n3, ntriples, rdfxml, trig, trix, turtle
    # * context => context (optional)
    def load(file, syntax="ntriples", context=nil)
      # rdf syntax type
      case syntax
      when 'n3'
        syntax_type = RDFFormat::N3      
      when 'ntriples'
        syntax_type = RDFFormat::NTRIPLES
      when 'rdfxml'
        syntax_type = RDFFormat::RDFXML
      when 'trig'
        syntax_type = RDFFormat::TRIG
      when 'trix'
        syntax_type = RDFFormat::TRIX
      when 'turtle'
        syntax_type = RDFFormat::TURTLE 
      else
        raise ActiveRdfError, "Sesame load file failed: syntax not valid."
      end

      begin
        @myWrapperInstance.load(file, "", syntax_type, wrap_contexts(context))
      rescue Exception => e
        raise ActiveRdfError, "Sesame load file failed: #{e.message}\n#{e.backtrace}"
      end
    end

    # executes ActiveRDF query on the sesame triple store associated with this adapter
    def execute(query)

      # we want to put the results in here
      results = []

      # translate the query object into a SPARQL query string
      qs = Query2SPARQL.translate(query)

      begin
        # evaluate the query on the sesame triple store
        # TODO: if we want to get inferred statements back we have to say so, as third boolean parameter
        tuplequeryresult = @db.prepareTupleQuery(QueryLanguage::SPARQL, qs).evaluate
      rescue Exception => e
        ActiveRdfLogger.log_error(self) { "Error evaluating query (#{e.message}): #{qs}" }
        raise
      end

      # what are the variables of the query ?
      variables = tuplequeryresult.getBindingNames
      size_of_variables = variables.size

      # the following is plainly ugly. the reason is that JRuby currently does not support
      # using iterators in the ruby way: with "each". it is possible to define "each" for java.util.Iterator
      # using JavaUtilities.extend_proxy but that fails in strange ways. this is ugly but works.

      # TODO: null handling, if a value is null...

      # if there only was one variable, then the results array should look like this:
      # results = [ [first Value For The Variable], [second Value], ...]
      if size_of_variables == 1 then
        # the counter keeps track of the number of values, so we can insert them into the results at the right position
        counter = 0
        while tuplequeryresult.hasNext
          solution = tuplequeryresult.next

          temparray = []
          # get the value associated with a variable in this specific solution
          temparray[0] = convertSesame2ActiveRDF(solution.getValue(variables[0]), query.resource_class)
          results[counter] = temparray
          counter = counter + 1
        end
      else
        # if there is more then one variable the results array looks like this:
        # results = [ [Value From First Solution For First Variable, Value From First Solution For Second Variable, ...],
        #             [Value From Second Solution For First Variable, Value From Second Solution for Second Variable, ...], ...]
        counter = 0
        while tuplequeryresult.hasNext
          solution = tuplequeryresult.next

          temparray = []
          for n in 1..size_of_variables
            value = convertSesame2ActiveRDF(solution.getValue(variables[n-1]), query.resource_class)
            temparray[n-1] = value
          end
          results[counter] = temparray
          counter = counter + 1
        end
      end

      return results
    end

    private

    # Init a native Sesame backend
    def init_native_store(params)
      # if no inferencing is specified, we don't activate sesame2 rdfs inferencing
      sesame_inferencing = params[:inferencing] || false
      ActiveRdfLogger.log_debug(self) { "Creating Sesame Native Adapter (location: #{params[:location]}, indexes: #{params[:indexes]}, inferencing: #{sesame_inferencing}" }
      sesame_location = JFile.new(params[:location]) if(params[:location])

      @myWrapperInstance.initWithNative(sesame_location, params[:indexes], sesame_inferencing)
    end

    # Init a in-memory Sesame backend
    def init_memory_store(params)
      # if no inferencing is specified, we don't activate sesame2 rdfs inferencing
      sesame_inferencing = params[:inferencing] || false
      ActiveRdfLogger.log_debug(self) { "Creating Sesame Memory Adapter (inferencing: #{sesame_inferencing}" }

      @myWrapperInstance.initWithMemory(sesame_inferencing)
    end

    # Init with an RDBMS backend
    def init_rdbms_store(params)
      sesame_inferencing = params[:inferencing] || false
      ActiveRdfLogger.log_debug(self) { "Creating Sesame RDBMS Adapter (driver: #{params[:driver]}, url: #{params[:url]}, user: #{params[:user]}, pass: #{params[:pass]}, inferencing: #{sesame_inferencing}" }

      @myWrapperInstance.initWithRDBMS(params[:driver], params[:url], params[:user], params[:pass], sesame_inferencing)
    end

    # Init the HTTP store
    def init_http_store(params)
      ActiveRdfLogger.log_debug(self) { "Creating Sesame HTTP Adapter (url: #{params[:url]}, user: #{params[:user]}, pass: #{params[:pass]} (inferencing settings are always ignored)" }

      wrap = @myWrapperInstance.initWithHttp(params[:url], params[:user], params[:pass])
      @writes = wrap.getRepository.isWritable
      wrap
    end

    # check if testee is a java subclass of reference
    def jInstanceOf(testee, reference)
      # for Java::JavaClass for a <=> b the comparison operator returns: -1 if a is subclass of b,
      # 0 if a.jclass = b.jclass, +1 in any other case.
      isSubclass = (testee <=> reference)
      if isSubclass == -1 or isSubclass == 0
        return true
      else
        return false
      end
    end

    # takes a part of a sesame statement, and converts it to a RDFS::Resource if it is a URI,
    # or to a String if it is a Literal. The assumption currently, is that we will only get stuff out of sesame,
    # which we put in there ourselves, and currently we only put URIs or Literals there.
    # 
    # result_type is the class that will be used for "resource" objects.
    def convertSesame2ActiveRDF(input, result_type)
      jclassURI = Java::JavaClass.for_name("org.openrdf.model.URI")
      jclassLiteral = Java::JavaClass.for_name("org.openrdf.model.Literal")
      jclassBNode = Java::JavaClass.for_name('org.openrdf.model.BNode')

      if jInstanceOf(input.java_class, jclassURI)
        result_type.new(input.toString)
      elsif jInstanceOf(input.java_class, jclassLiteral)
        # The string is wrapped in quotationn marks. However, there may be a language
        # indetifier outside the quotation marks, e.g. "The label"@en
        # We try to unwrap this correctly. For now we assume that there may be
        # no quotation marks inside the string
        input.toString.gsub('"', '')
      elsif jInstanceOf(input.java_class, jclassBNode)
        RDFS::BNode.new(input.toString)
      else
        raise ActiveRdfError, "the Sesame Adapter tried to return something which is neither a URI nor a Literal, but is instead a #{input.java_class.name}"
      end
    end

    # converts spoc input into sesame objects (RDFS::Resource into
    # valueFactory.createURI etc.)
    def activerdf_to_sesame(s, p, o, c, use_nil = false)
      params = []

      # construct sesame parameters from s,p,o,c
      [s,p,o].each { |item|
        params << wrap(item, use_nil)
      }

      # wrap Context
      params << wrap_contexts(c) unless (c.nil?)

      params
    end

    # converts item into sesame object (RDFS::Resource into 
    # valueFactory.createURI etc.). You can opt to preserve the
    # nil values, otherwise they'll be transformed
    def wrap(item, use_nil = false)
      result = 
      if(item.respond_to?(:uri))
        if (item.uri.to_s[0..4].match(/http:/).nil?)
          @valueFactory.createLiteral(item.uri.to_s)
        else
          @valueFactory.createURI(item.uri.to_s)
        end
      else
        case item
        when Symbol
          @valueFactory.createLiteral('')
        when NilClass
          use_nil ? nil : @valueFactory.createLiteral('')
        else
          @valueFactory.createLiteral(item.to_s)
        end
      end
      return result      
    end

    def wrap_contexts(*contexts)
      contexts.compact!
      contexts.collect! do |context|
        raise ActiveRdfError, "context must be a Resource" unless(context.respond_to?(:uri))
        @valueFactory.createURI(context.uri)
      end
      contexts.to_java(org.openrdf.model.Resource)
    end
  end
end