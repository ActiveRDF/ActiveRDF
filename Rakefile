require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'tools/rakehelp'
require 'rubygems'
require 'fileutils'
include FileUtils

# setup tests and rdoc files
setup_tests
setup_clean ["pkg", "lib/*.bundle", "*.gem", ".config"]
setup_rdoc ['README', 'LICENSE', 'lib/**/*.rb']

# default task: install
desc 'test and package gem'
task :default => :install

# get ActiveRdfVersion from commandline
ActiveRdfVersion = ENV['REL'] || '1.0'
NAME="activerdf"
GEMNAME="#{NAME}-#{ActiveRdfVersion}.gem"

# define package task
setup_gem(NAME,ActiveRdfVersion) do |spec|
  spec.summary = 'Offers object-oriented access to RDF (with adapters to several datastores).'
  spec.description = spec.summary
  spec.author = 'Eyal Oren'
  spec.email = 'eyal.oren@deri.org'
  spec.homepage = 'http://www.activerdf.org'
  spec.platform = Gem::Platform::RUBY
  spec.autorequire = 'active_rdf'
  spec.add_dependency('gem_plugin', '>= 0.2.1')
end

# define upload task
task :upload => :package do |task|
  sh "scp pkg/#{GEMNAME} eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
  #sh "scp activerdf-*/pkg/*.gem eyal@m3pe.org:/home/eyal/webs/activerdf/gems/"
end

task :install => [:package] do
  sh "sudo gem install pkg/#{GEMNAME}"
end

task :uninstall => [:clean] do
  sh "sudo gem uninstall #{NAME}"
end

task :reinstall => [:uninstall, :install]

# define task rcov
begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList["activerdf-*/test/**/*.rb"]
    t.verbose = true
    # t.rcov_opts << "--test-unit-only "
  end
rescue LoadError
  # rcov not installed
end

# define test_all task
Rake::TestTask.new do |t|
  t.name = :test_all
  t.test_files = FileList["test/**/*.rb", "activerdf-*/test/**/*.rb"]
end
