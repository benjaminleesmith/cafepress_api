# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cafepress_api/version"

Gem::Specification.new do |s|
  s.name        = "cafepress_api"
  s.version     = CafepressApi::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Benjamin Lee Smith"]
  s.email       = ["benjamin.lee.smith@gmail.com"]
  s.homepage    = "https://github.com/benjaminleesmith/cafepress_api"
  s.summary     = "A simple Ruby wrapper for the CafePress API."
  s.description = %q{This is a simple Ruby wrapper for the CafePress API. It is a work in progress and does not cover everything in the API.}

  s.rubyforge_project = "cafepress_api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
