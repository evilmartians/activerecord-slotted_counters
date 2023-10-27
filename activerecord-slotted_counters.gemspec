# frozen_string_literal: true

require_relative "lib/activerecord_slotted_counters/version"

Gem::Specification.new do |s|
  s.name = "activerecord-slotted_counters"
  s.version = ActiveRecordSlottedCounters::VERSION
  s.authors = ["Egor Lukin", "Vladimir Dementyev"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/evilmartians/activerecord-slotted_counters"
  s.summary = "Active Record slotted counters support"
  s.description = "Active Record slotted counters support"

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/evilmartians/activerecord-slotted_counters/issues",
    "changelog_uri" => "https://github.com/evilmartians/activerecord-slotted_counters/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/evilmartians/activerecord-slotted_counters",
    "homepage_uri" => "http://github.com/evilmartians/activerecord-slotted_counters",
    "source_code_uri" => "http://github.com/evilmartians/activerecord-slotted_counters"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.7"

  s.add_dependency "activerecord", ">= 6.1"

  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.9"
  s.add_development_dependency "rspec-sqlimit"
end
