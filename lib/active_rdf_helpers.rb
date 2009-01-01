# Default ActiveRDF error
class ActiveRdfError < StandardError
end

class Module
  # Adds boolean accessor to a class (e.g. person.male?)
  def bool_accessor *syms
    syms.flatten.each do |sym|
      next unless sym.is_a?(Symbol)
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @#{sym}
          @#{sym} = nil
        end
        
        def #{sym}=(val)
          @#{sym} = val ? true : false
        end

        def #{sym}?
          @#{sym} ? true : false
        end
      EOS
    end
  end
end

class Array
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end  
end
