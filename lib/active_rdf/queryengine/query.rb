require 'active_rdf'
require 'federation/federation_manager'

# Represents a query on a datasource, abstract representation of SPARQL 
# features. Query is passed to federation manager or adapter for execution on 
# data source.  In all clauses symbols represent variables: 
# Query.new.select(:s).where(:s,:p,:o).
class Query
	attr_reader :select_clauses, :where_clauses, :sort_clauses, :keywords, :limits, :offsets
	bool_accessor :distinct, :ask, :select, :count, :keyword, :reasoning

	def initialize
		distinct = false
		limit = nil
		offset = nil
		@select_clauses = []
		@where_clauses = []
		@sort_clauses = []
		@keywords = {}
		@reasoning = true
	end

	# Clears the select clauses
	def clear_select
		$activerdflog.debug "cleared select clause"
		@select_clauses = []
		distinct = false
	end

	# Adds variables to select clause
	def select *s
		@select = true
		s.each do |e|
			@select_clauses << parametrise(e) 
		end
		# removing duplicate select clauses
		@select_clauses.uniq!
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

	# Adds sort predicates (must appear in select clause)
	def sort *s
		s.each do |e|
			@sort_clauses << parametrise(e) 
		end
		# removing duplicate select clauses
		@sort_clauses.uniq!
		self
	end

	# Adds limit clause (maximum number of results to return)
	def limit(i)
		@limits = i 
		self
	end

	# Add offset clause (ignore first n results)
	def offset(i)
		@offsets = i
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

			unless [RDFS::Resource, Symbol].include?(s.class)
				raise(ActiveRdfError, "cannot add a where clause with s #{s}: s must be a resource or a variable")
			end
			unless [RDFS::Resource, Symbol].include?(s.class)
				raise(ActiveRdfError, "cannot add a where clause with p #{p}: p must be a resource or a variable")
			end

			@where_clauses << [s,p,o,c].collect{|arg| parametrise(arg)}
		end
    self
  end

	# Adds keyword constraint to the query. You can use all Ferret query syntax in 
	# the constraint (e.g. keyword_where(:s,'eyal|benjamin')
	def keyword_where s,o
		@keyword = true
		s = parametrise(s)
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
    if block_given?
      FederationManager.query(self) do |*clauses|
        block.call(*clauses)
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

  private
  def parametrise s
    case s
    when Symbol
			s
    when RDFS::Resource
      s
		when nil
			nil
    when Literal
      s
    else
      '"' + s.to_s + '"'
    end
  end
end
