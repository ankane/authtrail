module AuthTrail
  class GeocodeJob < ActiveJob::Base
    def perform(activity)
      result =
        begin
          Geocoder.search(activity.ip).first
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        attributes = {
          city: result.try(:city),
          region: result.try(:state),
          country: result.try(:country),
          latitude: result.try(:latitude),
          longitude: result.try(:longitude)
        }
        attributes.each do |k, v|
          activity.try("#{k}=", v.presence)
        end
        activity.save!
      end
    end
  end
end
