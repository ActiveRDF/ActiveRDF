require 'active_rdf'

# Represents an RDF literal, optionally datatyped.
# TODO: language tags
class Literal
  Namespace.register :xsd, 'http://www.w3.org/2001/XMLSchema#'

  attr_reader :value, :type
  @value, @type = nil, nil

  # Constructs literal with given datatype. If no datatype is given, automatic 
  # conversion from Ruby to XSD datatype is tried.
  def initialize(value, type=nil)
    @value = value
    @type = type

    if @type.nil?
      @type = case value
             when String
               XSD::string
             when Date, Time, DateTime
               XSD::date
             when TrueClass, FalseClass
               XSD::boolean
             when Fixnum
               XSD::integer
             end
    end
  end

  # returns string serialisation of literal, e.g. "test"^^xsd:string
  def to_s
    if type
      "\"#{value}\"^^#{type.to_s}"
    else
      "\"value\""
    end
  end
end
