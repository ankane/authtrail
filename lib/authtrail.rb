# dependencies
require "warden"

# modules
require_relative "auth_trail/manager"
require_relative "auth_trail/version"

module AuthTrail
  autoload :GeocodeJob, "auth_trail/geocode_job"

  class << self
    attr_accessor :exclude_method, :geocode, :track_method, :identity_method, :job_queue, :transform_method
  end
  self.geocode = false
  self.identity_method = lambda do |request, opts, user|
    if user
      user.try(:email)
    else
      scope = opts[:scope]
      request.params[scope] && request.params[scope][:email] rescue nil
    end
  end

  def self.track(strategy:, scope:, identity:, success:, request:, user: nil, failure_reason: nil)
    data = {
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
      data[:context] = "#{request.params[:controller]}##{request.params[:action]}"
    end

    # add request data before exclude_method since exclude_method doesn't have access to request
    # could also add 2nd argument to exclude_method when arity > 1
    AuthTrail.transform_method.call(data, request) if AuthTrail.transform_method

    # if exclude_method throws an exception, default to not excluding
    exclude = AuthTrail.exclude_method && AuthTrail.safely(default: false) { AuthTrail.exclude_method.call(data) }

    unless exclude
      if AuthTrail.track_method
        AuthTrail.track_method.call(data)
      else
        login_activity = LoginActivity.new
        data.each do |k, v|
          login_activity.try("#{k}=", v)
        end
        login_activity.save!
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
