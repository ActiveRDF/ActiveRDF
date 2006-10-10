# Represents a query on a datasource, abstract representation of SPARQL features
# is passed to federation/adapter for execution on data
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL
require 'active_rdf'
require 'federation/federation_manager'

class Query
  attr_reader :select_clauses, :where_clauses
  bool_accessor :distinct, :ask, :select, :count

  def initialize
    distinct = false
    @select_clauses = []
    @where_clauses = []
  end

	def clear_select
		@select_clauses = []
		distinct = false
	end

  def select *s
    @select = true
    s.each do |e|
      @select_clauses << parametrise(e) 
    end
		# removing duplicate select clauses
		@select_clauses.uniq!

    self
  end

  def ask
    @ask = true
    self
  end

  def distinct *s
    @distinct = true
    select(*s)
  end

	def count *s
		@count = true
		select(*s)
	end

  alias_method :select_distinct, :distinct

  def where s,p,o
		# remove duplicate variable bindings, e.g.
		# where(:s,type,:o).where(:s,type,:oo) we should remove the second clause, 
		# since it doesn't add anything to the query and confuses the query 
		# generator. 
		# if you construct this query manually, you shouldn't! if your select 
		# variable happens to be in one of the removed clauses: tough luck.
    @where_clauses << [s,p,o].collect{|arg| parametrise(arg)}
    self
  end

# this is not normal behaviour, the method is implemented inside FacetNavigation
#	def replace_where_clause old,new
#		return unless where_clauses.includes?(old)
#		where_clauses.delete(old)
#		where_clauses.insert(new)
#	end

  # execute query on data sources
  # either returns result as array
  # (flattened into single value unless specified otherwise)
  # or executes a block (number of block variables should be
  # same as number of select variables)
  #
  # usage: results = query.execute
  # usage: query.execute do |s,p,o| ... end
  def execute(options={:flatten => true}, &block)
    if block_given?
      FederationManager.query(self) do |*clauses|
        block.call(*clauses)
      end
    else
      FederationManager.query(self, options)
    end
  end

  def to_s
    require 'queryengine/query2sparql'
    Query2SPARQL.translate(self)
  end

  private
  def parametrise s
    case s
    when Symbol
      '?' + s.to_s
    when RDFS::Resource
      s
    else
      '"' + s.to_s + '"'
    end
  end
end
