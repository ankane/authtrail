module AuthTrail
  module Manager
    class << self
      def after_set_user(user, auth, opts)
        request = ActionDispatch::Request.new(auth.env)

        AuthTrail.track(
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
          strategy: detect_strategy(env["warden"]),
          scope: opts[:scope].to_s,
          identity: AuthTrail.identity_method.call(request, opts, nil),
          success: false,
          request: request,
          failure_reason: opts[:message].to_s
        )
      end

      private

      def detect_strategy(auth)
        strategy = auth.env["omniauth.auth"]["provider"] if auth.env["omniauth.auth"]
        if !strategy && auth.winning_strategy
          winning_class = auth.winning_strategy.class
          strategy =
            if winning_class.name
              winning_class.name.split("::").last.underscore
            else
              # rescue since _strategies is private
              Warden::Strategies._strategies.key(winning_class).to_s rescue "unknown"
            end
        end
        strategy ||= "database_authenticatable"
        strategy
      end
    end
  end
end
