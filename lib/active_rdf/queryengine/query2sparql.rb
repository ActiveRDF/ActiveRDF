# require 'active_rdf'

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
      if (!query.sort_clauses.empty? || !query.reverse_sort_clauses.empty?)
        str << "ORDER BY "
        str << "#{sort_clauses(query)} " if !query.sort_clauses.empty?
        str << "#{reverse_sort_clauses(query)} " if !query.reverse_sort_clauses.empty?
      end
    elsif query.ask?
      str << "ASK { #{where_clauses(query)} } "
    end
    
    return str
  end

  # build filters in query
  def self.filter_clauses(query)
    filters = query.filter_clauses.collect do |filter|
      variable, operator, operand = filter[0], filter[1][0], filter[1][1]
      case operator
        when :lang
          tag, exact = operand
          if exact
            "lang(?#{variable}) = '#{tag}'"
          else
            "regex(lang(?#{variable}), '#{tag.gsub(/_.*/,'')}')"
          end
        when :datatype
          "datatype(?#{variable}) = #{operand.to_literal_s}"
        when :regex
          "regex(str(?#{variable}), '#{operand.to_s}')"
      end
    end
    "FILTER (#{filters.join(" && ")})" if filters.size > 0
  end

  def self.sort_clauses(query)
    sort_clauses = query.sort_clauses.collect do |term|
      "ASC(#{construct_clause(term)})"
    end

    sort_clauses.join(' ')
  end

  def self.reverse_sort_clauses(query)
    reverse_sort_clauses = query.reverse_sort_clauses.collect do |term|
      "DESC(#{construct_clause(term)})"
    end

    "#{reverse_sort_clauses.join(' ')}"
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

    o_idx = 0
		where_clauses = query.where_clauses.collect do |s,p,o,c|
      # does there where clause use a context ? 
		  if c.nil?
  			sp = [s,p].collect {|term| construct_clause(term) }.join(' ')
        # if all_types are requested, add filter for object value
        if query.all_types? and !o.respond_to?(:uri)   # dont wildcard resources
          o_var = "o#{o_idx}"
          o_val = o.respond_to?(:uri) ? o.uri : o.to_s
          query.filter(o_var.to_sym, :regex, o_val) 
          o_idx += 1
          "#{sp} ?#{o_var}"
        else
          "#{sp} #{construct_clause(o)}"
        end
  		else
        # TODO: add support for all_types to GRAPH queries
  		  "GRAPH #{construct_clause(c)} { #{construct_clause(s)} #{construct_clause(p)} #{construct_clause(o)} }"
		  end
		end

    "#{where_clauses.join(' . ')} ."
  end

	def self.construct_clause(term)
    case term
      when Symbol
        "?#{term}"
      when RDFS::Resource, RDFS::Literal
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
