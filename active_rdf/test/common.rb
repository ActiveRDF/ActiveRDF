require 'active_rdf'

$adapters = [:redland]
$yars_host = 'browserdf.org'
$yars_context = 'test'

$run_tests = ['resource', 'literal']

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
  require 'adapter/yars/yars_adapter'
  yars = YarsAdapter.new :host => $yars_host, :context => $yars_context
  ##yars.yars.set_debug_output STDOUT
  # remove all triples from yars repository
  yars.remove(nil,nil,nil)
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
  if $adapters.include?(:yars)
    delete_yars
  # other adapters run in memory
  end
  NodeFactory.clear
end