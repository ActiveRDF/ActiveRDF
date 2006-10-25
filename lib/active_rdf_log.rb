require 'logger'

$log =
  begin
    # us the rails logger if running under rails
    RAILS_DEFAULT_LOGGER 
  rescue NameError
    unless ENV['ACTIVE_RDF_LOG'].nil?
      # write to environment variable $RDF_LOG if set
      Logger.new(ENV['ACTIVE_RDF_LOG'], 1, 100*1024) 
    else
      require 'tmpdir'
      # else just write to the temp dir
      Logger.new(Dir.tmpdir.to_s + "/activerdf.log", 1, 100*1024); 
    end
  end
    
# if user has specified loglevel we use that, otherwise we use default level
# in the environment variable ACTIVE_RDF_LOG_LEVEL we expect numbers, which we 
# have to convert
if ENV['ACTIVE_RDF_LOG_LEVEL'].nil?
  $log.level = Logger::WARN
else
  $log.level = ENV['ACTIVE_RDF_LOG_LEVEL'].to_i
end
