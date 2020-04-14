# dependencies
require "geocoder"
require "warden"

# modules
require "auth_trail/engine"
require "auth_trail/manager"
require "auth_trail/version"

module AuthTrail
  class << self
    attr_accessor :exclude_method, :geocode, :track_method, :identity_method
  end
  self.geocode = true
  self.identity_method = lambda do |request, opts, user|
    if user
      user.try(:email)
    else
      scope = opts[:scope]
      request.params[scope] && request.params[scope][:email] rescue nil
    end
  end

  def self.track(strategy:, scope:, identity: nil, success:, request:, user: nil, failure_reason: nil, activity_type:)
    info = {
      activity_type: activity_type,
      strategy: strategy,
      scope: scope,
      identity: identity,
      success: success,
      failure_reason: failure_reason,
      user: user,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      referrer: request.referrer
    }

    if request.params[:controller]
      info[:context] = "#{request.params[:controller]}##{request.params[:action]}"
    end

    # if exclude_method throws an exception, default to not excluding
    exclude = AuthTrail.exclude_method && AuthTrail.safely(default: false) { AuthTrail.exclude_method.call(info) }

    unless exclude
      if AuthTrail.track_method
        AuthTrail.track_method.call(info)
      else
        login_activity = LoginActivity.create!(info)
        AuthTrail::GeocodeJob.perform_later(login_activity) if AuthTrail.geocode
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
