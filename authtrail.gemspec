
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "auth_trail/version"

Gem::Specification.new do |spec|
  spec.name          = "authtrail"
  spec.version       = AuthTrail::VERSION
  spec.summary       = "Track Devise login activity"
  spec.homepage      = "https://github.com/ankane/authtrail"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@chartkick.com"

  spec.files         = Dir["*.{md,txt}", "{app,lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "railties", ">= 5"
  spec.add_dependency "activerecord", ">= 5"
  spec.add_dependency "warden"
  spec.add_dependency "geocoder"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
