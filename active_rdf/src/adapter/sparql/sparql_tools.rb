# = sparql_tools.rb
#
# Tools for SPARQL adapter
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#

require 'active_rdf'
require 'adapter/abstract_adapter'

class SparqlAdapter  
  def parse_sparql_query_result_json(query_result)
    require 'rubygems'
    require 'json'
    
    parsed_object = JSON.parse(query_result)
    return [] if parsed_object.nil?
    
    results = []    
    vars = parsed_object['head']['vars']
    objects = parsed_object['results']['bindings']
    if vars.length > 1
      objects.each do |obj|
        result = []
        vars.each do |v|
          result << create_node( obj[v]['type'], obj[v]['value'])
        end
        results << result
      end
    else
      objects.each do |obj| 
        obj.each_value do |e|
          results << create_node(e['type'], e['value'])
        end
      end
    end
    return results
  end
  
  def parse_sparql_query_result_xml(query_result)
    require 'rexml/document'
    results = []
    vars = []
    objects = []
    doc = REXML::Document.new query_result
    doc.elements.each("*/head/variable") {|v| vars << v.attributes["name"]}
    doc.elements.each("*/results/result") {|o| objects << o}
    if vars.length > 1
      objects.each do |result|
        myResult = []
        vars.each do |v|
          result.each_element_with_attribute('name', v) do |binding|
            binding.elements.each do |e|
              type = e.name
              value = e.text
              myResult << create_node(type, value)
            end            
          end          
        end
        results << myResult
      end
      
    else
      objects.each do |bs| 
        bs.elements.each("binding") do |b|
          b.elements.each do |e|
            type = e.name
            value = e.text
            results << create_node(type, value)
          end
        end
      end
    end
    return results
  end
  
  def create_node(type, value)
    case type
    when 'uri'
      return IdentifiedResource.create(value)
    when 'bnode'
      return nil	
      # raise(ActiveRdfError, "Blank Node not implemented.")
    when 'literal'
      return Literal.create(value)
    when 'typed-literal'
      return Literal.create(value)
    end
  end
end
