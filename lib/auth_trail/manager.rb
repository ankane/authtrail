module AuthTrail
  module Manager
    class << self
      def after_set_user(user, auth, opts)
        # do not raise an exception for tracking
        AuthTrail.safely do
          request = ActionDispatch::Request.new(auth.env)

          AuthTrail.track(
            strategy: detect_strategy(auth),
            scope: opts[:scope].to_s,
            identity: AuthTrail.identity_method.call(request, opts, user),
            success: true,
            request: request,
            ip: AuthTrail.ip_method.call(request),
            user: user
          )
        end
      end

      def before_failure(env, opts)
        AuthTrail.safely do
          if opts[:message]
            request = ActionDispatch::Request.new(env)

            AuthTrail.track(
              strategy: detect_strategy(env["warden"]),
              scope: opts[:scope].to_s,
              identity: AuthTrail.identity_method.call(request, opts, nil),
              success: false,
              request: request,
              ip: AuthTrail.ip_method.call(request),
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
