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
      str << "WHERE { #{where_clauses(query)} #{filter_clauses(query)}}"
      
      if query.limits
        str << " LIMIT #{query.limits.to_s}"
      end
      
      if query.offsets
        str << " OFFSET #{query.offsets.to_s}"
      end
      
    elsif query.ask?
      str << "ASK { #{where_clauses(query)} }"
    end
    
    return str
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

	def self.construct_clause(term)
    if term.respond_to? :uri
      '<' + term.uri + '>'
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
