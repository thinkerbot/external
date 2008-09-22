Gem::Specification.new do |s|
  s.name = "external"
	s.version = "0.1.7"
	s.author = "Simon Chiang"
	s.email = "simon.a.chiang@gmail.com"
	s.homepage = "http://rubyforge.org/projects/external/"
  s.platform = Gem::Platform::RUBY
  s.summary = "array-like access to external data files"
  s.require_path = "lib"
  s.test_file = "test/tap_test_suite.rb"
  s.rubyforge_project = "external"
  s.has_rdoc = true
  s.add_development_dependency("tap", "~> 0.10.7")
  s.add_development_dependency("mspec", "~> 1.5.0")
  
  # list extra rdoc files here.
  s.extra_rdoc_files = %W{
    README
  }
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
    test/tap_test_helper.rb
    test/tap_test_suite.rb
  }
end