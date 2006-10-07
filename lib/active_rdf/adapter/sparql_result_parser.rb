# parser for SPARQL XML result set
#
# Author:: Sebastian Gerke
# Copyright:: (c) 2005-2006
# License:: LGPL
class SparqlResultParser
  
  attr_reader :result

  def initialize
    @result = []
    @vars = []
    @current_type = nil
  end
  
  def tag_start(name, attrs)
    if name == 'variable'
      @vars << attrs['name']
    elsif name == 'result'
      @current_result = []
    elsif name == 'binding'
      @index = @vars.index(attrs['name'])
    elsif name == 'bnode' || name == 'literal' || name == 'typed-literal' || name == 'uri'
      @current_type = name
    end
  end
  
  def tag_end(name)
    if name == "result"
      @result << @current_result
    elsif name == 'bnode' || name == 'literal' || name == 'typed-literal' || name == 'uri'
      @current_type = nil
    elsif name == "sparql"
    end
  end
  
  def text(text)
    if !@current_type.nil?
      @current_result[@index] = create_node(@current_type, text)  
    end
  end

  # create ruby objects for each RDF node
  def create_node(type, value)
    case type
    when 'uri'
      RDFS::Resource.new(value)
    when 'bnode'
      nil
    when 'literal','typed-literal'
      value.to_s
    end
  end
  
  def method_missing (*args)
  end
end
