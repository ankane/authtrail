require "bundler/setup"
Bundler.require
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
  config.load_defaults Rails::VERSION::STRING.to_f

  if Rails::VERSION::STRING.to_f >= 7.1
    config.action_dispatch.show_exceptions = :none
  end

  config.active_job.queue_adapter = :test

  logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
  config.action_controller.logger = logger
  config.active_record.logger = logger
  config.active_job.logger = logger
end

class Minitest::Test
  def with_options(options)
    previous_options = {}
    options.each_key do |k|
      previous_options[k] = AuthTrail.send(k)
    end
    begin
      options.each do |k, v|
        AuthTrail.send("#{k}=", v)
      end
      yield
    ensure
      previous_options.each do |k, v|
        AuthTrail.send("#{k}=", v)
      end
    end
  end
end
