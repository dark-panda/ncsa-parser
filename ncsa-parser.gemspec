# -*- encoding: utf-8 -*-

require File.expand_path('../lib/ncsa-parser/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "ncsa-parser"
  s.version = NCSAParser::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "A simple NCSA-style log file parser."
  s.summary = s.description
  s.email = "dark.panda@gmail.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/dark-panda/ncsa-parser"
  s.require_paths = ["lib"]

  s.add_development_dependency("rdoc")
  s.add_development_dependency("rake", ["~> 0.9"])
  s.add_development_dependency("minitest")
  s.add_development_dependency("turn")
end
