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
        login_activity.assign_attributes(
          city: result.try(:city).presence,
          region: result.try(:state).presence,
          country: result.try(:country).presence
        )
        %w(latitude longitude).each do |attribute|
          login_activity.try("#{attribute}=", result.try(attribute).presence)
        end
        login_activity.save!
      end
    end
  end
end
