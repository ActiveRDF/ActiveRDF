require 'benchmark'
# Default ActiveRDF error
module ActiveRDF
  class ActiveRdfError < StandardError; end
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

# extract boolean from value
def truefalse(val, default = nil)
  raise ArgumentError, "truefalse: default must be a boolean: #{default}" if !default.nil? and !(default == true || default == false)
  case val
  when true,/^(yes|y|true)$/i then true
  when false,/^(no|n|false)$/i then false
  else default
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
