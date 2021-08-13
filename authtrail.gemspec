require_relative "lib/auth_trail/version"

Gem::Specification.new do |spec|
  spec.name          = "authtrail"
  spec.version       = AuthTrail::VERSION
  spec.summary       = "Track Devise login activity"
  spec.homepage      = "https://github.com/ankane/authtrail"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{app,lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "railties", ">= 5.2"
  spec.add_dependency "activerecord", ">= 5.2"
  spec.add_dependency "warden"
end
