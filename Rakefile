#require 'meta_project'
require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
#require 'rake/contrib/xforge'
require 'tools/rakehelp'
require 'rubygems'
require 'fileutils'
include FileUtils

$version  = IO.read('VERSION').strip
$name     = 'activerdf'
#$project  = MetaProject::Project::XForge::RubyForge.new('activerdf')
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

# default task: install
desc 'test and package gem'
task :default => :install

# GEMNAME="#{NAME}-#{ActiveRdfVersion}.gem"

# define package task
setup_gem("activerdf",$version) do |spec|
  spec.summary = 'Offers object-oriented access to RDF (with adapters to several datastores).'
  spec.description = spec.summary
  spec.author = 'Eyal Oren'
  spec.email = 'eyal.oren@deri.org'
  spec.homepage = 'http://www.activerdf.org'
  spec.platform = Gem::Platform::RUBY
  spec.autorequire = 'active_rdf'
  spec.add_dependency('gem_plugin', '>= 0.2.1')
#  spec.add_dependency('activerdf_sparql')
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
end

# define test_all task
Rake::TestTask.new do |t|
  t.name = :test_all
  t.test_files = FileList.new("test/**/*.rb", "activerdf-*/test/**/*.rb") do |fl|
    fl.exclude(/jena|sesame|sparql/i)
  end
end

task :verify_rubyforge do
  raise "RUBYFORGE_USER environment variable not set!" unless ENV['RUBYFORGE_USER']
  raise "RUBYFORGE_PASSWORD environment variable not set!" unless ENV['RUBYFORGE_PASSWORD']
end

desc "release #$name-#$version gem on RubyForge"
task :release => [ :clean, :verify_rubyforge, :package ] do
  release_files = FileList["pkg/#$distdir.gem"]
  Rake::XForge::Release.new($project) do |release|
    release.user_name     = ENV['RUBYFORGE_USER']
    release.password      = ENV['RUBYFORGE_PASSWORD']
    release.files         = release_files.to_a
    release.release_name  = "#$name #$version"
    release.package_name  = "activerdf"
    release.release_notes = ""

    changes = []
    File.open("CHANGELOG") do |file|
      current = true

      file.each do |line|
        line.chomp!
				if current and line =~ /^==/
					current = false; next
				end
        break if line.empty? and not current
        changes << line
      end
    end
    release.release_changes = changes.join("\n")
  end
end

desc "release gem on RubyForge and build documentation"
task :release_docs => [ :release, :rdoc ]
