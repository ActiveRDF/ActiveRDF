# Default ActiveRDF error
class ActiveRdfError < StandardError
end

class Module
	# Adds boolean accessor to a class (e.g. person.male?)
  def bool_accessor *syms
    attr_accessor(*syms)
    syms.each { |sym| alias_method "#{sym}?", sym }
    remove_method(*syms)
  end
end
