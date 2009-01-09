Gem::Specification.new do |s|
  s.name = "external"
	s.version = "0.3.0"
	s.author = "Simon Chiang"
	s.email = "simon.a.chiang@gmail.com"
	s.homepage = "http://rubyforge.org/projects/external/"
  s.platform = Gem::Platform::RUBY
  s.summary = "array-like access to external data files"
  s.require_path = "lib"
  s.rubyforge_project = "external"
  s.has_rdoc = true
  s.add_development_dependency("tap", ">= 0.12.0")
  s.add_development_dependency("mspec", "~> 1.5")
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    MIT-LICENSE
    README
    History
  }
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
    lib/external.rb
    lib/external/base.rb
    lib/external/chunkable.rb
    lib/external/enumerable.rb
    lib/external/io.rb
    lib/external/patches/ruby_1_8_io.rb
    lib/external/patches/windows_io.rb
    lib/external/patches/windows_utils.rb
    lib/external/utils.rb
    lib/external_archive.rb
    lib/external_array.rb
    lib/external_index.rb
  }
end