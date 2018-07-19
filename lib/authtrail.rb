# dependencies
require "active_support"
require "geocoder"
require "warden"

# modules
require "auth_trail/controller"
require "auth_trail/engine"
require "auth_trail/manager"
require "auth_trail/model"
require "auth_trail/version"

# devise
if defined?(Devise)
  require "devise/models/trailable"
end

module AuthTrail
  class << self
    attr_accessor :exclude_method, :geocode, :track_method
  end
  self.geocode = true

  def self.track(activity_type:, success: true, strategy: nil, scope: nil, identity: nil, request: nil, user: nil, failure_reason: nil)
    request ||= RequestStore.store[:authtrail_request]

    info = {
      activity_type: activity_type,
      strategy: strategy,
      scope: scope,
      identity: identity,
      success: success,
      failure_reason: failure_reason,
      user: user
    }

    if request
      info[:context] = "#{request.params[:controller]}##{request.params[:action]}"
      info[:ip] = request.remote_ip
      info[:user_agent] = request.user_agent
      info[:referrer] = request.referrer
    end

    # if exclude_method throws an exception, default to not excluding
    exclude = AuthTrail.exclude_method && AuthTrail.safely(default: false) { AuthTrail.exclude_method.call(info) }

    unless exclude
      if AuthTrail.track_method
        AuthTrail.track_method.call(info)
      else
        login_activity = AccountActivity.create!(info)
        AuthTrail::GeocodeJob.perform_later(login_activity) if request && AuthTrail.geocode
      end
    end
  end

  def self.safely(default: nil)
    begin
      yield
    rescue => e
      warn "[authtrail] #{e.class.name}: #{e.message}"
      default
    end
  end
end

Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  AuthTrail::Manager.after_set_user(user, auth, opts)
end

Warden::Manager.before_failure do |env, opts|
  AuthTrail::Manager.before_failure(env, opts) if opts[:message]
end

Warden::Manager.before_logout do |user, auth, opts|
  AuthTrail::Manager.before_logout(user, auth, opts) if user
end

ActiveSupport.on_load(:action_controller) do
  include AuthTrail::Controller
end
