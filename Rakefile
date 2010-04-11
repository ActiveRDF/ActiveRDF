require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

require 'tools/rakehelp'

$version  = IO.read('VERSION').strip
$name     = 'activerdf'
$distdir  = "#$name-#$version"

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
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'activerdf'
    gemspec.summary = 'Offers object-oriented access to RDF (with adapters to several datastores).' 
    gemspec.description = gemspec.summary 
    gemspec.authors = ['Michael Diamond', 'Eyal Oren', 'The Talia Team']
    gemspec.email = 'michael@thinknasium.org'
    gemspec.homepage = 'http://www.activerdf.org'
    gemspec.platform = Gem::Platform::RUBY
    gemspec.autorequire = 'active_rdf'
    gemspec.files = FileList["lib/**/*", "activerdf-*/**/*"]
    gemspec.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "LICENSE"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dendency) is not available. Install with: gem install jeweler"
end

begin
  require 'gokdok'
  Gokdok::Dokker.new do |gd|
    gd.remote_path = '' # Put into the root directory
    gd.doc_home = 'doc'
  end
rescue LoadError
  puts "Gokdok is not available. Install with: gem install gokdok"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = FileList.new("test/**/*.rb", "activerdf-*/test/**/*.rb") do |fl|
      fl.exclude(/jena|sesame|sparql/i)
    end
    t.verbose = true
  end
rescue LoadError
  puts 'Rcov or dependency is not available'
end

# define test_all task
Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs.concat FileList.new("activerdf-*/lib")
  t.test_files = FileList.new("test/**/*.rb", "activerdf-*/test/**/*.rb")
#  t.test_files.exclude(/jena|sesame|sparql/i)
end