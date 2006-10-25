# defining ActiveRDF errors
class ActiveRdfError < StandardError
end

# adding bool_accessor to ruby
class Module
  def bool_accessor *syms
    attr_accessor(*syms)
    syms.each { |sym| alias_method "#{sym}?", sym }
    remove_method(*syms)
  end
end
