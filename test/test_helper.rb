require "bundler/setup"
Bundler.require(:development)
require "minitest/autorun"
require "minitest/pride"

Devise.setup do |config|
  require "devise/orm/active_record"

  config.warden do |manager|
    manager.failure_app = ->(env) { [401, {"Content-Type" => "text/html"}, "Unauthorized"] }
  end
end

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller, :active_job do
  if ActiveRecord::VERSION::MAJOR < 6 && config.active_record.sqlite3.respond_to?(:represent_boolean_as_integer)
    config.active_record.sqlite3.represent_boolean_as_integer = true
  end

  config.active_job.queue_adapter = :test
end

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT) if ENV["VERBOSE"]

AuthTrail.exclude_method = lambda do |info|
  info[:identity] == "exclude@example.org"
end
