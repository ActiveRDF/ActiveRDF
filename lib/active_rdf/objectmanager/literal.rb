require 'time'

module RDFS
  module Literal
    ActiveRDF::Namespace.register :xsd, 'http://www.w3.org/2001/XMLSchema#'

    class << self
      attr_accessor :class_uri
    end

    # convert value to class type
    def self.typed(value, type)
      case type
      when XSD::string
        String.new(value)
      when XSD::integer
        value.to_i
      when XSD::double
        value.to_f
      when XSD::boolean
        value == 'true' or value == 1
      when XSD::dateTime
        DateTime.parse(value)
      when XSD::time
        Time.parse(value)
      when XSD::date
        Date.parse(value)
      else
        value
      end
    end

    def xsd_type
      case self
      when String
        XSD::string
      when Integer
        XSD::integer
      when Float
        XSD::double
      when TrueClass, FalseClass
        XSD::boolean
      when DateTime
        XSD::dateTime
      when Date
        XSD::date
      when Time
        XSD::time
      end
    end
    alias :datatype :xsd_type

    def to_literal_s
      s = kind_of?(Time) ? xmlschema : to_s
      unless $activerdf_without_datatype
        "\"#{s}\"^^<#{xsd_type}>"
      else
        "\"#{s}\""
      end
    end
  end
  Literal.class_uri = RDFS::Literal
end

class String; include RDFS::Literal; end
class Integer; include RDFS::Literal; end
class Float; include RDFS::Literal; end
class DateTime; include RDFS::Literal; end
class Date; include RDFS::Literal; end
class Time; include RDFS::Literal; end
class TrueClass; include RDFS::Literal; end
class FalseClass; include RDFS::Literal; end

class LocalizedString < String
  include RDFS::Literal

  attr_reader :lang
  def initialize(value, lang)
    super(value)
    @lang = lang.sub(/^@/,'')
  end

  def ==(other)
    if other.is_a?(LocalizedString)
      super && @lang == other.lang
    else
      super
    end
  end
  alias_method :eql?, :==

  def inspect
    super + "@#@lang"
  end

  # returns quoted string with language type if present.
  # xsd:string isn't appended when lang missing (xsd:string should be considered the default type)
  def to_literal_s
    $activerdf_without_datatype ? "\"#{self}\"" : "\"#{self}\"@#@lang"
  end
end