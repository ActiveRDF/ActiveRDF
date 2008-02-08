require 'active_rdf'

module Literal
  Namespace.register :xsd, 'http://www.w3.org/2001/XMLSchema#'
  def xsd_type
    case self
    when String
      XSD::string
    when Integer
      XSD::integer
    when TrueClass, FalseClass
      XSD::boolean
    when DateTime, Date, Time
      XSD::date
    end
  end

  def self.typed(value, type)
    case type
    when XSD::string
      String.new(value)
    when XSD::date
      DateTime.parse(value)
    when XSD::boolean
      value == 'true' or value == 1
    when XSD::integer
      value.to_i
    end
  end

  def to_ntriple
    if $activerdf_without_xsdtype
      "\"#{to_s}\""
    else
      "\"#{to_s}\"^^#{xsd_type}"
    end
  end
end

class String; include Literal; end
class Integer; include Literal; end
class DateTime; include Literal; end
class Date; include Literal; end
class Time; include Literal; end
class TrueClass; include Literal; end
class FalseClass; include Literal; end

class LocalizedString < String
  include Literal
  attr_reader :lang
  def initialize value, lang=nil
    super(value)

    @lang = lang
    @lang = lang[1..-1] if @lang[0..0] == '@'
  end

  def to_ntriple
    if @lang
      "\"#{to_s}\"@#@lang"
    else
      super
    end
  end
end
