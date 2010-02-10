require 'benchmark'
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

  def cbool_accessor *syms
    syms.flatten.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end
        
        class << self
          def #{sym}=(val)
            @@#{sym} = val ? true : false
          end
  
          def #{sym}?
            @@#{sym} ? true : false
          end
        end
        
        def #{sym}=(val)
          self.class.#{sym} = val
        end

        def #{sym}?
          self.class.#{sym}
        end
      EOS
    end
  end
end

# Extends the class object with class and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
class Class # :nodoc:
  def cattr_reader(*syms)
    syms.flatten.each do |sym|
      next if sym.is_a?(Hash)
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}
          @@#{sym}
        end

        def #{sym}
          @@#{sym}
        end
      EOS
    end
  end

  def cattr_writer(*syms) 
    options = syms.extract_options!
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end

        #{"
        def #{sym}=(obj)
          @@#{sym} = obj
        end
        " unless options[:instance_writer] == false }
      EOS
    end
  end

  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end
end

class Array
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end  
end

module ActiveRdfBenchmark
  # Benchmarking for ActiveRecord. You may pass a message with additional
  # information - there's a little hack that the "real" benchmark will pass
  # the message to the block, while the "non-benchmark" call will pass nil.
  # This allows you to build the message in the block only if you need it.
  def benchmark(title, log_level = Logger::DEBUG, message = '')
    if(ActiveRdfLogger.logger.level <= log_level)
      result = nil
      seconds = Benchmark.realtime { result = yield(message) }
      ActiveRdfLogger.log_add("\033[31m\033[1m#{title}\033[0m (#{'%.5f' % seconds}) -- \033[34m#{message}\033[0m", log_level, self)
      result
    else
      yield(nil)
    end
  end

end
