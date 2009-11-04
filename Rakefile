require 'rubygems'

require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/rdoctask'
require 'tools/rakehelp'
require 'fileutils'
include FileUtils

$version  = IO.read('VERSION').strip
$name     = 'activerdf'
$distdir  = "#$name-#$version"

# setup tests and rdoc files
setup_tests
setup_clean ["pkg", "lib/*.bundle", "*.gem", ".config"]

Rake::RDocTask.new do |rdoc|
	files = ['README', 'LICENSE', 'lib/**/*.rb', 'doc/**/*.rdoc', 'test/*.rb']
	files << 'activerdf-*/lib/**/*.rb'
	rdoc.rdoc_files.add(files)
	rdoc.main = "README"
	rdoc.title = "ActiveRDF documentation"
	rdoc.template = "tools/allison/allison.rb"
	rdoc.rdoc_dir = 'doc'
	rdoc.options << '--line-numbers' << '--inline-source'
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'activerdf_net7'
    s.summary = 'Offers object-oriented access to RDF (with adapters to several datastores). Version of the Talia project.'
    s.description = s.summary + ' THIS IS NOT THE OFFICIAL VERSION.'
    s.authors = ['Eyal Oren', 'The Talia Team']
    s.email = 'hahn@netseven.it'
    s.homepage = 'http://www.activerdf.org'
    s.platform = Gem::Platform::RUBY
    s.autorequire = 'active_rdf'
    s.add_dependency('gem_plugin', '>= 0.2.1')
    s.files = FileList["{lib}/**/*", "{activerdf}*/**/*"]
    s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "LICENSE"]
    s.add_dependency('grit', '>= 1.1.1')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dendency) is not available. Install with: gem install jeweler"
end

begin
  require 'gokdok'
  Gokdok::Dokker.new do |gd|
    gd.remote_path = '' # Put into the root directory
  end
rescue LoadError
  puts "Gokdok is not available. Install with: gem install gokdok"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList["activerdf-*/test/**/*.rb"]
    t.verbose = true
  end
rescue LoadError
  puts 'Rcov or dependency is not available'
end

# define test_all task
Rake::TestTask.new do |t|
  t.name = :test_all
  t.test_files = FileList["test/**/*.rb", "activerdf-*/test/**/*.rb"]
end
