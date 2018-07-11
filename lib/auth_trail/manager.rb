module AuthTrail
  module Manager
    class << self
      def after_set_user(user, auth, opts)
        # do not raise an exception for tracking
        AuthTrail.safely do
          request = ActionDispatch::Request.new(auth.env)

          strategy = auth.env["omniauth.auth"]["provider"] if auth.env["omniauth.auth"]
          strategy ||= auth.winning_strategy.class.name.split("::").last.underscore if auth.winning_strategy
          strategy ||= "database_authenticatable"

          identity = user.try(:email)
          AuthTrail.track(
            strategy: strategy,
            scope: opts[:scope].to_s,
            identity: identity,
            success: true,
            request: request,
            user: user
          )
        end
      end

      def before_failure(env, opts)
        AuthTrail.safely do
          if opts[:message]
            request = ActionDispatch::Request.new(env)
            scope = opts[:scope]
            identity = request.params[scope] && request.params[scope][:email] rescue nil

            warden_config = env['warden'].config
            default_strategies = warden_config[:default_strategies][scope]
            default_strategies.delete(:rememberable)
            default_strategy = default_strategies.first.to_s

            AuthTrail.track(
              strategy: default_strategy,
              scope: opts[:scope].to_s,
              identity: identity,
              success: false,
              request: request,
              failure_reason: opts[:message].to_s
            )
          end
        end
      end
    end
  end
end
