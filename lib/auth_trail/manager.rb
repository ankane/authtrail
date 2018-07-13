module AuthTrail
  module Manager
    class << self
      def after_set_user(user, auth, opts)
        # do not raise an exception for tracking
        AuthTrail.safely do
          request = ActionDispatch::Request.new(auth.env)

          identity = user.try(:email)
          AuthTrail.track(
            strategy: detect_strategy(auth),
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

            AuthTrail.track(
              strategy: detect_strategy(env["warden"]),
              scope: scope.to_s,
              identity: identity,
              success: false,
              request: request,
              failure_reason: opts[:message].to_s
            )
          end
        end
      end

      private

      def detect_strategy(auth)
        strategy = auth.env["omniauth.auth"]["provider"] if auth.env["omniauth.auth"]
        strategy ||= auth.winning_strategy.class.name.split("::").last.underscore if auth.winning_strategy
        strategy ||= "database_authenticatable"
        strategy
      end
    end
  end
end
