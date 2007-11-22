require 'active_rdf'

# Represents an RDF literal, optionally datatyped.
# TODO: language tags
class Literal
  Namespace.register :xsd, 'http://www.w3.org/2001/XMLSchema#'

  attr_reader :value, :type, :language
  @value, @type, @language = nil, nil, nil

  # Constructs literal with given datatype. If no datatype is given, automatic 
  # conversion from Ruby to XSD datatype is tried.
  def initialize(value, type_or_language=nil)
    @value = value
    
    if type_or_language.nil?
      # deduce type from the given value
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
    elsif type_or_language.to_s[0..0] == "@"
      # a language tag has been given
      @language = type_or_language[1..type_or_language.length]
    else
      # the type_or_language was not empty and did not start with a @ so it must be a data type
      @type = type_or_language
    end  

  end

  # returns string serialisation of literal, e.g. "test"^^xsd:string
  def to_s
    if type
      "\"#{value}\"^^#{type.to_s}"
    elsif language
      "\"#{value}\"@#{language}"
    else
      "\"value\""
    end
  end
end
