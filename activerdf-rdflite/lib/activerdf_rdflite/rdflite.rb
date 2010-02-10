# Author:: Eyal Oren
# Copyright:: (c) 2005-2006 Eyal Oren
# License:: LGPL

require 'sqlite3'
require 'active_rdf'
require 'federation/connection_pool'
require 'uuidtools'
require 'queryengine/ntriples_parser'
require 'open-uri'
require 'mime/types'

ActiveRdfLogger::log_info "Loading RDFLite adapter", self

begin 
  require 'ferret'
  @have_ferret = true
rescue LoadError
  ActiveRdfLogger::log_info "Keyword search is disabled since we could not load Ferret. To enable, please do \"gem install ferret\"", self
  @@have_ferret = false
end

# RDFLite is a lightweight RDF database on top of sqlite3. It can act as adapter 
# in ActiveRDF. It supports on-disk and in-memory usage, and allows keyword 
# search if ferret is installed.
class RDFLite < ActiveRdfAdapter
  ConnectionPool.register_adapter(:rdflite,self)
  bool_accessor :keyword_search, :reasoning

  # instantiates RDFLite database
  # available parameters:
  # * :location => filepath (defaults to memory)
  # * :keyword => true/false (defaults to false)
  # * :pidx, :oidx, etc. => true/false (enable/disable these indices)
  def initialize(params = {})
    super()
    ActiveRdfLogger::log_info(self) { "Initialised rdflite with params #{params.to_s}" }

    @reads = true
    @writes = true

    # if no file-location given, we use in-memory store
    file = params[:location] || ':memory:'
    @db = SQLite3::Database.new(file) 

    # disable keyword search by default, enable only if ferret is found
    @keyword_search = params[:keyword].nil? ? false : params[:keyword]
    @keyword_search &= @@have_ferret

    @reasoning = params[:reasoning] || false
    @subprops = {} if @reasoning

    if keyword_search?
      # we initialise the ferret index, either as a file or in memory
      infos = Ferret::Index::FieldInfos.new

      # we setup the fields not to store object's contents
      infos.add_field(:subject, :store => :yes, :index => :no, :term_vector => :no)
      infos.add_field(:object, :store => :no) #, :index => :omit_norms)

      @ferret = if params[:location]
        Ferret::I.new(:path => params[:location] + '.ferret', :field_infos => infos)
      else
        Ferret::I.new(:field_infos => infos)
      end
    end

    # turn off filesystem synchronisation for speed
    @db.synchronous = 'off'

    # create triples table. ignores duplicated triples
    @db.execute('create table if not exists triple(s,p,o,c, unique(s,p,o,c) on conflict ignore)')

    create_indices(params)
    @db
  end

  # returns the number of triples in the datastore (incl. possible duplicates)
  def size
    @db.execute('select count(*) from triple')[0][0].to_i
  end

  # returns all triples in the datastore
  def dump
    @db.execute('select s,p,o,c from triple').collect do |s,p,o,c|
      [s,p,o,c].join(' ')
    end
  end

  # deletes all triples from datastore
  def clear
    @db.execute('delete from triple')
  end

  # close adapter and remove it from the ConnectionPool
  def close
    ConnectionPool.remove_data_source(self)
    @db.close
  end

  # deletes triple(s,p,o,c) from datastore
  # symbol parameters match anything: delete(:s,:p,:o) will delete all triples
  # you can specify a context to limit deletion to that context: 
  # delete(:s,:p,:o, 'http://context') will delete all triples with that context
  def delete(s, p, o, c=nil)
    # convert non-nil input to internal format
    quad = [s,p,o,c].collect {|r| r.nil? ? nil : internalise(r) }

    # construct where clause for deletion (for all non-nil input)
    where_clauses = []
    conditions = []		
    quad.each_with_index do |r,i|
      unless r.nil?
        conditions << r
        where_clauses << "#{SPOC[i]} = ?"
      end
    end

    # construct delete string
    ds = 'delete from triple'
    ds << " where #{where_clauses.join(' and ')}" unless where_clauses.empty?

    # execute delete string with possible deletion conditions (for each 
    # non-empty where clause)
    ActiveRdfLogger::log_debug(self) { "Deleting #{[s,p,o,c].join(' ')}" }
    @db.execute(ds, *conditions)

    # delete literal from ferret index
    @ferret.search_each("subject:\"#{s}\", object:\"#{o}\"") do |idx, score|
      @ferret.delete(idx)
    end if keyword_search?

    @db
  end

  # adds triple(s,p,o) to datastore
  # s,p must be resources, o can be primitive data or resource
  def add(s,p,o,c=nil)
    # check illegal input
    raise(ActiveRdfError, "adding non-resource #{s} while adding (#{s},#{p},#{o},#{c})") unless s.respond_to?(:uri)
    raise(ActiveRdfError, "adding non-resource #{p} while adding (#{s},#{p},#{o},#{c})") unless p.respond_to?(:uri)


    triple = [s, p, o].collect{|r| serialise(r) }
    ntriple = triple.join(' ') + " .\n"
    add_ntriples(ntriple, serialise(c))

    ## get internal representation (array)
    #quad = [s,p,o,c].collect {|r| internalise(r) }

    ## insert the triple into the datastore
    #@db.execute('insert into triple values (?,?,?,?)', *quad)

    ## if keyword-search available, insert the object into keyword search
    #@ferret << {:subject => s, :object => o} if keyword_search?
  end

  # flushes openstanding changes to underlying sqlite3
  def flush
    # since we always write changes into sqlite3 immediately, we don't do 
    # anything here
    true
  end

  # loads triples from file in ntriples format
  def load(location)
    context = if URI.parse(location).host
      location
    else
      internalise(RDFS::Resource.new("file:#{location}"))
    end

    case MIME::Types.of(location)
    when MIME::Types['application/rdf+xml']
      # check if rapper available
      begin 
        # can only parse rdf/xml with redland
        # die otherwise
        require 'rdf/redland'
        model = Redland::Model.new
        Redland::Parser.new.parse_into_model(model, location)
        add_ntriples(model.to_string('ntriples'), location)
      rescue LoadError
        raise ActiveRdfError, "cannot parse remote rdf/xml file without Redland: please install Redland (librdf.org) and its Ruby bindings"
      end
    else
      data = open(location).read
      add_ntriples(data, context)
    end
  end

  # adds ntriples from given context into datastore
  def add_ntriples(ntriples, context)
    # add each triple to db
    @db.transaction
    insert = @db.prepare('insert into triple values (?,?,?,?);')

    ntriples = NTriplesParser.parse(ntriples)
    ntriples.each do |s,p,o|
      # convert triples into internal db format
      subject, predicate, object = [s,p,o].collect {|r| internalise(r) }

      # insert triple into database
      insert.execute(subject, predicate, object, context)

      # if keyword-search available, insert the object into keyword search
      @ferret << {:subject => subject, :object => object} if keyword_search?
    end

    @db.commit
    @db
  end

  # executes ActiveRDF query on datastore
  def query(query)
    # construct query clauses
    sql, conditions = translate(query)

    # executing query, passing all where-clause values as parameters (so that 
    # sqlite will encode quotes correctly)
    results = @db.execute(sql, *conditions)

    # if ASK query, we check whether we received a positive result count
    if query.ask?
      return [[results[0][0].to_i > 0]]
    elsif query.count?
      return [[results[0][0].to_i]]
    else
      # otherwise we convert results to ActiveRDF nodes and return them
      return wrap(results, query.resource_class)
    end
  end

  # translates ActiveRDF query into internal sqlite query string
  def translate(query)
    where, conditions = construct_where(query)
    [construct_select(query) + construct_join(query) + where + construct_sort(query) + construct_limit(query), conditions]
  end

  private
  # constants for extracting resources/literals from sql results
  SPOC = ['s','p','o','c']

  # construct select clause
  def construct_select(query)
    # ASK queries counts the results, and return true if results > 0
    return "select count(*)" if query.ask?

    # add select terms for each selectclause in the query
    # the term names depend on the join conditions, e.g. t0.s or t1.p
    select = query.select_clauses.collect do |term|
      variable_name(query, term)
    end

    # add possible distinct and count functions to select clause
    select_clause = ''
    select_clause << 'distinct ' if query.distinct?
    select_clause << select.join(', ')
    select_clause = "count(#{select_clause})" if query.count?

    "select " + select_clause
  end

  # construct (optional) limit and offset clauses
  def construct_limit(query)
    clause = ""

    # if no limit given, use limit -1 (no limit)
    limit = query.limits.nil? ? -1 : query.limits

    # if no offset given, use offset 0
    offset = query.offsets.nil? ? 0 : query.offsets

    clause << " limit #{limit} offset #{offset}"
    clause
  end

  # sort query results on variable clause (optionally)
  def construct_sort(query)
    if not query.sort_clauses.empty?
      sort = query.sort_clauses.collect { |term| variable_name(query, term) }
      " order by (#{sort.join(',')})"
    elsif not query.reverse_sort_clauses.empty?
      sort = query.reverse_sort_clauses.collect { |term| variable_name(query, term) }
      " order by (#{sort.join(',')}) DESC"
    else
      ""
    end
  end

  # construct join clause
  # TODO: joins don't work this way, they have to be linear (in one direction 
  # only, and we should only alias tables we didnt alias yet)
  # we should only look for one join clause in each where-clause: when we find 
  # one, we skip the rest of the variables in this clause.
  def construct_join(query)
    join_stmt = ''

    # no join necessary if only one where clause given
    return ' from triple as t0 ' if query.where_clauses.size == 1

    where_clauses = safe_flatten(query.where_clauses)
    considering = where_clauses.uniq.select{|w| w.is_a?(Symbol)}

    # constructing hash with indices for all terms
    # e.g. {?s => [1,3,5], ?p => [2], ... }
    term_occurrences = Hash.new()
    where_clauses.each_with_index do |term, index|
      ary = (term_occurrences[term] ||= [])
      ary << index 
    end

    aliases = {}

    where_clauses.each_with_index do |term, index|
      # if the term has been joined with his buddy already, we can skip it
      next unless considering.include?(term)

      # we find all (other) occurrences of this term
      indices = term_occurrences[term]

      # if the term doesnt have a join-buddy, we can skip it
      next if indices.size == 1

      # construct t0,t1,... as aliases for term
      # and construct join condition, e.g. t0.s
      termalias = "t#{index / 4}"
      termjoin = "#{termalias}.#{SPOC[index % 4]}"

      join = if join_stmt.include?(termalias)
        ""
      else
        "triple as #{termalias}"
      end

      indices.each do |i|
        # skip the current term itself
        next if i==index

        # construct t0,t1, etc. as aliases for buddy,
        # and construct join condition, e.g. t0.s = t1.p
        buddyalias = "t#{i/4}"
        buddyjoin = "#{buddyalias}.#{SPOC[i%4]}"

        # TODO: fix reuse of same table names as aliases, e.g.
        # "from triple as t1 join triple as t2 on ... join t1 on ..."
        # is not allowed as such by sqlite
        # but on the other hand, restating the aliases gives ambiguity:
        # "from triple as t1 join triple as t2 on ... join triple as t1 ..."
        # is ambiguous
        if join_stmt.include?(buddyalias)
          join << "and #{termjoin} = #{buddyjoin}"
        else
          join << " join triple as #{buddyalias} on #{termjoin} = #{buddyjoin} "
        end
      end
      join_stmt << join

      # remove term from 'todo' list of still-considered terms
      considering.delete(term)
    end

    if join_stmt == ''
      return " from triple as t0 "
    else
      return " from #{join_stmt} "
    end
  end

  # construct where clause
  def construct_where(query)
    # collecting where clauses, these will be added to the sql string later
    where = []

    # collecting all the right-hand sides of where clauses (e.g. where name = 
    # 'abc'), to add to query string later using ?-notation, because then 
    # sqlite will automatically encode quoted literals correctly
    right_hand_sides = []

    # convert each where clause to SQL:
    # add where clause for each subclause, except if it's a variable
    query.where_clauses.each_with_index do |clause,level|
      raise ActiveRdfError, "where clause #{clause} is not a triple" unless clause.is_a?(Array)
      clause.each_with_index do |subclause, i|
        # dont add where clause for variables
        unless subclause.is_a?(Symbol) || subclause.nil?
          conditions = compute_where_condition(i, subclause, query.reasoning? && reasoning?)
          if conditions.size == 1
            where << "t#{level}.#{SPOC[i]} = ?"
            right_hand_sides << conditions.first
          else
            conditions = conditions.collect {|c| "'#{c}'"}
            where << "t#{level}.#{SPOC[i]} in (#{conditions.join(',')})"
          end
        end
      end
    end

    # if keyword clause given, convert it using keyword index
    if query.keyword? && keyword_search?
      subjects = []
      select_subject = query.keywords.collect {|subj,key| subj}.uniq
      raise ActiveRdfError, "cannot do keyword search over multiple subjects" if select_subject.size > 1

      keywords = query.keywords.collect {|subj,key| key}
      @ferret.search_each("object:#{keywords}") do |idx,score|
        subjects << @ferret[idx][:subject]
      end
      subjects.uniq! if query.distinct?
      where << "#{variable_name(query,select_subject.first)} in (#{subjects.collect {'?'}.join(',')})"
      right_hand_sides += subjects
    end

    if where.empty?
      ['',[]]
    else
      ["where " + where.join(' and '), right_hand_sides]
    end
  end

  def compute_where_condition(index, subclause, reasoning)
    conditions = [subclause]

    # expand conditions with rdfs rules if reasoning enabled
    if reasoning
      case index
      when 0: ;
        # no rule for subjects
      when 1:
        # expand properties to include all subproperties
        conditions = subproperties(subclause) if subclause.respond_to?(:uri)
      when 2:
        # no rule for objects
      when 3:
        # no rule for contexts
      end
    end

    # convert conditions into internal format
    #conditions.collect { |c| c.respond_to?(:uri) ? "<#{c.uri}>" : c.to_s }
    conditions.collect { |c| internalise(c) }
  end

  def subproperties(resource)
    # compute and store subproperties of this resource 
    # or use earlier computed value if available
    unless @subprops[resource]
      subproperty = Namespace.lookup(:rdfs,:subPropertyOf)
      children_query = Query.new.distinct(:sub).where(:sub, subproperty, resource)
      children_query.reasoning = false
      children = children_query.execute

      if children.empty?
        @subprops[resource] = [resource]
      else
        @subprops[resource] = [resource] + safe_flatten(children.collect{|c| subproperties(c)}).compact
      end
    end
    @subprops[resource]
  end

  # returns sql variable name for a queryterm
  def variable_name(query,term)
    # look up the first occurence of this term in the where clauses, and compute 
    # the level and s/p/o position of it
    index = nil
    # Hack to "safely find" the index of the term (as index(1) will call ==, which will execute a query on RDFS::Property)
    flat_clauses = safe_flatten(query.where_clauses)
    flat_clauses.each_index do |idx|
      element = flat_clauses[idx]
      if(element.respond_to?(:uri))
        found = (term.respond_to?(:uri) && (term.uri == element.uri))
      else
        found = (element == term)
      end
      if(found)
        index = idx
        break
      end
    end

    if index.nil? 
      # term does not appear in where clause
      # but maybe it appears in a keyword clause

      # index would not be nil if we had:
      # select(:o).where(knud, knows, :o).where(:o, :keyword, 'eyal')
      #
      # the only possibility that index is nil is if we have:
      # select(:o).where(:o, :keyword, :eyal) (selecting subject)
      # or if we use a select clause that does not appear in any where clause

      # so we check if we find the term in the keyword clauses, otherwise we throw 
      # an error
      if query.keywords.keys.include?(term)
        return "t0.s"
      else
        raise ActiveRdfError, "unbound variable :#{term.to_s} in select of #{query.to_sp}"
      end
    end

    termtable = "t#{index / 4}"
    termspo = SPOC[index % 4]
    return "#{termtable}.#{termspo}"
  end

  # wrap resources into ActiveRDF resources, literals into Strings. result_type
  # is the type that should be used for ActiveRDF resources
  def wrap(results, result_type)
    results.collect do |row|
      row.collect { |result| parse(result, result_type) }
    end
  end

  # Return the result as a correct type. result_type is the type that should 
  # be used for "resouce" elements
  def parse(result, result_type = RDFS::Resource)
    NTriplesParser.parse_node(result, result_type) || result
    #		case result
    #		when Literal
    #      # replace special characters to allow string interpolation for e.g. 'test\nbreak'
    #      $1.double_quote
    #		when Resource
    #   result_type.new($1)
    #		else
    #			# when we do a count(*) query we get a number, not a resource/literal
    #			result
    #		end
  end

  def create_indices(params)
    sidx = params[:sidx] || false
    pidx = params[:pidx] || false
    oidx = params[:oidx] || false
    spidx = params[:spidx] || true
    soidx = params[:soidx] || false
    poidx = params[:poidx] || true
    opidx = params[:opidx] || false

    # creating lookup indices
    @db.transaction do 
      @db.execute('create index if not exists sidx on triple(s)') if sidx
      @db.execute('create index if not exists pidx on triple(p)') if pidx
      @db.execute('create index if not exists oidx on triple(o)') if oidx
      @db.execute('create index if not exists spidx on triple(s,p)') if spidx
      @db.execute('create index if not exists soidx on triple(s,o)') if soidx
      @db.execute('create index if not exists poidx on triple(p,o)') if poidx
      @db.execute('create index if not exists opidx on triple(o,p)') if opidx
    end
  end

  # transform triple into internal format <uri> and "literal"
  def internalise(r)
    if r.nil? or r.is_a? Symbol
      nil
    else
      r.to_literal_s
    end
  end

  # transform resource/literal into ntriples format
  def serialise(r)
    # Fixme: r is most likely NOT a resource
    if r.nil?
      nil
    else
      r.to_literal_s
    end
  end
  
  # "Safe" flatten that doesn't recurse into properties (which would create a new query)
  def safe_flatten(ary)
    flattened = []
    ary.each do |element|
      if(!element.respond_to?(:uri) && element.is_a?(Array))
        flattened += safe_flatten(element)
      else
        flattened << element
      end
    end
    flattened
  end

  Resource = /<([^>]*)>/
  Literal = /"((?:\\"|[^"])*)"/

  public :subproperties
end

class String
  def double_quote
    Thread.new do
      $SAFE = 12
      begin
        eval('"%s"' % self)
      rescue Exception => e
        self
      end
    end.value
  end
end
