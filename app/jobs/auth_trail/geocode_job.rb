module AuthTrail
  class GeocodeJob < ActiveJob::Base
    # default queue is used if queue_as returns nil
    # Rails has a test for this
    queue_as { AuthTrail.job_queue }

    def perform(login_activity)
      result =
        begin
          Geocoder.search(login_activity.ip).first
        rescue NameError
          raise "Add the geocoder gem to your Gemfile to use geocoding"
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        attributes = {
          city: result.try(:city),
          region: result.try(:state),
          country: result.try(:country),
          country_code: result.try(:country_code),
          latitude: result.try(:latitude),
          longitude: result.try(:longitude)
        }
        attributes.each do |k, v|
          login_activity.try("#{k}=", v.presence)
        end
        login_activity.save!
      end
    end
  end
end
