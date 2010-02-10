# require 'active_rdf'
require 'time'

module RDFS
  module Literal
    Namespace.register :xsd, 'http://www.w3.org/2001/XMLSchema#'
    XSD::String = RDFS::Resource.new('http://www.w3.org/2001/XMLSchema#string')
    XSD::Integer = RDFS::Resource.new('http://www.w3.org/2001/XMLSchema#integer')
    XSD::Double = RDFS::Resource.new('http://www.w3.org/2001/XMLSchema#double')
    XSD::Boolean = RDFS::Resource.new('http://www.w3.org/2001/XMLSchema#boolean')
    XSD::Date = RDFS::Resource.new('http://www.w3.org/2001/XMLSchema#date')
    Class_uri = Namespace.lookup(:rdfs, :Literal)

    def self.class_uri
      Class_uri
    end

    def self.typed(value, type)
      case type
      when XSD::String
        String.new(value)
      when XSD::Integer
        value.to_i
      when XSD::Double
        value.to_f
      when XSD::Boolean
        value == 'true' or value == 1
      when XSD::Date
        DateTime.parse(value)
      else
        value
      end
    end

    def xsd_type
      case self
      when String
        XSD::String
      when Integer
        XSD::Integer
      when Float
        XSD::Double
      when TrueClass, FalseClass
        XSD::Boolean
      when DateTime, Date, Time
        XSD::Date
      end
    end
      
    def to_literal_s
      unless $activerdf_without_xsdtype
        s = kind_of?(Time) ? xmlschema : to_s
        "\"#{s}\"^^#{xsd_type}"
      else
        "\"#{to_s}\""
      end
    end
  end
end

class LocalizedString < String
  include RDFS::Literal

  attr_reader :lang
  def initialize(value, lang)
    super(value)
    @lang = lang =~ /^@/ ? lang[1..-1] : lang
  end

  def xsd_type
    XSD::String unless @lang   # don't return xsd_type if language is set (only lang or datatype may be set)
  end

  # returns quoted string with language type if present. 
  # xsd:string isn't appended when lang missing (xsd:string should be considered the default type)
  def to_literal_s
    unless $activerdf_without_xsdtype
      if @lang
        "\"#{self}\"@#@lang"
      else
        "\"#{self}\"^^#{XSD::String}"
      end
    else
      "\"#{self}\""
    end
  end
end

class String; include RDFS::Literal; end
class Integer; include RDFS::Literal; end
class Float; include RDFS::Literal; end
class DateTime; include RDFS::Literal; end
class Date; include RDFS::Literal; end
class Time; include RDFS::Literal; end
class TrueClass; include RDFS::Literal; end
class FalseClass; include RDFS::Literal; end
