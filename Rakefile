require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'tools/rakehelp'
require 'rubygems'
require 'fileutils'
include FileUtils

#Gem::manage_gems
setup_tests
setup_clean ["pkg", "lib/*.bundle", "*.gem", ".config"]
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
	spec.autorequire = 'active_rdf'
	spec.add_dependency('gem_plugin', '>= 0.2.1')
end

task :upload => :package do |task|
	sh "scp pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
	sh "scp activerdf-*/pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{name}}
end

task :reinstall => [:uninstall, :install]

# rake task for rcov code coverage, 
# execute with "rake rcov"
require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  # t.test_files = FileList["test/**/*.rb", "activerdf-*/test/**/*.rb"]
  t.test_files = FileList["activerdf-*/test/**/*.rb"]
  t.verbose = true     # uncomment to see the executed command
  # t.rcov_opts << "--test-unit-only "
end

# modify the standard test task to run test from all adapters and from the active_rdf top level 
#Rake::TestTask.new do |t|
#    # t.libs << "test"
#    t.test_files = FileList["test/**/*.rb", "activerdf-*/test/**/*.rb"]
#    t.verbose = true
#end
