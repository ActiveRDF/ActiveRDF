require 'active_rdf/storage/federated_store'

# Represents a query on a datasource, abstract representation of SPARQL
# features. Query is passed to federation manager or adapter for execution on
# data source.  In all clauses symbols represent variables:
# Query.new.select(:s).where(:s,:p,:o).
module ActiveRDF
  class Query
    attr_reader :select_clauses, :where_clauses, :filter_clauses, :sort_clauses, :limits, :offsets, :keywords

    bool_accessor :distinct, :ask, :select, :count, :keyword, :all_types

    # Creates a new query. You may pass a different class that is used for "resource"
    # type objects instead of RDFS::Resource
    def initialize(resource_type = RDFS::Resource)
      @distinct = false
      @select_clauses = []
      @where_clauses = []
      @filter_clauses = {}
      @sort_clauses = []
      @limits = nil
      @offsets = nil
      @keywords = {}
      @reasoning = nil
      @all_types = false
      @nil_clause_idx = -1
    set_resource_class(resource_type)
    end

    def initialize_copy(orig)
      # dup the instance variables so we're not messing with the original query's values
      instance_variables.each do |iv|
        orig_val = instance_variable_get(iv)
        case orig_val
          when Array,Hash
            instance_variable_set(iv,orig_val.dup)
        end
      end
    end

    # This returns the class that is be used for resources, by default this
    # is RDFS::Resource
    def resource_class
      @resource_class ||= RDFS::Resource
    end

    # Sets the resource_class. Any class may be used, however it is required
    # that it can be created using the uri of the resource as it's only 
    # parameter and that it has an 'uri' property
    def set_resource_class(resource_class)
      raise(ArgumentError, "resource_class must be a class") unless(resource_class.class == Class)

      test = resource_class.new("http://uri")
      raise(ArgumentError, "Must have an uri property") unless(test.respond_to?(:uri))
      @resource_class = resource_class
    end



    # Clears the select clauses
    def clear_select
      ActiveRdfLogger::log_debug(self) { "Cleared select clause" }
      @select_clauses = []
      @distinct = false
    end

    # Adds variables to select clause
    def select *s
      raise(ActiveRdfError, "variable must be a Symbol") unless s.all?{|var| var.is_a?(Symbol)}
      @select = true
      # removing duplicate select clauses
      @select_clauses.concat(s).uniq!
      self
    end

    # Adds variables to ask clause (see SPARQL specification)
    def ask
      @ask = true
      self
    end

    # Request reasoning be performed on query
    def reasoning(bool)
      @reasoning = truefalse(bool)
      self
    end
    def reasoning=(bool)
      self.reasoning(bool)
    end
    def reasoning?
      @reasoning
    end

    # Set query to ignore language & datatypes for objects
    def all_types(enabled = true)
      @all_types = enabled
      self
    end

    # Adds variables to select distinct clause
    def distinct *s
      @distinct = true
      select(*s)
    end
    alias_method :select_distinct, :distinct

    # Adds variables to count clause
    def count *s
      @count = true
      select(*s)
    end

    # Adds sort predicates
    # 
    def sort *s
      s.each do |var| 
        raise(ActiveRdfError, "variable must be a Symbol") unless var.is_a? Symbol
        @sort_clauses << [var,:asc]
      end
      self
    end

    # adds reverse sorting predicates
    def reverse_sort *s
      s.each do |var| 
        raise(ActiveRdfError, "variable must be a Symbol") unless var.is_a? Symbol
        @sort_clauses << [var,:desc]
      end
      self
    end

    # adds operator filter on one variable
    # variable is a Ruby symbol that appears in select/where clause, operator is a
    # SPARQL operator (e.g. '>','lang','datatype'), operand is a SPARQL value (e.g. 15)
    def filter(variable, operator, operand)
      raise(ActiveRdfError, "variable must be a Symbol") unless variable.is_a? Symbol
      @filter_clauses[variable] = [operator.to_sym,operand]
      self
    end

    # adds regular expression filter on one variable
    # variable is Ruby symbol that appears in select/where clause, regex is Ruby
    # regular expression
    def regexp(variable, regexp)
      raise(ActiveRdfError, "variable must be a symbol") unless variable.is_a? Symbol
      regexp = regexp.source if(regexp.is_a?(Regexp))
      filter(variable, :regexp, regexp)
    end
    alias :regex :regexp

    # filter variable on specified language tag, e.g. lang(:o, 'en', true)
    # optionally matches exactly on language dialect, otherwise only
    # language-specifier is considered
    def lang(variable, tag, exact=true)
      filter(variable,:lang,[tag.sub(/^@/,''),exact])
    end

    def datatype(variable, type)
      filter(variable,:datatype,type)
    end

    # Adds limit clause (maximum number of results to return)
    def limit(i)
      @limits = i.to_i
      self
    end

    # Add offset clause (ignore first n results)
    def offset(i)
      @offsets = i.to_i
      self
    end

    # Adds where clauses (s,p,o) where each constituent is either variable (:s) or
  # an RDFS::Resource (or equivalent class). Keyword queries are specified with the special :keyword 
    # symbol: Query.new.select(:s).where(:s, :keyword, 'eyal')
    def where s,p,o,c=nil
      case p
      when :keyword
        # treat keywords in where-clauses specially
        keyword_where(s,o)
      else
        # give nil clauses a unique variable
        s,p,o = [s,p,o].collect{|clause| clause.nil? ? "nil#{@nil_clause_idx += 1}".to_sym : clause}

        # remove duplicate variable bindings, e.g.
        # where(:s,type,:o).where(:s,type,:oo) we should remove the second clause,
        # since it doesn't add anything to the query and confuses the query
        # generator.
        # if you construct this query manually, you shouldn't! if your select
        # variable happens to be in one of the removed clauses: tough luck.
      unless (s.respond_to?(:uri) or s.is_a?(Symbol)) and (s.class != RDFS::BNode)
        raise(ActiveRdfError, "Cannot add a where clause with s #{s}: s must be a resource or a variable, is a #{s.class.name}")
        end
      unless (p.respond_to?(:uri) or p.is_a?(Symbol)) and (s.class != RDFS::BNode)
        raise(ActiveRdfError, "Cannot add a where clause with p #{p}: p must be a resource or a variable, is a #{p.class.name}")
        end
      raise(ActiveRdfErrror, "Cannot add a where clause where o is a blank node") if(o.class == RDFS::BNode)

        @where_clauses << [s,p,o,c]
      end
      self
    end

    # Adds keyword constraint to the query. You can use all Ferret query syntax in
    # the constraint (e.g. keyword_where(:s,'eyal|benjamin')
    def keyword_where s,o
      @keyword = true
      if @keywords.include?(s)
        @keywords[s] = @keywords[s] + ' ' + o
      else
        @keywords[s] = o
      end
      self
    end

    # Executes query on data sources. Either returns result as array
    # (flattened into single value unless specified otherwise)
    # or executes a block (number of block variables should be
    # same as number of select variables)
    #
    # usage:: results = query.execute
    # usage:: query.execute do |s,p,o| ... end
    def execute(options={:flatten => false}, &block)
      options = {:flatten => true} if options == :flatten

      prepared_query = prepare_query(options)

      if block_given?
        for result in FederationManager.execute(prepared_query, options.merge(:flatten => false))
          yield result
        end
      else
        FederationManager.execute(prepared_query, options)
      end
    end

    # Returns query string depending on adapter (e.g. SPARQL, N3QL, etc.)
    def to_s
      if ConnectionPool.read_adapters.empty?
        inspect
      else
        ConnectionPool.read_adapters.first.translate(prepare_query)
      end
    end

    # Returns SPARQL serialisation of query
    def to_sp
    require 'active_rdf/query/query2sparql' unless(defined?(Query2SPARQL))
      Query2SPARQL.translate(self)
    end

    private
    def prepare_query(options = {})
      # leave the original query intact
      dup = self.dup
      dup.expand_obj_values
      # dup.reasoned_query if dup.reasoning?

      # extract options
      if options.include?(:order)
        dup.sort(:sort_value)
        dup.where(:s, options.delete(:order), :sort_value)
      end

      if options.include?(:reverse_order)
        dup.reverse_sort(:sort_value)
        dup.where(:s, options.delete(:reverse_order), :sort_value)
      end

      dup.limit(options.delete(:limit)) if options.include?(:limit)
      dup.offset(options.delete(:offset)) if options.include?(:offset)

      dup
    end

    protected
    def expand_obj_values
      new_where_clauses = []
      @where_clauses.each do |s,p,o,c|
        if o.respond_to?(:to_ary)
          o.to_ary.each{|elem| new_where_clauses << [s,p,elem,c]}
        else
          new_where_clauses << [s,p,o,c]
        end
      end
      @where_clauses = new_where_clauses
    end

  #  def reasoned_query
  #    new_where_clauses = []
  #    @where_clauses.each do |s,p,o,c|
  #      # other reasoning should be added here
  #    end
  #    @where_clauses += new_where_clauses
  #  end
  end
end