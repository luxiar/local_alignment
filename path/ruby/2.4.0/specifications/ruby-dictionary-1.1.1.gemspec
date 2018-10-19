# -*- encoding: utf-8 -*-
# stub: ruby-dictionary 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-dictionary".freeze
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matt Huggins".freeze]
  s.date = "2014-08-14"
  s.description = "Dictionary class for ruby that allows for checking\n                         existence and finding words starting with a given\n                         prefix.".freeze
  s.email = ["matt.huggins@gmail.com".freeze]
  s.homepage = "https://github.com/mhuggins/ruby-dictionary".freeze
  s.rubygems_version = "2.6.14.1".freeze
  s.summary = "Simple dictionary class for checking existence of words".freeze

  s.installed_by_version = "2.6.14.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
