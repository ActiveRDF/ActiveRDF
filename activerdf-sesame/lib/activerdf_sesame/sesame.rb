# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

require 'active_rdf'

$activerdflog.info "loading Sesame adapter"


# ----- java imports and extentsions
require 'java'

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

# TODO: about this adapter
class SesameAdapter < ActiveRdfAdapter
  ConnectionPool.register_adapter(:sesame,self)

  # instantiates Sesame database
  # available parameters:
  # * :location => path to a file for persistent storing or :memory for in-memory (defaults to in-memory)
  # * :inferencing => true or false, if sesame2 rdfs inferencing is uses (defaults to true)
  def initialize(params = {})
    $activerdflog.info "initializing Sesame Adapter with params #{params.to_s}"

    @reads = true
    @writes = true
	
    # if no directory path given, we use in-memory store
    if params[:location]
      if params[:location] == :memory
        sesame_location = nil      
      else
        sesame_location = JFile.new(params[:location])
      end
    else
      sesame_location = nil
    end
    
    # if no inferencing is specified, we use the sesame2 rdfs inferencing
    sesame_inferencing = params[:inferencing] || false
	
    # this will not work at the current state of jruby	
    #    # fancy JRuby code so that the user does not have to set the java CLASSPATH
    #    
    #    this_dir = File.dirname(File.expand_path(__FILE__))
    #    
    #    jar1 = JFile.new(this_dir + "/../../ext/wrapper-sesame2.jar")
    #    jar2 = JFile.new(this_dir + "/../../ext/openrdf-sesame-2.0-alpha4-onejar.jar")
    #
    #    # make an array of URL, which contains the URLs corresponding to the files
    #    uris = JURL[].new(2)
    #    uris[0] = jar1.toURL
    #    uris[1] = jar2.toURL
    #
    #    # this is our custom class loader, yay!
    #    @activerdfClassLoader = URLClassLoader.new(uris)
    #    classWrapper = JClass.forName("org.activerdf.wrapper.sesame2.WrapperForSesame2", true, @activerdfClassLoader)    
    #    @myWrapperInstance = classWrapper.new_instance 

    @myWrapperInstance = WrapperForSesame2.new

    if sesame_location == nil
      if sesame_inferencing == nil
        @db = @myWrapperInstance.callConstructor
      else
        @db = @myWrapperInstance.callConstructor(sesame_inferencing)		  
      end
    else
      if sesame_inferencing == nil
        @db = @myWrapperInstance.callConstructor(sesame_location)		  
      else
	@db = @myWrapperInstance.callConstructor(sesame_location,sesame_inferencing)		  
      end
    end
		
    @valueFactory = @db.getRepository.getValueFactory

    # define the finalizer, which will call close on the sesame triple store
    # recipie for this, is from: http://wiki.rubygarden.org/Ruby/page/show/GCAndMemoryManagement
    #    ObjectSpace.define_finalizer(self, SesameAdapter.create_finalizer(@db))       
  end

  # TODO: this does not work, but it is also not caused by jruby. 
  #  def SesameAdapter.create_finalizer(db)
  #    # we have to call close on the sesame triple store, because otherwise some of the iterators are not closed properly
  #    proc { puts "die";  db.close }
  #  end



  # returns the number of triples in the datastore (incl. possible duplicates)
  # * context => context (optional)
  def size(context = nil)
    # convert context in sesame object
    sesame_context = wrap(context) if !context.nil?
    
    # get size
    @myWrapperInstance.size(sesame_context)
  end

  # deletes all triples from datastore
  # * context => context (optional)
  def clear(context = nil)
    # convert context in sesame object
    sesame_context = wrap(context) if !context.nil?
    # clear
    @myWrapperInstance.clear(sesame_context)
  end

  # deletes triple(s,p,o,c) from datastore
  # symbol parameters match anything: delete(:s,:p,:o) will delete all triples
  # you can specify a context to limit deletion to that context: 
  # delete(:s,:p,:o, 'http://context') will delete all triples with that context
  # * s => subject
  # * p => predicate
  # * o => object
  # * c => context (optional)
  def delete(s, p, o, c=nil)
    # convert variables
    params = activerdf_to_sesame(s, p, o, c)

    begin
      # remove triple or tiples
      @myWrapperInstance.remove(params[0], params[1], params[2],params[3])
    rescue
      raise ActiveRdfError, "Sesame add triple failed: #{e.message}"
    end
  end
	
  # adds triple(s,p,o,c) to datastore
  # s,p must be resources, o can be primitive data or resource
  # * s => subject
  # * p => predicate
  # * o => object
  # * c => context (optional)
  def add(s,p,o,c=nil)
    # check variables
    unless (((s.class == String) && (p.class == String) && (o.class == String)) && 
          ((s[0..0] == '<') && (s[-1..-1] == '>')) && 
          ((p[0..0] == '<') && (p[-1..-1] == '>'))) || (s.respond_to?(:uri) && p.respond_to?(:uri))
      $activerdflog.debug "cannot add triple where s/p are not resources, exiting"
      return false
    end
    
    # convert variables
    params = activerdf_to_sesame(s, p, o, c)
    
    begin
      # add triple
      @myWrapperInstance.add(params[0], params[1], params[2],params[3])
    rescue Exception => e
      raise ActiveRdfError, "Sesame add triple failed: #{e.message}"
    end
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
  end

  # returns all triples in the datastore
  # * context => context (optional)
  def dump(context = nil)
    # convert context in sesame object
    sesame_context = wrapContext(context) if !context.nil?
    
    begin
      # dump
      @myWrapperInstance.dump(sesame_context)
    rescue Exception => e
      raise ActiveRdfError, "Sesame dump failed: #{e.message}"
    end
  end

  # loads triples from file in ntriples format
  # * file => file to load
  # * syntax => syntax of file to load. The syntax can be: n3, ntriples, rdfxml, trig, trix, turtle
  # * context => context (optional)
  def load(file, syntax="ntriples", context=nil)
    # wrap Context
    sesame_context = nil
    sesame_context = wrapContext(context) unless (context.nil?)
   
    # rdf syntax type
    case syntax
    when 'n3'
      syntaxType = RDFFormat::N3      
    when 'ntriples'
      syntaxType = RDFFormat::NTRIPLES
    when 'rdfxml'
      syntaxType = RDFFormat::RDFXML
    when 'trig'
      syntaxType = RDFFormat::TRIG
    when 'trix'
      syntaxType = RDFFormat::TRIX
    when 'turtle'
      syntaxType = RDFFormat::TURTLE 
    else
      raise ActiveRdfError, "Sesame load file failed: syntax not valid."
    end
    
    begin
      @myWrapperInstance.load(file,"",syntaxType,sesame_context)
    rescue Exception => e
      raise ActiveRdfError, "Sesame load file failed: #{e.message}"
    end
  end

  # executes ActiveRDF query on the sesame triple store associated with this adapter
  # * query => Query object
  def query(query)
	
    # we want to put the results in here
    results = []
    
    # translate the query object into a SPARQL query string
    qs = Query2SPARQL.translate(query)
    
    # evaluate the query on the sesame triple store
    # TODO: if we want to get inferred statements back we have to say so, as third boolean parameter
    tuplequeryresult= @myWrapperInstance.query(QueryLanguage::SPARQL, qs)

    # what are the variables of the query ?
    variables = tuplequeryresult.getBindingNames
    sizeOfVariables = variables.size

    # a solution is a binding of a variable to all entities that matched this variable in the sparql query
    # TODO: null handling, if a value is null...
    
    # process all query result
    while tuplequeryresult.hasNext()
      # get next result
      resultItem = tuplequeryresult.next
        
      temparray = []
      # get the value associated with a variable in this specific solution
      (1..sizeOfVariables).each { |i|
        temparray << convertSesame2ActiveRDF(resultItem.getValue(variables[i-1]))
      }
      results << temparray
    end    
    
    return results
  end
	
  private
	
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
  # TODO: do we need to think about handling blank nodes ? e.g. if the are part of a graph read from a file ? 
  def convertSesame2ActiveRDF(input)
    jclassURI = Java::JavaClass.for_name("org.openrdf.model.URI")
    jclassLiteral = Java::JavaClass.for_name("org.openrdf.model.Literal")	
    
    if jInstanceOf(input.java_class, jclassURI)
      if Query.resource_class.nil?
        return RDFS::Resource.new(input.toString)
      else
        return Query.resource_class.new(input.toString)
      end
    elsif jInstanceOf(input.java_class, jclassLiteral)
      return input.toString[1..-2]
    else
      raise ActiveRdfError, "the Sesame Adapter tried to return something which is neither a URI nor a Literal, but is instead a #{input.java_class.name}"
    end
  end

  # converts spoc input into sesame objects (RDFS::Resource into 
  # valueFactory.createURI etc.)
  def activerdf_to_sesame(s, p, o, c)
    params = []
    
    # construct sesame parameters from s,p,o,c
    [s,p,o].each { |item|
      params << wrap(item)
    }
    
    # wrap Context
    params << wrapContext(c) unless (c.nil?)
   
    params
  end
  
  # converts item into sesame object (RDFS::Resource into 
  # valueFactory.createURI etc.)
  def wrap(item)
    result = case item
    when RDFS::Resource
      if (item.uri[0..4].match(/http:/).nil?)
        @valueFactory.createLiteral(item.uri)
      else
        @valueFactory.createURI(item.uri)
      end
    when Symbol
      nil
    when NilClass
      nil
    else
      if ((!Query.resource_class.nil?) && (item.class == Query.resource_class))
        if (item.uri[0..4].match(/http:/).nil?)
          @valueFactory.createLiteral(item.uri)
        else
          @valueFactory.createURI(item.uri)
        end
      else
        @valueFactory.createLiteral(item.to_s)
      end
    end  
    return result      
  end
  
  def wrapContext(context)
    # context must be Resource
    raise ActiveRdfError, "context must be a Resource" if (context.class != RDFS::Resource)
    
    # return context
    @valueFactory.createURI(context.uri)
  end
end
