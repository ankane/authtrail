require "bundler/setup"
Bundler.require(:development)
require "minitest/autorun"
require "minitest/pride"
require "warden"

class PasswordStrategy < Warden::Strategies::Base
  def authenticate!
    u = User.find_by(email: params.dig("user", "email"))

    if u.nil? || params.dig('user', 'password') != 'sEcReT'
      fail!("Could not sign in")
    else
      success!(u)
    end

  end
end

Warden::Strategies.add(:password, PasswordStrategy)

Combustion.path = "test/internal"
Combustion.initialize! :all do
  if ActiveRecord::VERSION::MAJOR < 6 && config.active_record.sqlite3.respond_to?(:represent_boolean_as_integer)
    config.active_record.sqlite3.represent_boolean_as_integer = true
  end

  config.middleware.use Warden::Manager do |manager|
    manager.default_strategies :password
    manager.failure_app = ->(env) { [401, {"Content-Type" => "text/html"}, "Unauthorized"] }
  end
end

AuthTrail.geocode = false
