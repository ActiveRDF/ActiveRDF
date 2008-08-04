require 'active_rdf'

# Translates abstract query into SPARQL that can be executed on SPARQL-compliant
# data source.
class Query2SPARQL
  def self.translate(query)
    str = ""
    if query.select?
      distinct = query.distinct? ? "DISTINCT " : ""
      select_clauses = query.select_clauses.collect{|s| construct_clause(s)}
      
      str << "SELECT #{distinct}#{select_clauses.join(' ')} "
      str << "#{from_clauses(query)}"
      str << "WHERE { #{where_clauses(query)} #{filter_clauses(query)}}"
      
      if query.limits
        str << " LIMIT #{query.limits.to_s}"
      end
      
      if query.offsets
        str << " OFFSET #{query.offsets.to_s}"
      end
      
      if (!query.sort_clauses.empty? || !query.reverse_sort_clauses.empty?)
        str << " ORDER BY"
        str << " ASC(#{sort_clauses(query)})" if !query.sort_clauses.empty?
        str << " DESC(#{reverse_sort_clauses(query)})" if !query.reverse_sort_clauses.empty?
      end
      
    elsif query.ask?
      str << "ASK { #{where_clauses(query)} }"
    end
    
    return str
  end
  
  # concatenate each from clause using space
  def self.from_clauses(query)
    params = []
    # construct single context clauses if context is present
    query.where_clauses.each {|s,p,o,c|
      params << "FROM #{construct_clause(c)}" unless c.nil?
    }
    
    # return FROM sintax or "" if no context is speficied
    if (params.empty?)
      ""
    else
      "#{params.join(' ')} "
    end
  end
  
  # concatenate each where clause using space (e.g. 's p o')
  # and concatenate the clauses using dot, e.g. 's p o . s2 p2 o2 .'
  def self.where_clauses(query)
    where_clauses = query.where_clauses.collect do |s,p,o,c|
      # ignore context parameter
      [s,p,o].collect {|term| construct_clause(term) }.join(' ')
    end
    "#{where_clauses.join('. ')} ."
  end
  
  def self.filter_clauses(query)
    "FILTER #{query.filter_clauses.join(" ")}" unless query.filter_clauses.empty?
  end
  
  def self.sort_clauses(query)
    sort_clauses = query.sort_clauses.collect do |term|     
      construct_clause(term)
    end

    "#{sort_clauses.join(' ')}"
  end
  
  def self.reverse_sort_clauses(query)
    reverse_sort_clauses = query.reverse_sort_clauses.collect do |term|
      construct_clause(term)
    end

     "#{reverse_sort_clauses.join(' ')}"
  end
  
  def self.construct_clause(term)
    if term.respond_to? :uri
      '<' + term.uri.to_s + '>'
    else
      case term
      when Symbol
        '?' + term.to_s
      else
        term.to_s
      end
    end
  end
  
  private_class_method :where_clauses, :construct_clause
end
