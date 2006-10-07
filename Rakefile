require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
	s.name = 'activerdf'
	s.version = '0.3.0'
	s.author = 'Eyal Oren'
	s.email = 'eyal.oren@deri.org'
	s.homepage = 'http://activerdf.org'
	s.platform = Gem::Platform::RUBY
	s.summary = 'Object-oriented access to RDF'
	candidates = FileList["{lib,test}/**/*"].exclude("rdoc").to_a
	s.require_path = 'lib'
	s.autorequire = 'active_rdf'
	s.test_file = 'test/ts_active_rdf.rb'
	s.has_rdoc = true
	s.extra_rdoc_files = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_tar = true
end
