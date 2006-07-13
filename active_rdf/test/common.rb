require 'active_rdf'
require 'tmpdir'
require 'fileutils'
	
$adapters = [:sesame,:sparql,:redland]
$yars_host = 'browserdf.org'
$yars_port = 8080
$yars_context = 'test'
$temp_location = "#{Dir.tmpdir}/test"
$log_level = Logger::INFO

$sesame_location = 'temp.rdf'

# setup data with various adapters
def setup_any(location = nil)
  if $adapters.include?(:redland)
    setup_redland(location || :memory)
  elsif $adapters.include?(:yars)
    setup_yars
  elsif $adapters.include?(:sesame)
    setup_sesame(location || $sesame_location)
  else
    raise StandardError, 'no suitable adapter found for test'
  end
end

def setup_redland(location = :memory)
  NodeFactory.connection :adapter => :redland, :location => location, :cache_server => :memory, :construct_class_model => false, :log_level => $log_level
end

def setup_yars
  NodeFactory.connection :adapter => :yars, :host => $yars_host, :context => $yars_context, :cache_server => :memory, :construct_class_model => false, :log_level => $log_level
end

def setup_sesame(location = $sesame_location)
  NodeFactory.connection :adapter => :sesame, :location => location
end

# delete data with various adapters
def delete_any(location = nil)
  case NodeFactory.connection.adapter_type
  when :sesame
    location ||= $sesame_location
    delete_sesame(location)
  when :yars
    delete_yars
  when :redland
	  # only delete if redland does not run in memory
  	delete_redland(location) unless location.nil? 
	end
  NodeFactory.clear
end

def delete_sesame(location = $sesame_location)
  FileUtils.rm location
end

def delete_redland(location = :memory)
  FileUtils.rm Dir.glob(location + '-*.db')
end

def delete_yars
  # TODO: fix to work without java API
  require 'adapter/yars/yars_adapter'
  `java -jar #{File.dirname(__FILE__)}/adapter/yars/yars-api-current.jar -d -u http://#$yars_host:#$yars_port/#$yars_context #{File.dirname(__FILE__)}/delete_all.nt`
  #  yars = YarsAdapter.new :host => $yars_host, :context => $yars_context
  #  yars.remove(nil,nil,nil)
end

# load test dataset with various adapters
def load_test_data
  case NodeFactory.connection.adapter_type
  when :yars
    `java -jar #{File.dirname(__FILE__)}/adapter/yars/yars-api-current.jar -p -u http://#$yars_host:#$yars_port/#$yars_context #{File.dirname(__FILE__)}/test_set_person.nt`    
  when :redland
    parser = Redland::Parser.new
    model = NodeFactory.connection.model
    dataset = File.read "#{File.dirname(__FILE__)}/test_set_person.rdf"
    parser.parse_string_into_model(model,dataset,'uri://test-set-activerdf/')
  when :sesame
    dataset = SesameAdapter::Sesame::File.new("#{File.dirname(__FILE__)}/test_set_person.rdf")
    NodeFactory.connection.repository.add(dataset, 'uri://test-set-activerdf/', SesameAdapter::Sesame::RDFFormat.RDFXML)
    true
  end
end

