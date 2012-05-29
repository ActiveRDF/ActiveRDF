require 'active_rdf/helpers'


# Direct access for Redland adapter
# 
# Syntax
# "<http://......>" = Resource
# "abc"             = Literal
# "_:"              = Blank Node
# "_:123"           = Blank Node with id
class DirectAccess
  
  # Execute a SPARQL query. The second parameter specify the result format (:json, :xml, :array) (optional)
  #
  # The return default value is an Array.
  # If you specify :xml or :json in result_format, the return value is a String that contain the request format.
  # 
  # Example: query("SELECT ?p ?o WHERE {<http://activerdf.org/test/eyal> ?p ?o}", :json)
  def self.sparql_query(query, result_format=:array)
    # verify input
    if query.nil?
      raise ActiveRdfError, "cannot execute empty query"
    end
    
    # verify class type
    if query.class != String
      raise ActiveRdfError, "query must be String."
    end
    
    # execute query
    FederationManager.query(query, {:result_format => result_format})
  end
  
  # Find all triple by subject and predicate
  # The return value is a PropertyList
  def self.find_all_by_subject_and_predicate(s,p)
    # verify input
    if s.nil? || p.nil?
      raise ActiveRdfError, "subject and predicate can't be nil"
    end
    
    # execute query
    query_result = self.sparql_query("SELECT ?o WHERE {#{s} #{p} ?o}")
    
    # return propertyList
    return PropertyList.new(p, query_result, s)
  end
  
end