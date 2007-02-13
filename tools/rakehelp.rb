def setup_tests
  Rake::TestTask.new do |t|
    t.test_files = FileList['test/**/*.rb']
  end
end

def setup_clean otherfiles
  files = ['build/*', '**/*.o', '**/*.so', '**/*.a', 'lib/*-*', '**/*.log'] + otherfiles
  CLEAN.include(files)
end

def setup_rdoc files
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'doc/rdoc'
    rdoc.options << '--line-numbers'
    rdoc.rdoc_files.add(files)
  end
end

def base_gem_spec(pkg_name, pkg_version)
	pkg_version = pkg_version
	pkg_name    = pkg_name
	pkg_file_name = "#{pkg_name}-#{pkg_version}"
	Gem::Specification.new do |s|
		s.name = pkg_name
		s.version = pkg_version
		s.platform = Gem::Platform::RUBY
		s.has_rdoc = true
		s.extra_rdoc_files = [ "README" ]

		s.files = %w(LICENSE README CHANGELOG) +
		Dir.glob("{bin,doc/rdoc,test,lib}/**/*") +
		Dir.glob("examples/**/*.rb")

		s.require_path = "lib"
		s.extensions = FileList["ext/**/extconf.rb"].to_a
		s.bindir = "bin"
	end
end

def setup_gem(pkg_name, pkg_version)
	spec = base_gem_spec(pkg_name, pkg_version)
	yield spec if block_given?

	Rake::GemPackageTask.new(spec) do |p|
		p.gem_spec = spec
		p.need_tar = false
	end
end
