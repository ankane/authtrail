module AuthTrail
  module Controller
    def self.included(base)
      base.around_action :set_authtrail_request
    end

    def set_authtrail_request
      previous_value = Thread.current[:authtrail_request]
      begin
        Thread.current[:authtrail_request] = request
        yield
      ensure
        Thread.current[:authtrail_request] = previous_value
      end
    end
  end
end
