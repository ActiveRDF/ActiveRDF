require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

Gem::manage_gems

spec = Gem::Specification.new do |s|
	s.name = 'activerdf'
	s.version = '0.9.2'
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
	s.add_dependency('gem_plugin', '>= 0.2.1')
end

Rake::GemPackageTask.new(spec) do |pkg|
end

Rake::RDocTask.new do |rd|
	rd.main = "README"
	rd.rdoc_dir = "doc"
	rd.title = "ActiveRDF RDoc documentation"
	rd.rdoc_files.include("README", "lib/**/*.rb")
end

task :default => [:upload]

task :upload => :package do |task|
	sh "scp pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
end
