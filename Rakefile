require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'tools/rakehelp'
require 'rubygems'

#Gem::manage_gems
setup_tests
setup_rdoc ['README', 'LICENSE', 'lib/**/*.rb']

desc 'test and package gem'
task :default => :reinstall

version="0.9.5"
name="activerdf"

setup_gem(name,version) do |spec|
	spec.summary = 'Offers object-oriented access to RDF (with adapters to several datastores).'
	spec.description = spec.summary
	spec.author = 'Eyal Oren'
	spec.email = 'eyal.oren@deri.org'
	spec.homepage = 'http://www.activerdf.org'
	spec.platform = Gem::Platform::RUBY
	spec.require_path = 'lib'
	spec.autorequire = 'active_rdf'
	spec.test_file = 'test/ts_active_rdf.rb'
	spec.add_dependency('gem_plugin', '>= 0.2.1')
end

task :upload => :package do |task|
	sh "scp pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
	sh "scp activerdf-*/pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
end

task :install => [:test, :package] do
  sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{name}}
end

task :reinstall => [:uninstall, :install]
