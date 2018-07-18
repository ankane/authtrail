module Devise
  module Models
    module Trailable
      extend ActiveSupport::Concern

      included do
        after_update :record_email_change, if: -> { saved_change_to_email? }
        after_update :record_password_change, if: -> { saved_change_to_encrypted_password? }
        after_update :record_password_reset_request, if: -> { saved_change_to_reset_password_sent_at? }
      end

      def record_password_reset_request
        puts "Password reset requested"
      end

      def record_email_change
        puts "Sending email change to #{email_before_last_save}"
        puts "Sending email change to #{email}"
      end

      def record_password_change
        puts "Sending password change to #{email}"
      end
    end
  end
end
