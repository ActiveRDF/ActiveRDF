require 'active_rdf'

$adapters = [:yars,:redland]
$yars_host = 'browserdf.org'
$yars_port = 8080
$yars_context = 'test'

#$run_tests = ['resource', 'literal']

def setup_redland(location = :memory)
	NodeFactory.connection :adapter => :redland, :location => location, :cache_server => :memory, :construct_class_model => false
end

def delete_redland(location = :memory)
  # TODO
end

def setup_yars
  NodeFactory.connection :adapter => :yars, :host => $yars_host, :context => $yars_context, :cache_server => :memory, :construct_class_model => false
end

def delete_yars
  # TODO: fix to work without java API
  require 'adapter/yars/yars_adapter'
  `java -jar #{File.dirname(__FILE__)}/adapter/yars/yars-api-current.jar -d -u http://#$yars_host:#$yars_port/#$yars_context #{File.dirname(__FILE__)}/delete_all.nt`
#  yars = YarsAdapter.new :host => $yars_host, :context => $yars_context
#  yars.remove(nil,nil,nil)
end

def setup_any(location = :memory)
  if $adapters.include?(:redland)
     setup_redland(location)
  elsif $adapters.include?(:yars)
     setup_yars
  else
     raise StandardError, 'no suitable adapter found for test'
  end
end

def delete_any   
  if NodeFactory.connection.class.name == 'YarsAdapter'
    delete_yars
  # other adapters run in memory
  end
  NodeFactory.clear
end

def load_test_data
  case NodeFactory.connection.adapter_type
  when :yars
    `java -jar #{File.dirname(__FILE__)}/adapter/yars/yars-api-current.jar -p -u http://#$yars_host:#$yars_port/#$yars_context #{File.dirname(__FILE__)}/test_set_person.nt`    
  when :redland
    parser = Redland::Parser.new
    model = NodeFactory.connection.model
    dataset = File.read "#{File.dirname(__FILE__)}/test_set_person.rdf"
    parser.parse_string_into_model(model,dataset,'uri://test-set-activerdf/')
  end
end