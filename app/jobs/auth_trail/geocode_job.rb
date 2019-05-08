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
        geocode_to_login_activity_mapping.each do |geocode_attr, login_activity_attr|
          next unless login_activity.respond_to?("#{login_activity_attr}=")
          login_activity.send("#{login_activity_attr}=", result.try(geocode_attr).presence)
        end
        login_activity.save!
      end
    end

    private

    def geocode_to_login_activity_mapping
      {
        city: :city,
        country: :country,
        latitude: :latitude,
        longitude: :longitude,
        state: :region,
      }
    end
  end
end
