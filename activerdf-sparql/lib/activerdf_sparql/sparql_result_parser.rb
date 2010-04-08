# Parser for SPARQL XML result set.
class SparqlResultParser
  attr_reader :result

  # The resource_type is the class that 
  def initialize(resource_type)
    @result = []
    @vars = []
    @current_type = nil
    @resource_type = resource_type
  end

  def tag_start(name, attrs)
    case name
    when 'variable'
      @vars << attrs['name']
    when 'result'
      @current_result = []
    when 'binding'
      @index = @vars.index(attrs['name'])
    when 'bnode', 'literal', 'typed-literal', 'uri'
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
      @resource_type.new(value)
    when 'bnode'
      BNode.new(value)
    when 'literal','typed-literal'
      value.to_s
    end
  end

  def method_missing (*args)
  end
end
