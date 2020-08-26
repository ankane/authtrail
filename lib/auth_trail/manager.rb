module AuthTrail
  module Manager
    class << self
      def after_set_user(user, auth, opts)
        request = ActionDispatch::Request.new(auth.env)

        AuthTrail.track(
          activity_type: "sign_in_success",
          strategy: detect_strategy(auth),
          scope: opts[:scope].to_s,
          identity: AuthTrail.identity_method.call(request, opts, user),
          success: true,
          request: request,
          user: user
        )
      end

      def before_failure(env, opts)
        request = ActionDispatch::Request.new(env)

        AuthTrail.track(
          activity_type: "sign_in_failure",
          strategy: detect_strategy(env["warden"]),
          scope: opts[:scope].to_s,
          identity: AuthTrail.identity_method.call(request, opts, nil),
          success: false,
          request: request,
          failure_reason: opts[:message].to_s
        )
      end

      def before_logout(user, auth, opts)
        request = ActionDispatch::Request.new(auth.env)

        AuthTrail.track(
          activity_type: "sign_out",
          strategy: detect_strategy(auth),
          scope: opts[:scope].to_s,
          success: true,
          request: request,
          user: user
        )
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
