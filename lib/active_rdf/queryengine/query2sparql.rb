require 'active_rdf'

# TODO: support limit and offset

# Translates abstract query into SPARQL that can be executed on SPARQL-compliant
# data source.
class Query2SPARQL
  Engines_With_Keyword = [:yars2, :virtuoso]
  def self.translate(query, engine=nil)
    str = ""
    if query.select?
      distinct = query.distinct? ? "DISTINCT " : ""
			select_clauses = query.select_clauses.collect{|s| construct_clause(s)}

      str << "SELECT #{distinct}#{select_clauses.join(' ')} "
      str << "WHERE { #{where_clauses(query)} #{filter_clauses(query)}} "
      str << "LIMIT #{query.limits} " if query.limits
      str << "OFFSET #{query.offsets} " if query.offsets
    elsif query.ask?
      str << "ASK { #{where_clauses(query)} } "
    end
    
    return str
  end

  # concatenate filters in query
  def self.filter_clauses(query)
    "FILTER (#{query.filter_clauses.join(" && ")})" unless query.filter_clauses.empty?
  end

  # concatenate each where clause using space (e.g. 's p o')
  # and concatenate the clauses using dot, e.g. 's p o . s2 p2 o2 .'
  def self.where_clauses(query)
    if query.keyword?
      case sparql_engine
      when :yars2
        query.keywords.each do |term, keyword|
          query.where(term, keyword_predicate, keyword)
        end
      when :virtuoso
        query.keywords.each do |term, keyword|
          query.filter("#{keyword_predicate}(#{construct_clause(term)}, '#{keyword}')")
        end
      end
    end

		where_clauses = query.where_clauses.collect do |s,p,o,c|
      # does there where clause use a context ? 
		  if c.nil?
  			[s,p,o].collect {|term| construct_clause(term) }.join(' ')
  		else
  		  "GRAPH #{construct_clause(c)} { #{construct_clause(s)} #{construct_clause(p)} #{construct_clause(o)} }"
		  end
		end

    "#{where_clauses.join(' . ')} ."
  end

	def self.construct_clause(term)
    case term
      when Symbol
        "?#{term}"
      when RDFS::Resource
        raise ActiveRdfError, "emtpy RDFS::Resources not allowed" if term.uri.size == 0
        term.to_literal_s
      when String
        "\"#{term}\""
      when RDFS::Literal
        term.to_literal_s
      when Class
        raise ActiveRdfError, "class must inherit from RDFS::Resource" unless term.ancestors.include?(RDFS::Resource)
        term.class_uri.to_literal_s
      when nil
        nil
      else
        "\"#{term.to_s}\""
    end
	end

  def self.sparql_engine
    sparql_adapters = ConnectionPool.read_adapters.select{|adp| adp.is_a? SparqlAdapter}
    engines = sparql_adapters.collect {|adp| adp.engine}.uniq

    unless engines.all?{|eng| Engines_With_Keyword.include?(eng)}
      raise ActiveRdfError, "one or more of the specified SPARQL engines do not support keyword queries" 
    end

    if engines.size > 1
      raise ActiveRdfError, "we currently only support keyword queries for one type of SPARQL engine (e.g. Yars2 or Virtuoso) at a time"
    end

    return engines.first
  end

  def self.keyword_predicate
    case sparql_engine
    when :yars, :yars2
      RDFS::Resource.new("http://sw.deri.org/2004/06/yars#keyword")
    when :virtuoso
      VirtuosoBIF.new("bif:contains")
    else
      raise ActiveRdfError, "default SPARQL does not support keyword queries, remove the keyword clause or specify the type of SPARQL engine used"
    end
  end
	
  private_class_method :where_clauses, :construct_clause, :keyword_predicate, :sparql_engine
end

# treat virtuoso built-ins slightly different: they are URIs but without <> 
# surrounding them
class VirtuosoBIF < RDFS::Resource
  def to_s
    uri
  end
end
