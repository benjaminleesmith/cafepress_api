# Copyright 2011 Benjamin Lee Smith <benjamin.lee.smith@gmail.com>
#
# This file is part of CafePressAPI.
# CafePressAPI is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CafePressAPI is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CafePressAPI.  If not, see <http://www.gnu.org/licenses/>.

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cafepress_api/version"

Gem::Specification.new do |s|
  s.name        = "cafepress_api"
  s.version     = CafePressAPI::VERSION
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
