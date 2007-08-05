# -*- ruby -*- 
require 'rake'

Gem::Specification.new do |spec|
  
  spec.name = 'activerdf_jena'
  spec.version = '0.1'
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'The adapter for ActiveRDF to support the Jena RDF store'

  spec.add_dependency 'activerdf'
  spec.add_dependency 'gem_plugin', '>= 0.1'

  spec.autorequire = 'init.rb'

  spec.files = FileList['lib/**/*.rb', 'ext/**/*.jar', 'README', 'LICENSE'].to_a

end
