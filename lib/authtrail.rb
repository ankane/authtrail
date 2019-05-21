# dependencies
require "geocoder"
require "warden"

# modules
require "auth_trail/engine"
require "auth_trail/manager"
require "auth_trail/version"

module AuthTrail
  class << self
    attr_accessor :exclude_method, :geocode, :track_method, :identity_method, :login_activity_attributes_method
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
  self.login_activity_attributes_method = lambda do |strategy, scope, identity, success, request, user, failure_reason|
    {
        strategy:       strategy,
        scope:          scope,
        identity:       identity,
        success:        success,
        failure_reason: failure_reason,
        user:           user,
        ip:             request.remote_ip,
        user_agent:     request.user_agent,
        referrer:       request.referrer
    }
  end

  def self.track(strategy:, scope:, identity:, success:, request:, user: nil, failure_reason: nil)
    login_activity_attributes = AuthTrail.login_activity_attributes_method.call(strategy, scope, identity, success, request, user, failure_reason)

    if request.params[:controller]
      login_activity_attributes[:context] = "#{request.params[:controller]}##{request.params[:action]}"
    end

    # if exclude_method throws an exception, default to not excluding
    exclude = AuthTrail.exclude_method && AuthTrail.safely(default: false) { AuthTrail.exclude_method.call(login_activity_attributes) }

    unless exclude
      if AuthTrail.track_method
        AuthTrail.track_method.call(login_activity_attributes)
      else
        login_activity = LoginActivity.create!(login_activity_attributes)
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
  AuthTrail::Manager.before_failure(env, opts)
end
