module AuthTrail
  class GeocodeJob < Rails::VERSION::MAJOR >= 5 ? ApplicationJob : ActiveJob::Base
    def perform(login_activity)
      result =
        begin
          Geocoder.search(login_activity.ip).first
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        %w(city country latitude longitude region).each do |attribute|
          next unless login_activity.respond_to?("#{attribute}=")
          login_activity.send("#{attribute}=", result.try(attribute).presence)
        end
        login_activity.save!
      end
    end
  end
end
