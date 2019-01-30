module AuthTrail
  class GeocodeJob < (ApplicationJob rescue ActiveJob::Base)
    def perform(login_activity)
      result =
        begin
          Geocoder.search(login_activity.ip).first
        rescue => e
          Rails.logger.info "Geocode failed: #{e.message}"
          nil
        end

      if result
        login_activity.update!(
          city: result.try(:city).presence,
          region: result.try(:state).presence,
          country: result.try(:country).presence
        )
      end
    end
  end
end
