require 'logger'


class ActiveRdfLogger

  # Create log methods for each level
  %w(debug info warn error fatal).each do |level|
    module_eval <<-"end_eval"
          def self.log_#{level}(message_or_context, context = nil)
            message_or_context, context = nil, message_or_context if(block_given?)
            log_add(message_or_context, Logger::#{level.upcase}, context) do
              yield if(block_given?)
            end
          end
    end_eval
  end

  class << self

    # Get the logger for the ActiveRDF library. This will default to the Rails
    # logger if that is active. Otherwise it will use the configured logger
    # for ActiveRDF. (Note that some messages may go to the configured logger
    # if ActiveRDF is initialized before Rails).
    def logger
      @logger ||= get_active_rdf_logger
    end

    # Assign a new logger
    def logger=(logger)
      @logger = logger
      @native_logger = false
    end

    # Logs a message of the given severity. The context may identify the class/
    # object that logged the message
    def log_add(message = nil, severity = Logger::DEBUG, context = nil)
      logger.add(severity, nil, "ActiveRDF") do
        message = yield if(!message && block_given?)
        log_message(message, context)
      end
    end

    private

    def log_message(message, context = nil)
      message = ("\033[32m\033[4m\033[1m#{context_string(context)}\033[0m ") << message if(context)
      return message if(@native_logger)
      "\033[35m\033[4m\033[1mActiveRDF\033[0m " << message
    end

    def context_string(context)
      return context if(context.is_a?(String))
      context = context.class unless(context.is_a?(Class))
      context.name
    end

    def get_active_rdf_logger
      if(defined?(RAILS_DEFAULT_LOGGER) && RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      else
        @native_logger = true

        # use either $ACTIVE_RDF_LOG for logging or current directory
        location = ENV['ACTIVE_RDF_LOG'] || $stdout # "#{Dir.pwd}/activerdf.log"
        location = $stdout if(location == "STDOUT")
        logger = Logger.new(location, 1, 100*1024)

        # if user has specified loglevel we use that, otherwise we use default level
        # in the environment variable ACTIVE_RDF_LOG_LEVEL we expect numbers, which we
        # have to convert
        if ENV['ACTIVE_RDF_LOG_LEVEL'].nil?
                  logger.level = Logger::WARN
        else
                  logger.level = ENV['ACTIVE_RDF_LOG_LEVEL'].to_i
        end

        logger
      end
    end
    
  end
end

class Logger
  def debug_pp(message, variable)
    if variable.respond_to?(:join)
      if variable.empty?
        debug(sprintf(message, "empty"))
      else
        debug(sprintf(message, variable.join(', ')))
      end
    else
      if variable.nil?
        debug(sprintf(message, 'empty'))
      else
        debug(sprintf(message, variable))
      end
    end
  end
end
