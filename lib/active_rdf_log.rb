require 'logger'

# use either $ACTIVE_RDF_LOG for logging or current directory
location = ENV['ACTIVE_RDF_LOG'] || $stdout # "#{Dir.pwd}/activerdf.log"
location = $stdout if location == "STDOUT"
$activerdflog = Logger.new(location, 1, 100*1024)
    
# if user has specified loglevel we use that, otherwise we use default level
# in the environment variable ACTIVE_RDF_LOG_LEVEL we expect numbers, which we 
# have to convert
if ENV['ACTIVE_RDF_LOG_LEVEL'].nil?
  $activerdflog.level = Logger::WARN
else
  $activerdflog.level = ENV['ACTIVE_RDF_LOG_LEVEL'].to_i
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
