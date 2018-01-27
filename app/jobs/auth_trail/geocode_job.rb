module AuthTrail
  class GeocodeJob < ActiveJob::Base
    def perform(login_activity)
      result =
        begin
          Geocoder.search(login_activity.ip).first.try(:data)
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        login_activity.update!(
          city: result["city"].presence,
          region: result["region_name"].presence,
          country: result["country_name"].presence
        )
      end
    end
  end
end
