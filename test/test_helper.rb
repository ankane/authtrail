require "bundler/setup"
Bundler.require(:development)
require "minitest/autorun"
require "minitest/pride"
require "devise"

Devise.setup do |config|
  require "devise/orm/active_record"

  config.warden do |manager|
    manager.failure_app = ->(env) { [401, {"Content-Type" => "text/html"}, "Unauthorized"] }
  end

  config.mailer_sender = "sender@example.org"

  config.maximum_attempts = 2

  config.reconfirmable = false
end

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller, :action_mailer do
  if ActiveRecord::VERSION::MAJOR < 6 && config.active_record.sqlite3.respond_to?(:represent_boolean_as_integer)
    config.active_record.sqlite3.represent_boolean_as_integer = true
  end
end

ActionMailer::Base.delivery_method = :test

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT) if ENV["VERBOSE"]

AuthTrail.geocode = false

AuthTrail.exclude_method = lambda do |info|
  info[:identity] == "exclude@example.org"
end
