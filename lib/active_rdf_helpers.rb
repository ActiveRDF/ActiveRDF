require 'benchmark'
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
