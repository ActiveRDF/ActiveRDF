# translates abstract query into SPARQL that can be executed on SPARQL-compliant data source
#
# Author:: Eyal Oren
# Copyright:: (c) 2005-2006
# License:: LGPL
require 'active_rdf'

class Query2SPARQL
  def self.translate(query)
    $log.debug "received query ..."
    str = ""
    if query.select?
      distinct = query.distinct? ? "DISTINCT " : ""
      str << "SELECT #{distinct}#{query.select_clauses.join(' ')} "
      str << "WHERE { #{where_clauses(query)} }"
    elsif query.ask?
      str << "ASK { #{where_clauses(query)} }"
    end
    $log.debug "translated into spqrql: ..."
    return str
  end

  private
  # concatenate each where clause using space (e.g. 's p o')
  # and concatenate the clauses using dot, e.g. 's p o . s2 p2 o2 .'
  def self.where_clauses(query)
    "#{query.where_clauses.collect{|w| w.join(' ')}.join('. ')} ."
  end
end
