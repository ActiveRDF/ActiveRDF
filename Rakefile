require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
	s.name = 'activerdf'
	s.version = '0.9.1'
	s.author = 'Eyal Oren'
	s.email = 'eyal.oren@deri.org'
	s.homepage = 'http://activerdf.org'
	s.platform = Gem::Platform::RUBY
	s.summary = 'Offers object-oriented access to RDF (with adapters to several datastores).'
	s.files = Dir['lib/**/*.rb']
	s.require_path = 'lib'
	s.autorequire = 'active_rdf'
	s.test_file = 'test/ts_active_rdf.rb'
	s.has_rdoc = true
	s.extra_rdoc_files = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
end

task :upload => :package do
	sh "scp pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
end

