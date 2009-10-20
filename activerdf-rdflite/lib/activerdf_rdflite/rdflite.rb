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

# RDFLite is a lightweight RDF database on top of sqlite3. It can act as adapter
# in ActiveRDF. It supports on-disk and in-memory usage, and allows keyword
# search if ferret is installed.
module ActiveRDF
  class RDFLite < ActiveRdfAdapter
    $activerdflog.info "loading RDFLite adapter"

    begin
      require 'ferret'
      @@have_ferret = true
    rescue LoadError
      $activerdflog.info "Keyword search is disabled since we could not load Ferret. To
      enable, please do \"gem install ferret\""
      @@have_ferret = false
    end

    ConnectionPool.register_adapter(:rdflite,self)
    bool_accessor :keyword_search, :reasoning

    # instantiates RDFLite database
    # available parameters:
    # * :location => filepath (defaults to memory)
    # * :keyword => true/false (defaults to false)
    # * :pidx, :oidx, etc. => true/false (enable/disable these indices)
    def initialize(params = {})
      super

      @reasoning = truefalse(params[:reasoning], false)
      @subprops = {} if @reasoning

      # if no file-location given, we use in-memory store
      file = params[:location] || ':memory:'
      @db = SQLite3::Database.new(file)

      # disable keyword search by default, enable only if ferret is found
      @keyword_search = truefalse(params[:keyword], false) && @@have_ferret

      # turn off filesystem synchronisation for speed
      @db.synchronous = 'off'

      # drop the table if a new datastore is requested
      @db.execute('drop table if exists triple') if truefalse(params[:new],false)

      # create triples table. ignores duplicated triples
      @db.execute('create table if not exists triple(s,p,o,c, unique(s,p,o,c) on conflict ignore)')

      create_indices(params)
      @db

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
    def delete(s, p, o=nil, c=nil)
      where_clauses = []
      conditions = []

      [s,p,o,c].each_with_index do |r,i|
        unless r.nil? or r.is_a?(Symbol)
          where_clauses << "#{SPOC[i]} = ?"
          conditions << r.to_literal_s
        end
      end

      # construct delete string
      ds = 'delete from triple'
      ds << " where #{where_clauses.join(' and ')}" unless where_clauses.empty?

      # execute delete string with possible deletion conditions (for each
      # non-empty where clause)
      $activerdflog.debug("deleting #{[s,p,o,c].join(' ')}")
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

      c = c.to_literal_s unless c.nil?

      # insert triple into database
      @db.execute('insert into triple values (?,?,?,?);',s.to_literal_s,p.to_literal_s,o.to_literal_s,c)

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
    def load(location, syntax = nil)
      context = if @contexts
                  if URI.parse(location).host
                    RDFS::Resource.new(location)
                   else
                    RDFS::Resource.new("file:#{location}")
                  end
                else
                  nil
                end

      if MIME::Types.of(location) == MIME::Types['application/rdf+xml'] or syntax == 'rdfxml'
        # check if rapper available
        begin
          # can only parse rdf/xml with redland
          # die otherwise
          require 'rdf/redland'
          model = Redland::Model.new
          Redland::Parser.new(syntax).parse_into_model(model, location)
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
    def add_ntriples(ntriples, context = nil)
      # add each triple to db
      @db.transaction

      ntriples = NTriplesParser.parse(ntriples)
      ntriples.each do |s,p,o|
        add(s,p,o,context)

        # if keyword-search available, insert the object into keyword search
        @ferret << {:subject => s.to_s, :object => o.to_s} if keyword_search?
      end

      @db.commit
      @db
    end

  # executes ActiveRDF query on datastore
    def execute(query)
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
        return wrap(query, results)
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
    # begins with first element of construct traverses tables referenced by
    def construct_join(query)
      join_stmt = []
      seen_aliases = ['t0']  # first table already seen
      seen_vars = []

      # get a hash with indices for for all terms
      # if the term doesnt have a join-buddy, we can skip it
      occurances = term_occurances(query).reject{|var,terms| terms.size < 2}

      # start with variables in first where clause
      var_queue = query.where_clauses[0].find_all{|obj| obj.is_a?(Symbol) and occurances.include?(obj)}

      while !var_queue.empty? do
        var = var_queue.shift
        seen_vars << var
        terms = occurances[var]

        # look for a term in a table that has already been seen
        table,field = terms.find{|table,field| seen_aliases.include?(table)}
        raise ActiveRdfError, "query is confused. haven't seen #{table} for :#{var} yet." unless table
        terms -= [[table,field]]   # ignore this previously seen buddy term table
        first_term = "#{table}.#{field}"

        terms.each do |table,field|
          join = ''
          unless seen_aliases.include?(table)
            seen_aliases << table
            join << "join triple as #{table} on "
          else
            join << "and "
          end
          join << "#{first_term}=#{table}.#{field} "
          join_stmt << join

          # add any terms from this table that haven't been seen yet to the queue
          var_queue.concat query.where_clauses[table[1..-1].to_i].find_all{|obj| obj.is_a?(Symbol) and !seen_vars.include?(obj) and occurances.include?(obj)}
        end
      end

      join = ' from triple as t0 '
      join_stmt.empty? ? join : join + "#{join_stmt.join(' ')} "
    end

    # Returns a hash of arrays, keyed by the term symbol. Each element of the array is nested array of a pair of values: [table alias, field('s'|'p'|'o'|'c')]
    # {:s => [[table,field],['t0','s'],...], :p => [['t0','p'],['t1','p']]}
    def term_occurances(query)
      term_occurances = {}
      query.where_clauses.each_with_index do |clause, table_index|
        clause.zip(SPOC).each do |obj,field|
          if obj.is_a?(Symbol)
            (term_occurances[obj] ||= []) << ["t#{table_index}",field]
          end
        end
      end
      term_occurances
    end

    # construct where clause
    def construct_where(query)
      # collecting where clauses, these will be added to the sql string later
      where = []

      # collecting all the right-hand sides of where clauses (e.g. where name =
      # 'abc'), to add to query string later using ?-notation, because then
      # sqlite will automatically encode quoted literals correctly
      right_hand_sides = []

      query.where_clauses.each_with_index do |clause, table_index|
        clause.zip(SPOC).each do |clause_elem,field|
          if !(clause_elem.is_a?(Symbol) or clause_elem.nil?)
            # include querying on subproperty fields
            if field == 'p' and query.reasoning? and $activerdf_internal_reasoning
              predicate = clause_elem
              predicates = [predicate] + predicate.sub_predicates
              if predicates.size > 1
                where << "t#{table_index}.#{field} in ('#{predicates.collect{|res| res.to_literal_s}.join("','")}')"
              else
                where << "t#{table_index}.#{field} = ?"
                right_hand_sides << predicates[0].to_literal_s
              end
            else
              # match plain strings to all strings
              if query.all_types? and !clause_elem.respond_to?(:uri)  # dont wildcard resources
                where << "t#{table_index}.#{field} like ?"
                right_hand_sides << "\"#{clause_elem.to_s}\"%"
              else
                where << "t#{table_index}.#{field} = ?"
                right_hand_sides << clause_elem.to_literal_s
              end
            end
          # process filters
          elsif field == 'o' and clause_elem.is_a?(Symbol) and (filter = query.filter_clauses[clause_elem])
            operator, operand = filter
            case operator
              when :datatype
                where << "t#{table_index}.o like ?"
                right_hand_sides << "%\"^^<#{operand}>"
              when :lang
                lang, exact = operand
                where << "t#{table_index}.o like ?"
                right_hand_sides << (exact ? "%\"@#{lang}" : "%\"@%#{lang}%")
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

    # returns first sql variable name found for a queryterm
    def variable_name(query,term)
      if (indices = term_occurances(query)[term])
        table, field = indices[0]
        "#{table}.#{field}"
      end
    end

  # wrap resources into ActiveRDF resources, literals into Strings
    def wrap(query, results)
      results.collect do |row|
        row.collect { |result| parse(result) }
      end
    end

    def parse(result)
      NTriplesParser.parse_node(result)
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
  end
end