require "request_store"

module AuthTrail
  module Controller
    def self.included(base)
      base.before_action :set_authtrail_request_store
    end

    def set_authtrail_request_store
      RequestStore.store[:authtrail_request] = request
    end
  end
end
