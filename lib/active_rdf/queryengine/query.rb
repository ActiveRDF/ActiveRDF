require 'active_rdf'
require 'federation/federation_manager'

# Represents a query on a datasource, abstract representation of SPARQL 
# features. Query is passed to federation manager or adapter for execution on 
# data source.  In all clauses symbols represent variables: 
# Query.new.select(:s).where(:s,:p,:o).
class Query
	attr_reader :select_clauses, :where_clauses, :sort_clauses, :keywords, :limits, :offsets, :reverse_sort_clauses, :filter_clauses

	bool_accessor :distinct, :ask, :select, :count, :keyword, :reasoning

	def initialize
		@distinct = false
		@limit = nil
		@offset = nil
		@select_clauses = []
		@where_clauses = []
		@sort_clauses = []
    @filter_clauses = []
		@keywords = {}
		@reasoning = true
    @reverse_sort_clauses = []
	end

	# Clears the select clauses
	def clear_select
		$activerdflog.debug "cleared select clause"
		@select_clauses = []
		@distinct = false
	end

	# Adds variables to select clause
	def select *s
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
	def sort *s
    # add sort clauses without duplicates
		@sort_clauses.concat(s).uniq!
		self
	end

  # adds one or more generic filters
  # NOTE: you have to use SPARQL syntax for variables, eg. regex(?s, 'abc')
  def filter *s
    # add filter clauses
    @filter_clauses.concat(s).uniq!
    self
  end

  # adds regular expression filter on one variable
  # variable is Ruby symbol that appears in select/where clause, regex is Ruby 
  # regular expression
  def filter_regexp(variable, regexp)
    raise(ActiveRdfError, "variable must be a symbol") unless variable.is_a? Symbol
    raise(ActiveRdfError, "regexp must be a ruby regexp") unless regexp.is_a? Regexp

    filter "regex(str(?#{variable}), #{regexp.inspect.gsub('/','"')})"
  end
  alias :filter_regex :filter_regexp

  # adds operator filter one one variable
  # variable is a Ruby symbol that appears in select/where clause, operator is a 
  # SPARQL operator (e.g. '>'), operand is a SPARQL value (e.g. 15)
  def filter_operator(variable, operator, operand)
    raise(ActiveRdfError, "variable must be a Symbol") unless variable.is_a? Symbol

    filter "?#{variable} #{operator} #{operand}"
  end

  # filter variable on specified language tag, e.g. lang(:o, 'en')
  # optionally matches exactly on language dialect, otherwise only 
  # language-specifier is considered
  def lang(variable, tag, exact=false)
    tag = tag.sub(/^@/,'')
    if exact
      filter "lang(?#{variable}) = '#{tag}'"
    else
      filter "regex(lang(?#{variable}), '^#{tag.gsub(/_.*/,'')}$')"
    end
  end

  def xsd_type(variable, type)
    filter "datatype(?#{variable}) = #{type.to_literal_s}"
  end

  # adds reverse sorting predicates
  def reverse_sort *s
    # add sort clauses without duplicates
    @reverse_sort_clauses.concat(s).uniq!
		self
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
	# an RDFS::Resource. Keyword queries are specified with the special :keyword 
	# symbol: Query.new.select(:s).where(:s, :keyword, 'eyal')
	def where s,p,o,c=nil
		case p
		when :keyword
			# treat keywords in where-clauses specially
			keyword_where(s,o)
		else
			# remove duplicate variable bindings, e.g.
			# where(:s,type,:o).where(:s,type,:oo) we should remove the second clause, 
			# since it doesn't add anything to the query and confuses the query 
			# generator. 
			# if you construct this query manually, you shouldn't! if your select 
			# variable happens to be in one of the removed clauses: tough luck.

			unless s.respond_to?(:uri) or s.is_a?(Symbol)
				raise(ActiveRdfError, "cannot add a where clause with s #{s}: s must be a resource or a variable")
			end
			unless p.respond_to?(:uri) or p.is_a?(Symbol)
				raise(ActiveRdfError, "cannot add a where clause with p #{p}: p must be a resource or a variable")
			end

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

    if block_given?
      for result in FederationManager.query(self, options)
        yield result
      end
    else
      FederationManager.query(self, options)
    end
  end

	# Returns query string depending on adapter (e.g. SPARQL, N3QL, etc.)
  def to_s
		if ConnectionPool.read_adapters.empty?
			inspect 
		else
			ConnectionPool.read_adapters.first.translate(self)
		end
  end

	# Returns SPARQL serialisation of query
  def to_sp
		require 'queryengine/query2sparql'
		Query2SPARQL.translate(self)
  end

  # Parameterization removed. This should be handled by the adapter.
end
