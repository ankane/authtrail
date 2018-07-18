module AuthTrail
  module Model
    extend ActiveSupport::Concern

    included do
      after_update :record_email_change, if: -> { (try(:saved_changes) || changes).key?(:email) }
      after_update :record_password_change, if: -> { (try(:saved_changes) || changes).key?(:encrypted_password) }
      after_update :record_password_reset_request, if: -> { (try(:saved_changes) || changes).key?(:reset_password_sent_at) && !reset_password_sent_at.nil? }
    end

    def record_password_reset_request
      AuthTrail.track(
        activity_type: "password_reset_request",
        user: self
      )
    end

    def record_email_change
      AuthTrail.track(
        activity_type: "email_change",
        user: self
      )
    end

    def record_password_change
      AuthTrail.track(
        activity_type: "password_change",
        user: self
      )
    end
  end
end
